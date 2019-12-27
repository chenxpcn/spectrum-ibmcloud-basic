#!/bin/bash

export ROLE=$1
export ADMIN_PASSWORD=`echo $5 | base64 -d`
export MASTER_HOSTNAME=$7
export CLUSTERNAME=${12}

export MASTER_HOSTNAME_SHORT=`echo $MASTER_HOSTNAME | cut -d '.' -f 1`

LOG_FILE=/root/logs/install-$ROLE.log
function LOG()
{
    echo -e `date` "$1" >> "$LOG_FILE"
}

LOG "Start install.sh for $ROLE ..."

export >> "$LOG_FILE"

if [ "$ROLE" == "master" ]
then
    cd /opt/ibm/lsf_installer/playbook

    LOG "Modify lsf-config.yml"
    sed -i 's/my_cluster_name: myCluster/my_cluster_name: '${CLUSTERNAME}'/' lsf-config.yml

    LOG "Modify lsf-inventory"
    sed -i 's/<master>/'$MASTER_HOSTNAME_SHORT'/g' lsf-inventory

    LOG "Modify group_vars/all"
    sed -i 's/lsf-master-only.lsf.spectrum/'$MASTER_HOSTNAME_SHORT'/' group_vars/all

    LOG "Start httpd"
    httpd -k start

    LOG "Perform pre-install checking"
    ansible-playbook -i lsf-inventory lsf-config-test.yml>/root/logs/lsf-config-test.log
    result=`cat /root/logs/lsf-config-test.log|grep 'failed='|sed -n 's/^.*failed=//;p'|grep '[1-9]'`
    if [ -z "$result" ]
    then
        LOG "Config test passed, please check /root/logs/lsf-config-test.log for detail."
    else
        LOG "Found error in config test, please check /root/logs/lsf-config-test.log for detail."
        exit -1
    fi
    ansible-playbook -i lsf-inventory lsf-predeploy-test.yml>/root/logs/lsf-predeploy-test.log
    result=`cat /root/logs/lsf-predeploy-test.log|grep 'failed='|sed -n 's/^.*failed=//;p'|grep '[1-9]'`
    if [ -z "$result" ]
    then
        LOG "Pre-deploy test passed, please check /root/logs/lsf-predeploy-test.log for detail."
    else
        LOG "Found error in pre-deploy test, please check /root/logs/lsf-predeploy-test.log for detail."
        exit -1
    fi

    LOG "Install LSF"
    ansible-playbook -i lsf-inventory lsf-deploy.yml>/root/logs/lsf-deploy.log
    result=`cat /root/logs/lsf-deploy.log|grep 'failed='|sed -n 's/^.*failed=//;p'|grep '[1-9]'`
    if [ -z "$result" ]
    then
        LOG "Install LSF successfully, please check /root/logs/lsf-deploy.log for detail."
    else
        LOG "Found error in deploy, please check /root/logs/lsf-deploy.log for detail."
        exit -1
    fi

    LOG "Set password for lsfadmin"
    echo "$ADMIN_PASSWORD" > /root/lsfadmin_password
    echo "$ADMIN_PASSWORD" >> /root/lsfadmin_password
    echo  >> /root/lsfadmin_password
    passwd lsfadmin < /root/lsfadmin_password >> "$LOG_FILE"
    rm -f /root/lsfadmin_password
else
    LOG "No action is required for this step."
fi

LOG "Complete install.sh for $ROLE."
