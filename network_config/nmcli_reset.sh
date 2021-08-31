#!/bin/bash

#clean up
nmcli networking off
nmcli con del eno1
nmcli con del eno2
nmcli con del bond0
nmcli con del ib0

systemctl restart NetworkManager

#default set
nmcli connection add con-name eno1 type ethernet ifname eno1 connection.autoconnect yes ipv4.addresses 202.20.204.80/24 ipv4.gateway 202.20.204.254 ipv4.method manual


nmcli networking on
systemctl restart NetworkManager

#check
nmcli -p con

