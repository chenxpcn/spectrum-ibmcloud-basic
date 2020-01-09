#!/bin/bash

export MASTER_HOSTNAME=$1
export MASTER_PRIVATE_IP=$2
export COMPUTE_HOSTNAME=$3

export MASTER_HOSTNAME_SHORT=`echo $MASTER_HOSTNAME | cut -d '.' -f 1`
export COMPUTE_HOSTNAME_SHORT=`echo $COMPUTE_HOSTNAME | cut -d '.' -f 1`

LOG_FILE=/root/config.log
function LOG()
{
    echo -e `date` "$1" >> "$LOG_FILE"
}
export >> $LOG_FILE

LOG "Set hosts"
echo $MASTER_PRIVATE_IP $MASTER_HOSTNAME $MASTER_HOSTNAME_SHORT >> /etc/hosts
cat /etc/hosts >> $LOG_FILE

LOG "Start daemons"
lsf_daemons start

max_retry=6
while [ $max_retry -gt 0 -a -z "$running" ]
do
    sleep 10
    lsf_daemons start
    running=`lsf_daemons status|grep 'lim'|grep 'running'`
    LOG "running is $running"
    max_retry=`expr $max_retry - 1`
done

if [ $max_retry -gt 0 ]
then
    LOG "Wait to join the cluster"
    max_retry=10
    while [ $max_retry -gt 0 -a "$state" != "ok" ]
    do
        sleep 30
        state=`bhosts -w |grep "$COMPUTE_HOSTNAME_SHORT"|cut -d ' ' -f 2`
        LOG "state is $state"
        max_retry=`expr $max_retry - 1`
    done
    if [ $max_retry -eq 0 ]
    then
        LOG "Failed to check the compute host."
    fi
else
    LOG "Failed to start daemons."
fi