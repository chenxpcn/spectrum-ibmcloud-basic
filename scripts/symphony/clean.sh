#!/bin/bash

rm -fr /root/installer

rm -f /tmp/sym_adv_entitlement.dat

sed -i '/deployer@deployer/d' /root/.ssh/authorized_keys
