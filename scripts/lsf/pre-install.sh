#!/bin/bash

export ROLE=$1
export REMOTE_CONSOLE_SSH_KEY=`echo $6 | base64 -d`
export MASTER_HOSTNAME=$7
export MASTER_PRIVATE_IP=$8
export COMPUTE_HOSTNAME=$9
export COMPUTE_PRIVATE_IP=${10}

export MASTER_HOSTNAME_SHORT=`echo $MASTER_HOSTNAME | cut -d '.' -f 1`
export COMPUTE_HOSTNAME_SHORT=`echo $COMPUTE_HOSTNAME | cut -d '.' -f 1`

LOG_FILE=/root/logs/pre-install-$ROLE.log
function LOG()
{
    echo -e `date` "$1" >> "$LOG_FILE"
}

LOG "Start pre-install.sh for $ROLE ..."

export >> "$LOG_FILE"

LOG "Add master and compute host SSH keys"
chmod 600 /root/.ssh/id_rsa
chmod 644 /root/.ssh/id_rsa.pub
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
if [ "$ROLE" == "master" ]
then
    cat /root/.ssh/compute-host.pub >> /root/.ssh/authorized_keys
    rm -f /root/.ssh/compute-host.pub

    LOG "Add remote console SSH key"
    echo $REMOTE_CONSOLE_SSH_KEY >> /root/.ssh/authorized_keys

    LOG "Set /etc/hosts"
    echo $COMPUTE_PRIVATE_IP $COMPUTE_HOSTNAME $COMPUTE_HOSTNAME_SHORT >> /etc/hosts

    LOG "install yum-utils"
    yum -y install yum-utils >> $LOG_FILE
else
    cat /root/.ssh/master-host.pub >> /root/.ssh/authorized_keys
    rm -f /root/.ssh/master-host.pub

    LOG "Set /etc/hosts"
    echo $MASTER_PRIVATE_IP $MASTER_HOSTNAME $MASTER_HOSTNAME_SHORT >> /etc/hosts
fi

LOG "Complete pre-install.sh for $ROLE."
