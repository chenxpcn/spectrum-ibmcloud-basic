#!/bin/bash

export MASTER_HOSTNAME=$1
export MASTER_PRIVATE_IP=$2

export MASTER_HOSTNAME_SHORT=`echo $MASTER_HOSTNAME | cut -d '.' -f 1`
export COMPUTE_HOSTNAME_SHORT=`echo $HOSTNAME | cut -d '.' -f 1`

LOG_FILE=/root/config.log
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
        RESOURCE_LIST=`egosh resource list -l | grep $COMPUTE_HOSTNAME_SHORT`
        if [ -n "$RESOURCE_LIST" ]
        then
            LOG "$COMPUTE_HOSTNAME_SHORT is in resource list."
            return 0
        else
            RETRY=`expr $RETRY + 1`
            LOG "Retry list resource ... $RETRY"
        fi
    done

    LOG "$COMPUTE_HOSTNAME_SHORT failed to join the cluster!"
    return 1
}

export >> $LOG_FILE

LOG "Set hosts"
echo $MASTER_PRIVATE_IP $MASTER_HOSTNAME $MASTER_HOSTNAME_SHORT >> /etc/hosts
cat /etc/hosts >> $LOG_FILE

source /opt/ibm/spectrumcomputing/profile.platform
egosetrc.sh >> "$LOG_FILE"
egosetsudoers.sh >> "$LOG_FILE"
LOG "Join the cluster"
su egoadmin -c "egoconfig join $MASTER_HOSTNAME -f" >> "$LOG_FILE"

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

IS_COMPUTE_JOIN
COMPUTE_JOINED=$?
LOG "Configuration completed."
