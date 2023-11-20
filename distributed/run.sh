#!/bin/bash
set -x

# $1: first token numa node.
# $2: second token numa node.
# $3: thread nums.
# $4: thread nums amount.

FIRST_TOKEN_WEIGHT_LOCATION=$1 NEXT_TOKEN_WEIGHT_LOCATION=$2 OMP_NUM_THREADS=$3 \
	taskset -c `expr $3 \* $4`-`expr $3 \* $4 + $3 - 1` \
	numactl -C `expr $3 \* $4`-`expr $3 \* $4 + $3 - 1` -m $2 $BENCHMARK -m $model_path -t $model_token_path -d $data_type -l $input_length --loop $loop_count --output_len $output_length -b $batch_size --no_stream