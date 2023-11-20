#!/bin/bash
set -x

interrupt_handler() {
  exit 1
}
trap interrupt_handler SIGINT

IFACE=eth0

is_ali_cloud=0

IP_A=192.168.0.1
IP_B=192.168.0.2
IP_C=192.168.0.3
IP_D=192.168.0.4

BENCHMARK=./example
export XFT_ONECCL=1
export XFT_COMM_TIME=0
export XFT_FAKE_MODEL=1

# open for MPI debug information
MPI_DEBUG="-prot -verbose -print-rank-map -print-all-exitcodes"

function run_1device_1s_1ins() {
  numa_node_0=0
  numa_node_0_hbm=0
  mpirun -iface=${IFACE} $MPI_DEBUG \
    -n 1 -hosts ${IP_A} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 0
} &> test_run_1device_1s_1ins_${model_name}_${data_type}_${thread_count}_${loop_count}_${input_length}_${output_length}_${batch_size}.log

function run_1device_1s_2ins() {
  numa_node_0=0
  numa_node_0_hbm=0
  mpirun -iface=${IFACE} $MPI_DEBUG \
    -n 1 -hosts ${IP_A} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 0 : \
	  -n 1 -hosts ${IP_A} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 1
} &> test_run_1device_1s_2ins_${model_name}_${data_type}_${thread_count}_${loop_count}_${input_length}_${output_length}_${batch_size}.log

function run_1device_2s_1ins() {
  numa_node_0=0
  numa_node_0_hbm=0
  numa_node_1=1
  numa_node_1_hbm=1
  mpirun -iface=${IFACE} $MPI_DEBUG \
    -n 1 -hosts ${IP_A} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 0 : \
	  -n 1 -hosts ${IP_A} sh run.sh $numa_node_1 $numa_node_1_hbm $thread_count 1
} &> test_run_1device_2s_1ins_${model_name}_${data_type}_${thread_count}_${loop_count}_${input_length}_${output_length}_${batch_size}.log

function run_1device_2s_2ins() {
  numa_node_0=0
  numa_node_0_hbm=0
  numa_node_1=1
  numa_node_1_hbm=1
  mpirun -iface=${IFACE} $MPI_DEBUG \
    -n 1 -hosts ${IP_A} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 0 : \
    -n 1 -hosts ${IP_A} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 1 : \
    -n 1 -hosts ${IP_A} sh run.sh $numa_node_1 $numa_node_1_hbm $thread_count 2 : \
    -n 1 -hosts ${IP_A} sh run.sh $numa_node_1 $numa_node_1_hbm $thread_count 3
} &> test_run_1device_2s_2ins_${model_name}_${data_type}_${thread_count}_${loop_count}_${input_length}_${output_length}_${batch_size}.log

function run_2device_2s_1ins() {
  numa_node_0=0
  numa_node_0_hbm=0
  numa_node_1=1
  numa_node_1_hbm=1
  mpirun -iface=${IFACE} $MPI_DEBUG \
    -n 1 -hosts ${IP_A} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 0 : \
    -n 1 -hosts ${IP_A} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 1 : \
    -n 1 -hosts ${IP_B} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 0 : \
    -n 1 -hosts ${IP_B} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 1
} &> test_run_2device_2s_1ins_${model_name}_${data_type}_${thread_count}_${loop_count}_${input_length}_${output_length}_${batch_size}.log

current_dir=$(pwd)
workspace_dir=$(echo $current_dir | sed 's|\(.*\/xFasterTransformer\).*|\1|')
model_paths=$(ls -d $workspace_dir/examples/model_config/*/)
data_types=("fp16" "bf16" "int8" "bf16_fp16" "bf16_int8")
batch_size=1
input_length=32
output_length=200
loop_count=3
thread_count=32
node_counts=("1" "2" "4")

# enable HBM flat
enable_hbm=0

func_name=run_1device_1s_1ins

# 输出结果
echo "workspace_dir: $workspace_dir"
echo "current_dir: $current_dir"
# echo "model_paths: $model_paths"

# 循环遍历所有参数组合
for model_path in $model_paths; do
    for data_type in "${data_types[@]}"; do
    ######################################################
      export model_name=$(basename "$model_path")
      export BENCHMARK=$BENCHMARK
      export data_type=$data_type
      export model_path=$model_path
      export model_token_path=$model_path/tokenizer.model
      export thread_count=$thread_count
      export loop_count=$loop_count
      export input_length=$input_length
      export output_length=$output_length
      export batch_size=$batch_size

      run_1device_1s_1ins
      run_1device_2s_1ins
      run_2device_2s_1ins
    ######################################################
    done
done
