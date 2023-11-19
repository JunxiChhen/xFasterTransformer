#!/bin/bash
set -x

scp -r ../../xFasterTransformer/* marvin@192.168.10.158:/data/workspace/xFasterTransformer/

# source /data/workspace/xFasterTransformer/3rdparty/oneCCL/build/_install/env/setvars.sh

# export I_MPI_FABRICS=ofi

# export I_MPI_OFI_PROVIDER="tcp;ofi_rxm"
#export I_MPI_OFI_PROVIDER="verbs;ofi_rxm"
# export I_MPI_OFI_PROVIDER="psm3"

node=8
nth=24
HBM=1

# IP_A=192.168.0.2
# IP_B=192.168.0.1
IP_A=192.168.10.158
IP_B=192.168.10.151
#IP_A=192.168.14.151
#IP_B=192.168.14.158

if [ "$node" -eq 1 ];then
mpirun -iface=${IFACE} \
	-prot -verbose -print-rank-map -print-all-exitcodes \
	-n 1 -hosts ${IP_A} sh run.sh 0 `expr $HBM \* 2` $nth 0

elif [ "$node" -eq 2 ];then
mpirun -iface=${IFACE} \
	-prot -verbose -print-rank-map -print-all-exitcodes \
	-n 1 -hosts ${IP_A} sh run.sh 0 `expr $HBM \* 2` $nth 0 : \
	-n 1 -hosts ${IP_B} sh run.sh 0 `expr $HBM \* 2` $nth 0

elif [ "$node" -eq 4 ];then
mpirun -iface=${IFACE} \
	-prot -verbose -print-rank-map -print-all-exitcodes \
	-n 1 -hosts ${IP_A} sh run.sh 0 `expr $HBM \* 2` $nth 0 : \
	-n 1 -hosts ${IP_A} sh run.sh 0 `expr $HBM \* 2` $nth 1 : \
	-n 1 -hosts ${IP_A} sh run.sh 1 `expr $HBM \* 2 + 1` $nth 2 : \
	-n 1 -hosts ${IP_A} sh run.sh 1 `expr $HBM \* 2 + 1` $nth 3

elif [ "$node" -eq 8 ];then
mpirun -iface=${IFACE} \
	-prot -verbose -print-rank-map -print-all-exitcodes \
	-n 1 -hosts ${IP_A} sh run.sh 0 `expr $HBM \* 2` $nth 0 : \
	-n 1 -hosts ${IP_A} sh run.sh 0 `expr $HBM \* 2` $nth 1 : \
	-n 1 -hosts ${IP_A} sh run.sh 1 `expr $HBM \* 2 + 1` $nth 2 : \
	-n 1 -hosts ${IP_A} sh run.sh 1 `expr $HBM \* 2 + 1` $nth 3 : \
	-n 1 -hosts ${IP_B} sh run.sh 0 `expr $HBM \* 2` $nth 0 : \
	-n 1 -hosts ${IP_B} sh run.sh 0 `expr $HBM \* 2` $nth 1 : \
	-n 1 -hosts ${IP_B} sh run.sh 1 `expr $HBM \* 2 + 1` $nth 2 : \
	-n 1 -hosts ${IP_B} sh run.sh 1 `expr $HBM \* 2 + 1` $nth 3
fi
