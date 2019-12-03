#!/bin/bash
logfile=/var/log/postprovisionscripts.log
echo START `date '+%Y-%m-%d %H:%M:%S'` >> $logfile

#Do not remove this part of the script to support passing LSF user data to VM run time environment
STARTTIME=`date +%s`
TIMEOUT=60
URL="https://api.service.softlayer.com/rest/v3/SoftLayer_Resource_Metadata/getUserMetadata.txt"
USERDATA=`curl -s $URL` 2>>$logfile
#
while [[ "$USERDATA" == [Nn]"o user data"* ]] && [[ `expr $NOWTIME - $STARTTIME` -lt $TIMEOUT ]]; do
    sleep 5
    NOWTIME=`date +%s`
    USERDATA=`curl -s $URL` 2>>$logfile
done

# check if we got user data eventually
if [[ "$USERDATA" != [Nn]"o user data"* ]]; then
    # user data is expected to be a semicolon-separated key=value list
    # like environment variables; split them into an array
    IFS=\; read -ra ARR <<<"$USERDATA"
    for VAR in ${ARR[@]}; do
    eval "export $VAR"
    done
else
    echo "USERDATA: $USERDATA" >>$logfile
    echo EXIT AT `date '+%Y-%m-%d %H:%M:%S'` >>$logfile
    exit -1
fi
echo "CURRENT ENVIRONMENT:" >>$logfile
env >> $logfile

#Set the correct path for LSF_TOP, where LSF is installed on the VM host
LSF_TOP=/opt/ibm/lsfsuite/lsf
LSF_CONF_FILE=$LSF_TOP/conf/lsf.conf
source $LSF_TOP/conf/profile.lsf

#Add softlayer boolean resource for slave host
sed -i '$ a LSF_LOCAL_RESOURCES=\"[resource softlayerhost]\" '  $LSF_CONF_FILE

###Disable ego in the slave host
#sed -i "s/LSF_ENABLE_EGO=Y/LSF_ENABLE_EGO=N/" $LSF_CONF_FILE
###if ego enabled need to create a soft link
ln -s /opt/ibm/lsfsuite/lsf/conf/ego/[CLUSTER-NAME]/kernel/ego.conf /etc/ego.conf

#Do not remove this part of the script to support rc_account resource for SoftLayer
#You can similarly set additional local resources if needed
if [ -n "${rc_account}" ]; then
    sed -i "s/\(LSF_LOCAL_RESOURCES=.*\)\"/\1 [resourcemap ${rc_account}*rc_account]\"/" $LSF_CONF_FILE
    echo "update LSF_LOCAL_RESOURCES lsf.conf successfully, add [resourcemap ${rc_account}*rc_account]" >> $logfile
fi

#If there is no DNS server to resolve host names and IPs between master host and VMs, 
#then uncomment the following part and set the correct master LSF host name and IP address 
master_host='[MASTER-HOSTNAME]'
master_host_short=`echo ${master_host} | cut -d '.' -f 1`
master_host_ip='[MASTER-IP-ADDRESS]'
echo ${master_host_ip} ${master_host} ${master_host_short} >> /etc/hosts
echo $master_host > $LSF_ENVDIR/hostregsetup
lsreghost -s $LSF_ENVDIR/hostregsetup

#Create a script to start LSF daemons as cron job

cat > $LSF_TOP/start_lsf.sh << "EOF"
#!/bin/sh
# This script: is check and start LSF Daemons in cron job
logfile=/tmp/lsf_daemons_status
LIMSTOP="lim is stopped..."
LIMSTATUS=`/opt/ibm/lsfsuite/lsf/10.1/linux2.6-glibc2.3-x86_64/etc/lsf_daemons status|grep lim` 2>> $logfile
if [[ $LIMSTATUS = $LIMSTOP ]]; then
        nohup /opt/ibm/lsfsuite/lsf/10.1/linux2.6-glibc2.3-x86_64/etc/lsf_daemons start <&- >&- 2>&- & disown
else
        echo ${LIMSTATUS} >>$logfile
fi
EOF
chmod +x $LSF_TOP/start_lsf.sh

crontab -l > /tmp/mycron
echo "* * * * * /opt/ibm/lsfsuite/lsf/start_lsf.sh" >> /tmp/mycron
crontab /tmp/mycron
rm -f /tmp/mycron
crontab -l >>  $logfile

#Start LSF Daemons in dynamic VM host.
#lsf_daemons start
#lsf_daemons status >>$logfile
#lsadmin limstartup
echo END AT `date '+%Y-%m-%d %H:%M:%S'` >> $logfile

