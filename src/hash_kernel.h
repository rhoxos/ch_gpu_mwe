#ifndef HASH_KERNEL_H
#define HASH_KERNEL_H

#include <vector>
#include <mutex>
#include <algorithm>


void allocateDeviceMemory(void** M, int width);
void allocateDeviceMemoryAsync(void** M, int width);
void deallocateDeviceMemory(void* M);

void cudaMemcpyToDevice(void* dst, void* src, int size);
void cudaMemcpyToHost(void* dst, void* src, int size);


void split_tables(int device_num,
                  const unsigned long long* const tableA, const unsigned long long* const tableB,
                  unsigned long long *tableA_size, unsigned long long *tableB_size,
                  unsigned long long **tableA_split, unsigned long long **tableB_split,
                  const int R, const int S);

void gpu_main();
#endif
