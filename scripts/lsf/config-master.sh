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
export PRIVATE_VLAN_NUMBER=${11}

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
echo "$ENTITLEMENT" > /opt/ibm/lsfsuite/lsf/conf/lsf.entitlement

LOG "Modify credentials file"
sed -i 's/^softlayer_access_user_name =.\+/softlayer_access_user_name = '$SL_USER'/; s/softlayer_secret_api_key =.\+/softlayer_secret_api_key = '$SL_APIKEY'/' $LSF_ENVDIR/resource_connector/softlayer/conf/credentials

LOG "Modify template file"
sed -i 's/"imageId": ".\+",/"imageId": "'$IMAGE_NAME'",/' $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_templates.json
sed -i 's/"datacenter": ".\+",/"datacenter": "'$DATA_CENTER'",/' $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_templates.json
if [ "$PRIVATE_VLAN_NUMBER" == "0" ]
then
    sed -i '/"vlanNumber"/d' $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_templates.json
else
    sed -i 's/"vlanNumber": ".\+",/"vlanNumber": "'$PRIVATE_VLAN_NUMBER'",/' $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_templates.json
fi
sed -i 's/"postProvisionURL": ".\+",/"postProvisionURL": "http:\/\/'$MASTER_PRIVATE_IP'\/provisioning.sh",/' $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_templates.json

LOG "Modify provisioning.sh"
sed -i "s/master_host_ip=.\+/master_host_ip='$MASTER_PRIVATE_IP'/" /var/www/html/provisioning.sh

LOG "Start daemons"
sed -i 's/^Listen .\+:80/Listen '$MASTER_PRIVATE_IP':80/' /etc/httpd/conf/httpd.conf
httpd -k start
lsf_daemons start

max_retry=6
while [ $max_retry -gt 0 -a -z "$running" ]
do
    sleep 10
    lsf_daemons start
    running=`lsf_daemons status|grep 'lim'|grep 'running'`
    max_retry=`expr $max_retry - 1`
done

if [ $max_retry -eq 0 ]
then
    LOG "Failed to start daemons."
fi
