#!/bin/bash

export MASTER_PRIVATE_IP=$1
export COMPUTE_HOSTNAME=$2
export COMPUTE_PRIVATE_IP=$3
export ENTITLEMENT=`echo $4 | base64 -d`
export IMAGE_NAME=`echo $5 | base64 -d`
export SL_USER=`echo $6 | base64 -d`
export SL_APIKEY=`echo $7 | base64 -d`
export COMPUTE_INSTANCE_ID=$8
export REMOTE_CONSOLE_SSH_KEY=`echo $9 | base64 -d`
export DATA_CENTER=${10}
export PRIVATE_VLAN_ID=${12}
export CLUSTERNAME=${13}

export COMPUTE_HOSTNAME_SHORT=`echo $COMPUTE_HOSTNAME | cut -d '.' -f 1`

LOG_FILE=/root/config.log
function LOG()
{
    echo -e `date` "$1" >> "$LOG_FILE"
}

function is_vm_offline() {
    LOG "Check whether vm is offline ..."
    max_retry=30
    online='1'
    while [ $max_retry -gt 0 -a $online -eq '1' ]
    do
        sleep 10
        online=`ping $COMPUTE_PRIVATE_IP -c 1 -q|grep received|cut -d ',' -f 2|cut -d ' ' -f 2`
        max_retry=`expr $max_retry - 1`
    done
}

function is_vm_online() {
    LOG "Check whether vm is online ..."
    max_retry=60
    online='0'
    while [ $max_retry -gt 0 -a $online -eq '0' ]
    do
        sleep 10
        online=`ping $COMPUTE_PRIVATE_IP -c 1 -q|grep received|cut -d ',' -f 2|cut -d ' ' -f 2`
        max_retry=`expr $max_retry - 1`
    done
}

function EGOSH_LOGON()
{
    LOG "Try to logon egosh ..."
    RETRY=0
    while [ $RETRY -lt 30 ]
    do
        sleep 10
        USER_LOGON=`egosh user logon -u Admin -x Admin 2>&1`
        if [ "$USER_LOGON" == "Logged on successfully" ]
        then
            LOG "Logon egosh successfully."
            return 0
        else
            RETRY=`expr $RETRY + 1`
            LOG "Retry logon egosh ... $RETRY"
        fi
    done

    LOG "Failed to logon egosh!"
    return 1
}

export >> $LOG_FILE

LOG "Add remote console SSH key"
echo $REMOTE_CONSOLE_SSH_KEY >> /root/.ssh/authorized_keys

LOG "Start to capture the image for dynamic compute host."

cd /root/installer
. ./venv/bin/activate

LOG "Capturing..."
python /root/installer/capture-image.py $SL_USER $SL_APIKEY $COMPUTE_INSTANCE_ID "$IMAGE_NAME" >> $LOG_FILE

deactivate

LOG "Check whether capture transaction is completed or not."
is_vm_offline
if [ $online -eq '0' ]
then
    LOG "vm is offline."
    is_vm_online
    if [ $online -eq '1' ]
    then
        LOG "vm is online again, capture transaction complete."
    else
        LOG "vm is still offline in 10 minutes, please check whether capture image succeed or not manually."
    fi
else
    LOG "vm is still online in 5 minutes, please check whether capture image succeed or not manually."
fi

LOG "Capture the image for dynamic compute host complete."

LOG "Set hosts"
echo $COMPUTE_PRIVATE_IP $COMPUTE_HOSTNAME $COMPUTE_HOSTNAME_SHORT >> /etc/hosts

LOG "Set entitlement"
echo -e "$ENTITLEMENT" > /tmp/sym_adv_entitlement.dat

source /opt/ibm/spectrumcomputing/profile.platform
if [ "$ROLE" == "master" ]
then
    chown egoadmin:wheel /tmp/sym_adv_entitlement.dat
fi
egosetrc.sh >> "$LOG_FILE"
egosetsudoers.sh >> "$LOG_FILE"
LOG "Join the cluster"
su egoadmin -c "egoconfig join $HOSTNAME -f" >> "$LOG_FILE"
su egoadmin -c "egoconfig setentitlement /tmp/sym_adv_entitlement.dat" >> "$LOG_FILE"

LOG "Modify cluster configuration file"
sed -i 's/\('$HOSTNAME'.\+\)(linux)/\1(linux mg)/' /opt/ibm/spectrumcomputing/kernel/conf/ego.cluster.$CLUSTERNAME

LOG "Wait EGO service start ..."
egosh ego start  >> "$LOG_FILE"
EGOSH_LOGON
EGO_SERVICE_STARTED=$?
if [ $EGO_SERVICE_STARTED -eq 1 ]
then
    LOG "Failed to start EGO service, exit!"
    return 1
fi
LOG "EGO service has been started."

LOG "Setup post_install.sh for HostFactory"
sed -i 's/YOUR_IP_ADDRESS/'$MASTER_PRIVATE_IP'/' /var/www/html/post_install.sh

LOG "Modify credentials file"
sed -i 's/^softlayer_access_user_name =.\+/softlayer_access_user_name = '$SL_USER'/; s/softlayer_secret_api_key =.\+/softlayer_secret_api_key = '$SL_APIKEY'/' /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/providers/softlayer/conf/credentials

LOG "Modify /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/providers/softlayer/conf/softlayerprov_templates.json"
sed -i 's/"imageId": ".\+",/"imageId": "'$IMAGE_NAME'",/' /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/providers/softlayer/conf/softlayerprov_templates.json
sed -i 's/"datacenter": ".\+",/"datacenter": "'$DATA_CENTER'",/' /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/providers/softlayer/conf/softlayerprov_templates.json
if [ "$PRIVATE_VLAN_ID" == "0" ]
then
    sed -i '/"vlanId"/d' /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/providers/softlayer/conf/softlayerprov_templates.json
else
    sed -i 's/"vlanId": ".\+",/"vlanId": "'$PRIVATE_VLAN_ID'",/' /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/providers/softlayer/conf/softlayerprov_templates.json
fi
sed -i 's/"postProvisionURL": ".\+"/"postProvisionURL": "http:\/\/'$MASTER_PRIVATE_IP'\/post_install.sh"/' /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/providers/softlayer/conf/softlayerprov_templates.json

LOG "Start httpd"
sed -i 's/^Listen .\+:80/Listen '$MASTER_PRIVATE_IP':80/' /etc/httpd/conf/httpd.conf
httpd -k start

LOG "Start HostFactory service"
egosh service start HostFactory >> "$LOG_FILE"

