# xFasterTransformer

此文件夹下主要包含xFasterTransformer分布式测试的使用说明。

## prequirements
- 安装ansible依赖
```shell
pip install -r requirements.txt
```

## network benchmark

```shell
[root@xftest001 distributed]# ./IMB-MPI1 allreduce
#----------------------------------------------------------------
#    Intel(R) MPI Benchmarks 2021.3, MPI-1 part
#----------------------------------------------------------------
# Date                  : Mon Nov 20 19:56:00 2023
# Machine               : x86_64
# System                : Linux
# Release               : 5.10.134-15.al8.x86_64
# Version               : #1 SMP Thu Jul 20 00:44:04 CST 2023
# MPI Version           : 3.1
# MPI Thread Environment: 


# Calling sequence was: 

# ./IMB-MPI1 allreduce 

# Minimum message length in bytes:   0
# Maximum message length in bytes:   4194304
#
# MPI_Datatype                   :   MPI_BYTE 
# MPI_Datatype for reductions    :   MPI_FLOAT 
# MPI_Op                         :   MPI_SUM  
# 
# 

# List of Benchmarks to run:

# Allreduce

#----------------------------------------------------------------
# Benchmarking Allreduce 
# #processes = 1 
#----------------------------------------------------------------
       #bytes #repetitions  t_min[usec]  t_max[usec]  t_avg[usec]
            0         1000         0.04         0.04         0.04
            4         1000         0.04         0.04         0.04
            8         1000         0.04         0.04         0.04
           16         1000         0.04         0.04         0.04
           32         1000         0.04         0.04         0.04
           64         1000         0.04         0.04         0.04
          128         1000         0.04         0.04         0.04
          256         1000         0.04         0.04         0.04
          512         1000         0.05         0.05         0.05
         1024         1000         0.05         0.05         0.05
         2048         1000         0.05         0.05         0.05
         4096         1000         0.07         0.07         0.07
         8192         1000         0.08         0.08         0.08
        16384         1000         0.13         0.13         0.13
        32768         1000         0.75         0.75         0.75
        65536          640         1.49         1.49         1.49
       131072          320         3.05         3.05         3.05
       262144          160         6.17         6.17         6.17
       524288           80        12.11        12.11        12.11
      1048576           40        25.30        25.30        25.30
      2097152           20       146.44       146.44       146.44
      4194304           10       291.86       291.86       291.86


# All processes entering MPI_Finalize
```

## 分布式测试