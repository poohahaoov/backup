#!/bin/bash

echo `hostname`
echo "Core Qty :  "`lscpu | grep 'CPU(s):' | grep -v NUMA`
echo "NUMA : " `numactl -H | grep avail`
echo "Firewall : " `systemctl status firewalld.service  | grep Active`
echo "SELinux : "`sestatus`
echo "MLNX_OFED : "`ofed_info | head -n 1`
echo "memlock : " `ulimit -l`
echo "stack size : " `ulimit -s`
echo "open files : " `ulimit -n`
echo "docker : " `docker -v`
echo "runlevel : " `systemctl get-default`
echo "GPU Driver : " ` nvidia-smi | grep Version | awk '{ print $4,$5,$6 }'`
echo "cuda version : " `ls /usr/local | egrep "10.2|11.2" | wc -l`
echo "NVIDIA Persistence : "`systemctl status nvidia-persistenced.service  | grep Active`
echo "nv_peer_mem module : " `systemctl status nv_peer_mem.service  | grep Active`
echo "NVIDIA fabric manager : "

if [ -e /etc/environment-modules/modulespath ] ; then
        echo "module exist"
else
        echo "module NOT exist !!!!!!!!!!!!!!!!!!!!!!!!"
fi
