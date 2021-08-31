#!/bin/bash

export LD_LIBRARY_PATH=/home/sr4/taesooism.kim/BMT/HPL/hpl-blis-mt-gcc/amd-blis/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/sr4/taesooism.kim/local/rhel8/openmpi-4.1.1/lib:$LD_LIBRARY_PATH
export PATH=/home/sr4/taesooism.kim/local/rhel8/openmpi-4.1.1/bin:$PATH
export OMP_NUM_THREADS=1

cd /home/sr4/taesooism.kim/BMT/HPL/hpl-blis-mt-gcc

cmp HPL.64n1t HPL.dat
if [ 0 -ne $?  ];then
cp -v HPL.64n1t HPL.dat
fi


echo "### 64-Core 1-Thread Ns-65536 ######################################"
#mpirun -bind-to core -mca btl ^openib -np 64 ./xhpl
#mpirun --allow-run-as-root -bind-to core -mca btl ^openib -np 64 ./xhpl >& $HOSTNAME.hpl.log
#mpirun --allow-run-as-root -bind-to hwthread -mca btl ^openib -np 64 ./xhpl >& $HOSTNAME.hwthread.log
#mpirun --allow-run-as-root -bind-to scatter  -mca btl ^openib -np 64 ./xhpl >& $HOSTNAME.scatter.log
#mpirun --allow-run-as-root -bind-to core     -mca btl ^openib -np 64 ./xhpl >& $HOSTNAME.core.log

# OpenMPI openib
#mpirun -np 64 -map-by core -report-bindings -mca btl_openib_allow_ib true -mca btl_openib_if_include mlx5_0:1 -mca pml ob1 -mca btl openib,self,vader -x UCX_NET_DEVICES=mlx5_0:1 -x HCOLL_MAIN_IB=mlx5_0:1 ./xhpl 2>&1 | tee $HOSTNAME.hpl.log
mpirun -np 64 -map-by core -report-bindings \
       -mca btl_openib_allow_ib true -mca btl_openib_if_include mlx5_0:1 -mca pml ob1 -mca btl openib,self,vader -mca btl_openib_cpc_exclude rdmacm,udcm -mca btl_openib_verbose 1\
       ./xhpl 2>&1 | tee $HOSTNAME.hpl.log


# OpenMPI UCX Option
#mpirun -np 64 -map-by core -report-bindings -mca btl ^openib -mca pml ucx -mca osc ucx -mca coll_hcoll_enable 1 -x UCX_NET_DEVICES=mlx5_0:1 -x HCOLL_MAIN_IB=mlx5_0:1 ./xhpl 2>&1 | tee $HOSTNAME.hpl.log

#echo "### btl self ######################################"
#mpirun -bind-to core -mca btl self -np 64 ./xhpl
#
#echo "### shmem posix ######################################"
#mpirun -bind-to core -mca btl ^openib -mca shmem posix -np 64 ./xhpl
#
#echo "### shmem sysv ######################################"
#mpirun -bind-to core -mca btl ^openib -mca shmem sysv -np 64 ./xhpl
#
#echo "### shmem mmap ######################################"
#mpirun -bind-to core -mca btl ^openib -mca shmem mmap -np 64 ./xhpl
~
~
~
