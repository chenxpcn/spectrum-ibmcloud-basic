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
export COMPUTE_CORES=${17}
export COMPUTE_MEM=${18}
export IMAGE_NAME=`echo ${19} | base64 -d`
export COMPUTE_VLAN_NUMBER=${20}

LOG_FILE=/root/logs/post-install-$ROLE.log
function LOG()
{
    echo -e `date` "$1" >> "$LOG_FILE"
}

LOG "Start post-install.sh for $ROLE ..."

export >> "$LOG_FILE"

if [ "$ROLE" == "master" ]
then
    if [ -n "COMPUTE_INSTANCE_ID" ]
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

    LOG "RC configuration directory is $LSF_ENVDIR/resource_connector/softlayer/conf"

    LOG "Set provioning.sh"
    cp /root/installer/provisioning.sh /var/www/html/
    sed -i 's/\[MASTER-HOSTNAME\]/'$MASTER_HOSTNAME'/' /var/www/html/provisioning.sh
    sed -i 's/\[MASTER-IP-ADDRESS\]/'$MASTER_PRIVATE_IP'/' /var/www/html/provisioning.sh
    sed -i 's/\[CLUSTER-NAME\]/'$CLUSTERNAME'/' /var/www/html/provisioning.sh

    LOG "Modify $LSF_ENVDIR/lsf.cluster.$CLUSTERNAME"
    sed -i '/Begin Parameters/a\LSF_HOST_ADDR_RANGE=*.*.*.*' $LSF_ENVDIR/lsf.cluster.$CLUSTERNAME

    LOG "Modify $LSF_ENVDIR/resource_connector/softlayer/conf/credentials"
    sed -i 's/^softlayer_access_user_name =.\+/softlayer_access_user_name = '$SL_USER'/; s/softlayer_secret_api_key =.\+/softlayer_secret_api_key = '$SL_APIKEY'/' $LSF_ENVDIR/resource_connector/softlayer/conf/credentials

    LOG "Modify $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_config.json"
    NEW_VALUE=`echo "$LSF_ENVDIR/resource_connector/softlayer/conf/credentials"|sed 's#\/#\\\/#g'`
    sed -i 's/\( \+"SOFTLAYER_CREDENTIAL_FILE": "\).\+\,/\1'$NEW_VALUE'"\,/' $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_config.json

    LOG "Modify $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_templates.json"
    sed -i 's/"maxNumber": [0-9]\+\,/"maxNumber": 10\,/' $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_templates.json
    sed -i 's/"ncpus": \["Numeric"\, ".\+"/"ncpus": \["Numeric"\, "'$COMPUTE_CORES'"/' $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_templates.json
    sed -i 's/"mem": \["Numeric"\, ".\+"/"mem": \["Numeric"\, "'$COMPUTE_MEM'"/' $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_templates.json
    sed -i 's/"softlayercomp"/"softlayerhost"/' $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_templates.json
    sed -i 's/"imageId": ".\+",/"imageId": "'$IMAGE_NAME'",/' $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_templates.json
    sed -i 's/"datacenter": ".\+"\,/"datacenter": "'$DATA_CENTER'"\,/' $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_templates.json
    sed -i 's/"vlanNumber": ".\+"\,/"vlanNumber": "'$COMPUTE_VLAN_NUMBER'"\,/' $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_templates.json
    sed -i 's/"privateNetworkOnlyFlag": false\,/"privateNetworkOnlyFlag": true\,/' $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_templates.json
    sed -i 's/"postProvisionURL": ".\+"\,/"postProvisionURL": "http:\/\/'$MASTER_PRIVATE_IP'\/provisioning.sh"\,/' $LSF_ENVDIR/resource_connector/softlayer/conf/softlayerprov_templates.json

    LOG "Modify $LSF_ENVDIR/lsbatch/$CLUSTERNAME/configdir/lsb.modules"
    sed -i 's/#schmod_demand/schmod_demand/' $LSF_ENVDIR/lsbatch/$CLUSTERNAME/configdir/lsb.modules

    LOG "Modify $LSF_ENVDIR/lsbatch/$CLUSTERNAME/configdir/lsb.queues"
    sed -i '/QUEUE_NAME \+= normal/a\RC_HOSTS = softlayerhost' $LSF_ENVDIR/lsbatch/$CLUSTERNAME/configdir/lsb.queues
    sed -i '/RC_HOSTS = softlayerhost/a\RC_ACCOUNT = lsf-demo-dynamic-host' $LSF_ENVDIR/lsbatch/$CLUSTERNAME/configdir/lsb.queues

    LOG "Modify $LSF_ENVDIR/lsf.conf"
    echo LSB_RC_EXTERNAL_HOST_FLAG=\"softlayerhost\">>$LSF_ENVDIR/lsf.conf
    echo LSF_REG_FLOAT_HOSTS=Y>>$LSF_ENVDIR/lsf.conf
    echo LSF_DYNAMIC_HOST_WAIT_TIME=60>>$LSF_ENVDIR/lsf.conf
    echo LSF_DYNAMIC_HOST_TIMEOUT=10m>>$LSF_ENVDIR/lsf.conf
    echo LSB_RC_EXTERNAL_HOST_IDLE_TIME=10>>$LSF_ENVDIR/lsf.conf

    LOG "Modify $LSF_ENVDIR/lsf.shared"
    sed -i 's/#\( \+\)softlayerhost/ \1softlayerhost/' $LSF_ENVDIR/lsf.shared

    LOG "Disable master node as compute node"
    badmin hclose $MASTER_HOSTNAME>>$LOG_FILE

    LOG "Restart the LSF daemons"
    echo y>/root/installer/all_yes
    echo y>>/root/installer/all_yes
    lsadmin limrestart</root/installer/all_yes>>$LOG_FILE
    lsadmin resrestart</root/installer/all_yes>>$LOG_FILE
    badmin mbdrestart</root/installer/all_yes>>$LOG_FILE

fi

LOG "Complete post-install.sh for $ROLE."
