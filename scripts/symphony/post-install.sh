#!/bin/bash

export ROLE=$1
export MASTER_HOSTNAME=$7
export MASTER_PRIVATE_IP=$8
export COMPUTE_PRIVATE_IP=${10}
export COMPUTE_INSTANCE_ID=${11}
export CLUSTERNAME=${12}
export SL_USER=`echo ${13} | base64 -d`
export SL_APIKEY=`echo ${14} | base64 -d`
export DATA_CENTER=${15}
export PRIVATE_VLAN_ID=${16}
export COMPUTE_CORES=${17}
export COMPUTE_MEM=${18}
export IMAGE_NAME=`echo ${19} | base64 -d`

export MASTER_HOSTNAME_SHORT=`echo $MASTER_HOSTNAME | cut -d '.' -f 1`

LOG_FILE=/root/logs/post-install-$ROLE.log
function LOG()
{
    echo -e `date` "$1" >> "$LOG_FILE"
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

function IS_COMPUTE_JOIN()
{
    LOG "Try to list resource ..."
    RETRY=0
    while [ $RETRY -lt 30 ]
    do
        sleep 10
        RESOURCE_LIST=`egosh resource list -l | grep $1`
        if [ -n "$RESOURCE_LIST" ]
        then
            LOG "$1 is in resource list."
            return 0
        else
            RETRY=`expr $RETRY + 1`
            LOG "Retry list resource ... $RETRY"
        fi
    done

    LOG "$1 failed to join the cluster!"
    return 1
}

LOG "Start post-install.sh for $ROLE ..."

export >> "$LOG_FILE"

if [ "$ROLE" == "master" -a -n "COMPUTE_INSTANCE_ID" ]
then
    LOG "Archive and remove installer and logs from compute host before create image template"
    ssh -o "StrictHostKeyChecking no" root@$COMPUTE_PRIVATE_IP "tar cfz compute-archive.tgz installer logs; rm -fr installer logs"
    scp root@$COMPUTE_PRIVATE_IP:/root/compute-archive.tgz /root/installer/

    LOG "Start to create image template $IMAGE_NAME ..."
    /root/installer/capture-image.sh $SL_USER $SL_APIKEY $COMPUTE_INSTANCE_ID $IMAGE_NAME $COMPUTE_PRIVATE_IP

    sleep 15
    
    LOG "Restore installer and logs on compute host"
    scp /root/installer/compute-archive.tgz root@$COMPUTE_PRIVATE_IP:/root/
    ssh root@$COMPUTE_PRIVATE_IP "tar xfz compute-archive.tgz; rm -f compute-archive.tgz"
fi

LOG "Post configure for cluster ..."
source /opt/ibm/spectrumcomputing/profile.platform
if [ "$ROLE" == "master" ]
then
    chown egoadmin:wheel /tmp/sym_adv_entitlement.dat
fi
egosetrc.sh >> "$LOG_FILE"
egosetsudoers.sh >> "$LOG_FILE"
LOG "Join the cluster"
su egoadmin -c "egoconfig join $MASTER_HOSTNAME -f" >> "$LOG_FILE"
if [ "$ROLE" == "master" ]
then
    LOG "Set entitlement"
    su egoadmin -c "egoconfig setentitlement /tmp/sym_adv_entitlement.dat" >> "$LOG_FILE"

    LOG "Modify /opt/ibm/spectrumcomputing/kernel/conf/ego.cluster.$CLUSTERNAME"
    sed -i 's/\('$MASTER_HOSTNAME'.\+\)(linux)/\1(linux mg)/' /opt/ibm/spectrumcomputing/kernel/conf/ego.cluster.$CLUSTERNAME
fi
egosh ego start  >> "$LOG_FILE"

LOG "Wait EGO service start ..."
EGOSH_LOGON
EGO_SERVICE_STARTED=$?
if [ $EGO_SERVICE_STARTED -eq 1 ]
then
    LOG "Failed to start EGO service, exit!"
    return 1
fi
LOG "EGO service has been started."

if [ "$ROLE" == "compute" ]
then
    IS_COMPUTE_JOIN `echo $HOSTNAME | cut -d '.' -f 1`
    COMPUTE_JOINED=$?
    if [ $COMPUTE_JOINED -eq 1 ]
    then
        return 1
    fi
    LOG "Complete post-install.sh for $ROLE."
    return 0
fi

LOG "Start to configure HostFactory"
LOG "Start httpd ..."
sed -i 's/Listen 80/Listen '$MASTER_PRIVATE_IP':80/' /etc/httpd/conf/httpd.conf
httpd -k start

LOG "Setup http://$MASTER_PRIVATE_IP/post_install.sh"
cp -f /opt/ibm/spectrumcomputing/$EGO_VERSION/hostfactory/providers/softlayer/postprovision/sym/post_install.sh /var/www/html
sed -i 's/'servername.ibm.com'/'$MASTER_HOSTNAME'/' /var/www/html/post_install.sh
sed -i 's/'servername'/'$MASTER_HOSTNAME_SHORT'/' /var/www/html/post_install.sh
sed -i 's/YOUR_IP_ADDRESS/'$MASTER_PRIVATE_IP'/' /var/www/html/post_install.sh
sed -i 's/CLUSTERADMIN=root/CLUSTERADMIN=egoadmin/' /var/www/html/post_install.sh

LOG "Modify /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/providers/softlayer/conf/credentials"
sed -i 's/^softlayer_access_user_name =.\+/softlayer_access_user_name = '$SL_USER'/; s/softlayer_secret_api_key =.\+/softlayer_secret_api_key = '$SL_APIKEY'/' /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/providers/softlayer/conf/credentials

LOG "Modify /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/providers/softlayer/conf/softlayerprov_config.json"
sed -i 's/"SOFTLAYER_CREDENTIAL_FILE":.\+/"SOFTLAYER_CREDENTIAL_FILE": "\/opt\/ibm\/spectrumcomputing\/eservice\/hostfactory\/conf\/providers\/softlayer\/conf\/credentials",/' /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/providers/softlayer/conf/softlayerprov_config.json

LOG "Modify /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/providers/softlayer/conf/softlayerprov_templates.json"
sed -i 's/COMPUTE_CORES/'$COMPUTE_CORES'/' /root/installer/softlayerprov_templates.json.template
sed -i 's/COMPUTE_MEM/'$COMPUTE_MEM'/' /root/installer/softlayerprov_templates.json.template
sed -i 's/IMAGE_NAME/'$IMAGE_NAME'/' /root/installer/softlayerprov_templates.json.template
sed -i 's/DATA_CENTER/'$DATA_CENTER'/' /root/installer/softlayerprov_templates.json.template
sed -i 's/PRIVATE_VLAN_ID/'$PRIVATE_VLAN_ID'/' /root/installer/softlayerprov_templates.json.template
sed -i 's/POST_PROVISION_SCRIPT/http:\/\/'$MASTER_PRIVATE_IP'\/post_install.sh/' /root/installer/softlayerprov_templates.json.template
echo y > /root/installer/force_orverwrite
cp /root/installer/softlayerprov_templates.json.template /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/providers/softlayer/conf/softlayerprov_templates.json < /root/installer/force_orverwrite

LOG "Modify /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/providers/hostProviders.json"
cp /root/installer/hostProviders.json.template /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/providers/hostProviders.json < /root/installer/force_orverwrite

LOG "Modify /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/requestors/hostRequestors.json"
cp /root/installer/hostRequestors.json.template /opt/ibm/spectrumcomputing/eservice/hostfactory/conf/requestors/hostRequestors.json < /root/installer/force_orverwrite

LOG "Start HostFactory service"
egosh service start HostFactory >> "$LOG_FILE"

LOG "Complete post-install.sh for $ROLE."
