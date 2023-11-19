#!/bin/bash
set -x

export XFT_ONECCL=1

XFT_FAKE_MODEL=1 ENABLE_COMM_TIME=1 OMP_NUM_THREADS=$3 FIRST_TOKEN_WEIGHT_LOCATION=$1 NEXT_TOKEN_WEIGHT_LOCATION=$2 \
	taskset -c `expr $3 \* $4`-`expr $3 \* $4 + $3 - 1` \
	numactl -C `expr $3 \* $4`-`expr $3 \* $4 + $3 - 1` -m $2 ./example -m /data/opt-66b-cpu-dumy/cpu -t /data/opt-66b-cpu-dumy/cpu -d bf16_fp16 -l 1024 --loop 1000 --output_len 32 -b 1 --no_stream