#!/bin/bash
ROLE=$1
LOG_FILE=/root/logs/download-$ROLE.log

function LOG()
{
    echo -e `date` "$1" >> "$LOG_FILE"
}

LOG "Start download script for $ROLE ..."

SCRIPTS_URI=$2/symphony
INSTALLER_URI=$3
ENTITLEMENT_URI=$4

LOG "wget -nv -nH -c --no-check-certificate -O symeval-7.3.0.0_x86_64.bin $INSTALLER_URI"
wget -nv -nH -c --no-check-certificate -O /root/installer/sym_x86_64.bin $INSTALLER_URI

LOG "wget -nv -nH -c --no-check-certificate -O /root/installer/pre-install.sh $SCRIPTS_URI/pre-install.sh"
wget -nv -nH -c --no-check-certificate -O /root/installer/pre-install.sh $SCRIPTS_URI/pre-install.sh

LOG "wget -nv -nH -c --no-check-certificate -O /root/installer/install.sh $SCRIPTS_URI/install.sh"
wget -nv -nH -c --no-check-certificate -O /root/installer/install.sh $SCRIPTS_URI/install.sh

LOG "wget -nv -nH -c --no-check-certificate -O /root/installer/post-install.sh $SCRIPTS_URI/post-install.sh"
wget -nv -nH -c --no-check-certificate -O /root/installer/post-install.sh $SCRIPTS_URI/post-install.sh

LOG "wget -nv -nH -c --no-check-certificate -O /root/installer/clean.sh $SCRIPTS_URI/clean.sh"
wget -nv -nH -c --no-check-certificate -O /root/installer/clean.sh $SCRIPTS_URI/clean.sh

if [ "$ROLE" == "master" ]
then
    LOG "wget -nv -nH -c --no-check-certificate -O /tmp/sym_adv_ev_entitlement.dat $ENTITLEMENT_URI"
    wget -nv -nH -c --no-check-certificate -O /tmp/sym_adv_entitlement.dat $ENTITLEMENT_URI

    LOG "wget -nv -nH -c --no-check-certificate -O /root/installer/softlayerprov_templates.json.template $SCRIPTS_URI/softlayerprov_templates.json.template"
    wget -nv -nH -c --no-check-certificate -O /root/installer/softlayerprov_templates.json.template $SCRIPTS_URI/softlayerprov_templates.json.template

    LOG "wget -nv -nH -c --no-check-certificate -O /root/installer/hostProviders.json.template $SCRIPTS_URI/hostProviders.json.template"
    wget -nv -nH -c --no-check-certificate -O /root/installer/hostProviders.json.template $SCRIPTS_URI/hostProviders.json.template

    LOG "wget -nv -nH -c --no-check-certificate -O /root/installer/hostRequestors.json.template $SCRIPTS_URI/hostRequestors.json.template"
    wget -nv -nH -c --no-check-certificate -O /root/installer/hostRequestors.json.template $SCRIPTS_URI/hostRequestors.json.template

    LOG "wget -nv -nH -c --no-check-certificate -O /root/installer/capture-image.sh $SCRIPTS_URI/capture-image.sh"
    wget -nv -nH -c --no-check-certificate -O /root/installer/capture-image.sh $SCRIPTS_URI/capture-image.sh

    LOG "wget -nv -nH -c --no-check-certificate -O /root/installer/capture-image.py $SCRIPTS_URI/capture-image.py"
    wget -nv -nH -c --no-check-certificate -O /root/installer/capture-image.py $SCRIPTS_URI/capture-image.py
fi

chmod u+x /root/installer/*.sh

LOG "Complete download script for $ROLE."
