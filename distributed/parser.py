import os
import pandas as pd
import numpy as np
import sys
import argparse


data_types = ["bf16_fp16", "bf16_int8", "bf16", "fp16", "int8"]
model_names = ["baichuan2-7b", "baichuan2-13b", "chatglm-6b", "chatglm2-6b", "llama-2-7b", "llama-2-13b", "llama-2-70b", "llama-7b", "llama-13b", "opt-6.7b", "opt-30b", "opt-66b"]

# test_run_1device_1s_1ins_${model_name}_${data_type}_${thread_count}_${loop_count}_${input_length}_${output_length}_${batch_size}.log


parser = argparse.ArgumentParser()
parser.add_argument("--log_path", type=str, default="./logs", help="log file path")
parser.add_argument("--token_in", "-i", type=int, help="Input Token Len")
parser.add_argument("--token_out", "-o", type=int, help="Output Token Len, MaxLen=IN+OUT")
parser.add_argument("--percentile", "-p", type=int, default=90, help="percentile P90/P99")
args = parser.parse_args()

sheet = pd.DataFrame(columns=["device", "socket", "instance", "model", "dtype", "num_threads", "loop", "input_lens", "output_lens", "bs", f"P{args.percentile} infer latency(ms)", f"P{args.percentile} first_comm(ms)", f"P{args.percentile} second_comm(ms)", f"P{args.percentile} 1st token latency(ms)", f"P{args.percentile} 2nd token latency(ms)", "throughput(token/s)"])

if not os.path.exists(args.log_path):
    print(f"[Error] The file '{args.log_path}' not exists.")
    sys.exit(1)

LOG_PATH = os.path.abspath(args.log_path)
print("[Info] Parse log files at ", LOG_PATH)

def parse_file_name(file_name):
    row_data = []
    file_name = file_name[len("test_run_"):]
    row_data.append(file_name[0:1])
    file_name = file_name[(1 + len("device_")):]

    row_data.append(file_name[0:1])
    file_name = file_name[(1 + len("s_")):]

    row_data.append(file_name[0:1])
    file_name = file_name[(1 + len("ins_")):]

    model_name = [name for name in model_names if file_name.startswith(name)][0]
    row_data.append(model_name)
    file_name = file_name[len(model_name) + 1:]

    dtype = [name for name in data_types if file_name.startswith(name)][0]
    row_data.append(dtype)

    row_data += file_name[len(dtype) + 1:-4].split("_")
    return row_data

def parse_file_content(file_name):
    file_path = os.path.join(LOG_PATH, file_name)
    rtn_map = {
        "inferlatency": float(-1),
        "first_comm": float(-1),
        "second_comm": float(-1),
        "1st_token": float(-1),
        "2nd_token": float(-1),
        "throughput": float(-1),
    }

    first_tokens = []
    second_tokens = []
    inferlatency = []
    # todo(marvin): add comm time collect.
    first_comm_tokens = []
    second_comm_tokens = []

    with open(file_path, 'r') as file:
        for line in file:
            if "[INFO] First token time" in line:
                # 以空格分隔并将最后一个数字保存到first_tokens数组
                tokens = line.split()
                first_tokens.append(float(tokens[-2]))
            elif "[INFO] Second token time" in line:
                # 以空格分隔并将最后一个数字保存到second_tokens数组
                tokens = line.split()
                second_tokens.append(float(tokens[-2]))
            elif "[INFO] inference latency time" in line:
                # 以空格分隔并将最后一个数字保存到second_tokens数组
                tokens = line.split()
                inferlatency.append(float(tokens[-2]))
            elif "FP32 count 131072 time:" in line or "FP32 count 294912 time:" in line or "FP32 count 4194304 time:" in line or "FP32 count 9437184 time:" in line:
                # 以空格分隔并将最后一个数字保存到first_comm_tokens数组
                tokens = line.split()
                first_comm_tokens.append(float(tokens[-2]))
            elif "FP32 count 4096 time:" in line or "FP32 count 9216 time:" in line:
                # 以空格分隔并将最后一个数字保存到second_comm_tokens数组
                tokens = line.split()
                second_comm_tokens.append(float(tokens[-2]))
        
        rtn_map["inferlatency"] = np.percentile(inferlatency[1:], args.percentile) if len(inferlatency) > 1 else rtn_map["inferlatency"]
        rtn_map["first_comm"] = np.percentile(first_comm_tokens, args.percentile) if len(first_comm_tokens) > 1 else rtn_map["first_comm"]
        rtn_map["second_comm"] = np.percentile(second_comm_tokens, args.percentile) if len(second_comm_tokens) > 1 else rtn_map["second_comm"]
        rtn_map["1st_token"] = np.percentile(first_tokens[1:], args.percentile) if len(first_tokens) > 1 else rtn_map["1st_token"]
        rtn_map["2nd_token"] = np.percentile(second_tokens, args.percentile) if len(second_tokens) > 1 else rtn_map["2nd_token"]
        rtn_map["throughput"] = (args.token_out / rtn_map["inferlatency"] * 1000) if rtn_map["inferlatency"] != -1 else rtn_map["throughput"]
    return [*rtn_map.values()]

def process_log_files():
    log_files = [file for file in os.listdir(LOG_PATH) if file.endswith(".log") and file.startswith("test_run")]
    for index, file_name in enumerate(log_files):
        name_params = parse_file_name(file_name)
        # file_params = parse_file_content(os.path.join(LOG_PATH, file_name))
        sheet.loc[index] = parse_file_name(file_name) + parse_file_content(file_name)

    print(sheet)
    sheet.to_excel(os.path.join(LOG_PATH, f"xft_perfs_data_{os.path.basename(LOG_PATH)}.xlsx"), index=0)

if __name__ == "__main__":
    process_log_files()