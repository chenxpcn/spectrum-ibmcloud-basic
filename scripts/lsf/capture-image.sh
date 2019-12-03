#!/bin/bash
SL_USER=$1
SL_APIKEY=$2
COMPUTE_INSTANCE_ID=$3
IMAGE_NAME=$4
COMPUTE_PRIVATE_IP=$5
LOG_FILE_CI=/root/logs/capture-image.log

LOG()
{
    echo -e `date` "$1" >> "$LOG_FILE_CI"
}

is_vm_offline() {
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

is_vm_online() {
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

LOG "Start to capture the image for vm."

LOG "Install and config python running environment."
yum install python3 -y >> "$LOG_FILE_CI"
cd /root/installer
LOG "Create virtual environment in $PWD"
python3 -m venv venv
LOG "activate"
. ./venv/bin/activate
LOG "pip install"
pip install --upgrade pip >> "$LOG_FILE_CI"
pip install SoftLayer >> "$LOG_FILE_CI"

LOG "Call to capture the image for vm"
python /root/installer/capture-image.py $SL_USER $SL_APIKEY $COMPUTE_INSTANCE_ID "$IMAGE_NAME" >> "$LOG_FILE_CI"
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

LOG "Capture the image for vm complete."
