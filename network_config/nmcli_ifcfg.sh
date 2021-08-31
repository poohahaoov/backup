#!/bin/bash

#clean up
nmcli networking off
nmcli con del eno1
nmcli con del eno2
nmcli con del bond0
nmcli con del ib0

systemctl restart NetworkManager
nmcli networking off


# bond0 - Bond Master
cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-bond0
BONDING_OPTS="mode=802.3ad miimon=100"
TYPE=Bond
BONDING_MASTER=yes
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=no
NAME=bond0
DEVICE=bond0
ONBOOT=yes
IPADDR=202.20.204.80
PREFIX=24
GATEWAY=202.20.204.254
EOF

# eno1 - Bond Slave1
cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-eno1
TYPE=Ethernet
NAME=eno1
DEVICE=eno1
ONBOOT=yes
MASTER=bond0
SLAVE=yes
EOF

# eno2 - Bond Slave2
cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-eno2
TYPE=Ethernet
NAME=eno2
DEVICE=eno2
ONBOOT=yes
MASTER=bond0
SLAVE=yes
EOF

# ib0 - infiniband
cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-ib0
TYPE=InfiniBand
PROXY_METHOD=none
BOOTPROTO=none
DEFROUTE=no
IPADDR=192.168.204.80
PREFIX=16
IPV6_DISABLED=yes
IPV6INIT=no
NAME=ib0
DEVICE=ib0
ONBOOT=yes
EOF

# ifcfg file load
nmcli con load /etc/sysconfig/network-scripts/ifcfg-bond0
nmcli con load /etc/sysconfig/network-scripts/ifcfg-eno1
nmcli con load /etc/sysconfig/network-scripts/ifcfg-eno2
nmcli con load /etc/sysconfig/network-scripts/ifcfg-ib0
                                                             
#networking up
systemctl restart NetworkManager
nmcli con reload
nmcli networking on

#check
nmcli -p con
