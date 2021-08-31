#!/bin/bash

export LD_LIBRARY_PATH=/home/sr7/taesooism.kim/BMT/HPL/hpl-blis-mt-gcc/amd-blis/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/home/sr7/taesooism.kim/local/rhel8/openmpi-4.1.1/lib:$LD_LIBRARY_PATH
export PATH=/home/sr7/taesooism.kim/local/rhel8/openmpi-4.1.1/bin:$PATH
export OMP_NUM_THREADS=1

cd /home/sr7/taesooism.kim/BMT/HPL/hpl-blis-mt-gcc

for HOSTF in 2node_pfc
do
echo "### $HOSTF test ######################################"

   cmp HPL.2node.512gb HPL.dat
   if  [ 0 -ne $?  ];then
      cp -v HPL.2node.512gb HPL.dat
   fi

   TIMELOG=`date +%m%d%H%M`

   # OpenMPI openib
#   mpirun -rf $HOSTF -report-bindings \
   mpirun -hostfile $HOSTF -N 48 -map-by core -report-bindings \
          -mca btl openib,self,vader -mca btl_openib_verbose 1 -mca btl_openib_cpc_exclude rdmacm,udcm \
          -mca btl_openib_if_include mlx5_1:1 \
          -x LD_LIBRARY_PATH ./xhpl 2>&1 | tee $HOSTF.roce.openib.$TIMELOG.log

   # OpenMPI UCX Option
   # mpirun -hostfile $HOSTF --map-by  ppr:64:node --bind-to numa -mca btl ^openib --mca pml ucx -x UCX_NET_DEVICES=mlx5_0:1 -x LD_LIBRARY_PATH ./xhpl 2>&1 | tee 64node.roce.$TIMELOG.log
done
#ldd ./xhpl
#for NUM in 16 32 64 128 256
#for NUM in 64 128 256
#do
#   echo HPL.$NUM\node
#   cmp HPL.$NUM\node HPL.dat
#   if  [ 0 -ne $?  ];then
#      cp -v HPL.$NUM\node HPL.dat
#   fi
#
#   TIMELOG=`date +%m%d%H%M`
#   NP=$(expr $NUM \* 64)
#   echo $NP
#   mpirun -np $NP -hostfile cpu.0625.roce.node --map-by  ppr:64:node --bind-to numa -mca btl ^openib --mca pml ucx -x UCX_NET_DEVICES=mlx5_0:1 -x LD_LIBRARY_PATH ./xhpl 2>&1 | tee $NUM\node.roce.$TIMELOG.log
#   sync
#   sleep 5
#   mpirun -np $NP -hostfile cpu.0625.roce.node --map-by  ppr:64:node --bind-to numa -mca btl ^openib --mca pml ucx -x UCX_LOG_LEVEL=DEBUG -x UCX_NET_DEVICES=mlx5_0:1 -x LD_LIBRARY_PATH ./xhpl 2>&1 | tee $NUM\node.roce.$TIMELOG.log
#done
~
