#!/bin/bash
set -x

interrupt_handler() {
  exit 1
}
trap interrupt_handler SIGINT

function run_1device_1s_1ins() {
  numa_node_0=0
  numa_node_0_hbm=0
  mpirun -iface=${IFACE} $MPI_DEBUG \
    -n 1 -hosts ${IP_A} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 0
} &> $logs_dir/test_run_1device_1s_1ins_${model_name}_${data_type}_${thread_count}_${loop_count}_${input_length}_${output_length}_${batch_size}.log

function run_1device_1s_2ins() {
  numa_node_0=0
  numa_node_0_hbm=0
  mpirun -iface=${IFACE} $MPI_DEBUG \
    -n 1 -hosts ${IP_A} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 0 : \
	  -n 1 -hosts ${IP_A} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 1
} &> $logs_dir/test_run_1device_1s_2ins_${model_name}_${data_type}_${thread_count}_${loop_count}_${input_length}_${output_length}_${batch_size}.log

function run_1device_1s_4ins() {
  numa_node_0=0
  numa_node_0_hbm=0
  mpirun -iface=${IFACE} $MPI_DEBUG \
    -n 1 -hosts ${IP_A} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 0 : \
    -n 1 -hosts ${IP_A} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 1 : \
    -n 1 -hosts ${IP_A} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 2 : \
	  -n 1 -hosts ${IP_A} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 3
} &> $logs_dir/test_run_1device_1s_4ins_${model_name}_${data_type}_${thread_count}_${loop_count}_${input_length}_${output_length}_${batch_size}.log

function run_1device_2s_1ins() {
  numa_node_0=0
  numa_node_0_hbm=0
  numa_node_1=1
  numa_node_1_hbm=1
  mpirun -iface=${IFACE} $MPI_DEBUG \
    -n 1 -hosts ${IP_A} sh run.sh $numa_node_0 $numa_node_0_hbm $thread_count 0 : \
	  -n 1 -hosts ${IP_A} sh run.sh $numa_node_1 $numa_node_1_hbm $thread_count 1
} &> $logs_dir/test_run_1device_2s_1ins_${model_name}_${data_type}_${thread_count}_${loop_count}_${input_length}_${output_length}_${batch_size}.log

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
} &> $logs_dir/test_run_1device_2s_2ins_${model_name}_${data_type}_${thread_count}_${loop_count}_${input_length}_${output_length}_${batch_size}.log

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
} &> $logs_dir/test_run_2device_2s_1ins_${model_name}_${data_type}_${thread_count}_${loop_count}_${input_length}_${output_length}_${batch_size}.log


############# PATH configuration #############
current_dir=$(pwd)
workspace_dir=$(echo $current_dir | sed 's|\(.*\/xFasterTransformer\).*|\1|')
build_dir=$(echo $workspace_dir/build)

# change the workspace status
if [ ! -d $build_dir ]; then
    echo "[Error] please build project in $build_dir"
    exit 1
fi

if [ "$current_dir" != "$workspace_dir/distributed" ]; then
    echo "[Error] please test in $workspace_dir/distributed"
    exit 1
fi

logs_dir=$(echo $current_dir/logs/`date "+%Y-%m-%d-%H:%M:%S"`)
mkdir -p $logs_dir

############# HW configuration #############
IFACE=eth0
IP_A=192.168.0.1
IP_B=192.168.0.2
IP_C=192.168.0.3
IP_D=192.168.0.4

# enable it if testing at a cloud environment
export is_ali_cloud=0

# sync manual
# scp -r $workspace_dir/* $IP_B:$workspace_dir/

# todo(marvin): enable HBM flat
enable_hbm=0

############# XFT configuration #############
BENCHMARK=$build_dir/example
export XFT_ONECCL=1
export XFT_COMM_TIME=0
export XFT_FAKE_MODEL=1

# open for MPI debug information
MPI_DEBUG="-prot -verbose -print-rank-map -print-all-exitcodes"

############# BENCHMARK configuration #############
batch_size=1
loop_count=5
input_length=32
output_length=200
thread_count=48
# data_types=("fp16" "bf16" "int8" "bf16_fp16" "bf16_int8")
data_types=("fp16")
# model_paths=$(ls -d $workspace_dir/examples/model_config/*/)
model_paths=$(ls -d $workspace_dir/examples/model_config/chatglm2-6b/)

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
      # run_1device_2s_1ins
      # run_2device_2s_1ins
    ######################################################
    done
done

######################## Parse log ########################
# usage: parser.py [-h] [--log_path LOG_PATH] [--token_in TOKEN_IN] [--token_out TOKEN_OUT] [--percentile PERCENTILE]
# 
# optional arguments:
#   -h, --help            show this help message and exit
#   --log_path LOG_PATH   log file path
#   --token_in TOKEN_IN, -i TOKEN_IN
#                         Input Token Len
#   --token_out TOKEN_OUT, -o TOKEN_OUT
#                         Output Token Len, MaxLen=IN+OUT
#   --percentile PERCENTILE, -p PERCENTILE
#                         percentile P90/P99
python parser.py --log_path $logs_dir -i $input_length -o $output_length