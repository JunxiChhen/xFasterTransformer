import os
import numpy as np

def process_log_files():
    log_files = [file for file in os.listdir() if file.endswith(".log")]
    print("model " "instance " "data_type " "input_len "  "first_comm " "second_comm " "first_token " "second_token")

    for log_file in log_files:
        first_tokens = []
        second_tokens = []
        first_comm_tokens = []
        second_comm_tokens = []
        # 按照"_"来拆分文件名
        file_name = log_file.split(".")[0]
        file_name_parts = file_name.split("_")

        # 打印拆分后的文件名部分
        # print(f"File: {log_file}, Parts: {file_name_parts}")
        with open(log_file, 'r') as file:
            for line in file:
                if "[INFO] First token time" in line:
                    # 以空格分隔并将最后一个数字保存到first_tokens数组
                    tokens = line.split()
                    first_tokens.append(float(tokens[-2]))
                elif "[INFO] Second token time" in line:
                    # 以空格分隔并将最后一个数字保存到second_tokens数组
                    tokens = line.split()
                    second_tokens.append(float(tokens[-2]))
                elif "FP32 count 131072 time:" in line or "FP32 count 294912 time:" in line or "FP32 count 4194304 time:" in line or "FP32 count 9437184 time:" in line:
                    # 以空格分隔并将最后一个数字保存到first_comm_tokens数组
                    tokens = line.split()
                    first_comm_tokens.append(float(tokens[-2]))
                elif "FP32 count 4096 time:" in line or "FP32 count 9216 time:" in line:
                    # 以空格分隔并将最后一个数字保存到second_comm_tokens数组
                    tokens = line.split()
                    second_comm_tokens.append(float(tokens[-2]))
        
        # print("model" "instance" "data type" "input len"  "first comm" "second comm" "first token" "second token")
        print(file_name_parts[1], file_name_parts[-1], file_name_parts[3], file_name_parts[-2],
                np.median(first_comm_tokens), np.median(second_comm_tokens), np.median(first_tokens[1:]), np.median(second_tokens))

if __name__ == "__main__":
    process_log_files()