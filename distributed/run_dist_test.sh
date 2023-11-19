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

IP_A=192.168.10.158
IP_B=192.168.10.151
#IP_A=192.168.10.158
#IP_B=192.168.10.151
#IP_A=192.168.14.151
#IP_B=192.168.14.158

export LOOP=6
export OLEN=256

function run_test() {
  export SLEN=$1
  export DTYPE=$2

  mpirun -iface=${IFACE} \
    -prot -verbose -print-rank-map -print-all-exitcodes \
    -n 1 -hosts ${IP_A} sh run-$MODEL.sh 0 `expr $HBM \* 2` $nth 0 : \
    -n 1 -hosts ${IP_A} sh run-$MODEL.sh 0 `expr $HBM \* 2` $nth 1 : \
    -n 1 -hosts ${IP_A} sh run-$MODEL.sh 1 `expr $HBM \* 2 + 1` $nth 2 : \
    -n 1 -hosts ${IP_A} sh run-$MODEL.sh 1 `expr $HBM \* 2 + 1` $nth 3 : \
    -n 1 -hosts ${IP_B} sh run-$MODEL.sh 0 `expr $HBM \* 2` $nth 0 : \
    -n 1 -hosts ${IP_B} sh run-$MODEL.sh 0 `expr $HBM \* 2` $nth 1 : \
    -n 1 -hosts ${IP_B} sh run-$MODEL.sh 1 `expr $HBM \* 2 + 1` $nth 2 : \
    -n 1 -hosts ${IP_B} sh run-$MODEL.sh 1 `expr $HBM \* 2 + 1` $nth 3 &> test_${MODEL}_${LOOP}_${DTYPE}_${SLEN}_8.log
}

# Tests
run_test 1024 fp16
run_test 32 fp16
run_test 1024 bf16_fp16
run_test 32 bf16_fp16

MODEL=opt

# Tests
run_test 1024 fp16
run_test 32 fp16
run_test 1024 bf16_fp16
run_test 32 bf16_fp16
