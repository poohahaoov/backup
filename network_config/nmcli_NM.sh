#!/bin/bash

#clean up
nmcli networking off
nmcli con del eno1
nmcli con del eno2
nmcli con del bond0
nmcli con del ib0

systemctl restart NetworkManager

#bond0 master config
nmcli connection add type bond con-name bond0 ifname bond0 mode 802.3ad miimon 100
nmcli connection modify bond0 connection.autoconnect yes
nmcli connection modify bond0 ipv4.addresses 202.20.204.80/24
nmcli connection modify bond0 ipv4.gateway 202.20.204.254
nmcli connection modify bond0 ipv4.method manual
nmcli connection modify bond0 ipv6.method ignore

#bond0 slave config
nmcli connection add con-name eno1 type ethernet ifname eno1 connection.autoconnect yes master bond0
nmcli connection add con-name eno2 type ethernet ifname eno2 connection.autoconnect yes master bond0
nmcli connection add con-name ib0 type infiniband ifname ib0 connection.autoconnect yes ipv4.addresses 192.168.204.80/16 ipv4.method manual ipv6.method disabled ipv4.never-default yes connection.autoconnect yes

#delete UUID
sed -i '/UUID/d' /etc/sysconfig/network-scripts/ifcfg-bond0
sed -i '/UUID/d' /etc/sysconfig/network-scripts/ifcfg-eno1
sed -i '/UUID/d' /etc/sysconfig/network-scripts/ifcfg-eno2
sed -i '/UUID/d' /etc/sysconfig/network-scripts/ifcfg-ib0

nmcli networking on
systemctl restart NetworkManager

#check
nmcli -p con

