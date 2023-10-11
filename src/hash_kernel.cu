#include "hash_kernel.h"
#include <stdio.h>
#include <iostream>
#include <chrono>
#include <assert.h>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <stdlib.h>
#include <math.h>


using namespace std;

void allocateDeviceMemory(void** M, int size)
{
    cudaError_t err = cudaMalloc(M, size);
    assert(err==cudaSuccess);
}

__global__ void gdata_init(unsigned long long *g_odata, int block_size)
{
    //unsigned int tid = threadIdx.x;
    unsigned int j = blockIdx.x * block_size + threadIdx.x;
    unsigned int thread_size = blockDim.x;
    unsigned int end = (blockIdx.x +1) * block_size;

    //g_odata[tid]=100;
    /*if(blockIdx.x==0)
    {
        printf("My j: %d, My tid: %d\n",j, tid);
    }*/

    while(j<end)
    {
        g_odata[j]=0;
        j+=thread_size;
    }
    //printf("Block Dim: %d // gridDim: %d\n",blockDim.x, gridDim.x);
    //__syncthreads();
}

__global__ void run_hist_both(unsigned long long *g_odata_a, unsigned long long *g_odata_b, int block_size, int data_end)
{
    extern  __shared__  unsigned long long sdata[];

    unsigned int tid = threadIdx.x;
    unsigned int starting_point = blockIdx.x * block_size + threadIdx.x;
    unsigned int j = starting_point;
    unsigned int end = (blockIdx.x +1) * block_size;
    unsigned int thread_size = blockDim.x;

    unsigned int sdata_end =  gridDim.x * thread_size;

    if(tid==0 && blockIdx.x==0)
    {
        printf("Grid Dim (Block Number): %d / Block Dim (Block Size, Thread size): %d /end: %d/ block size parameter: %d/ sdata end: %d\n",gridDim.x,blockDim.x, end, block_size,sdata_end);
    }
    //printf("Starting point: %d\n",starting_point);

    if(end>data_end)
    {
        end=data_end;
    }

    //if(tid==0) printf("Block id: %d / Start: %d / End: %d\n",blockIdx.x,j, sdata_end);

    while(j<sdata_end)///initializing __shared__
    {
        //printf("Current point: %d\n", j);
        sdata[j]=2;
        j+=thread_size;
    }
    __syncthreads();


    //int index = (g_idata_a[j]%gridDim.x)*thread_size+tid;
    //sdata[index]++;//error
    //sdata[0]++;//error
    sdata[0]=1;
    __syncthreads();

    for(int k=0;k<gridDim.x;k++)///recording the first part to g_odata
    {
        //g_odata[k*thread_size+tid] = sdata[k*thread_size+tid];
        //atomicAdd(&g_odata[0], temp);
        atomicAdd(&g_odata_a[k*thread_size+tid], sdata[k*thread_size+tid]);
        //g_odata_a[k*thread_size+tid] = sdata[k*thread_size+tid];
    }
    __syncthreads();

    j=starting_point;
    while(j<sdata_end)///initializing __shared__
    {
        sdata[j]=9;
        j+=thread_size;
    }
    //for(int k=0;k<sdata_end;k++) sdata[k]=0;
    __syncthreads();

    j=starting_point;
    /*while(j<end)
    {
        int index = (g_idata_b[j]%gridDim.x)*thread_size+tid;
        //atomicAdd(&sdata[index], 1);
        j+=thread_size;
    }
    __syncthreads();*/


    for(int k=0;k<gridDim.x;k++)///recording the first the second part to g_odata
    {
        atomicAdd(&g_odata_b[k*thread_size+tid], sdata[k*thread_size+tid]);//adding first_data_part_end so it can have both
        //g_odata_b[k*thread_size+tid] = sdata[k*thread_size+tid];
    }
}


void gpu_main()
{
    //printf("Setting Devices (WIP)\n");


    unsigned long long *GPUO_A;
    unsigned long long *GPUO_B;


    allocateDeviceMemory((void**)&GPUO_A, sizeof(unsigned long long)*(128));
    allocateDeviceMemory((void**)&GPUO_B, sizeof(unsigned long long)*(128));


    int block_size=10;
    int block_no =2;
    int thread_no=4;

    gdata_init<<< block_no, thread_no, sizeof(unsigned long long) * thread_no*block_no >>>((unsigned long long *) GPUO_A, block_size); //each block should look for block_size number of elements
    gdata_init<<< block_no, thread_no, sizeof(unsigned long long) * thread_no*block_no >>>((unsigned long long *) GPUO_B, block_size);

    printf("Init complete\n");

    run_hist_both<<< block_no, thread_no, sizeof(unsigned long long) * thread_no*block_no >>>((unsigned long long *) GPUO_A, (unsigned long long *) GPUO_B, block_size, 128); //each block should look for block_size number of elements
    unsigned long long * gpu_histogram;
    gpu_histogram = new unsigned long long[256];
    cudaMemcpy((void **) gpu_histogram, GPUO_A, sizeof(unsigned long long) * 64, cudaMemcpyDeviceToHost);
    for(int i=0;i<8;i++)
    {
        printf("A %d: %llu\n",i,gpu_histogram[i]);
    }

    printf("\n\n\n\n\n");

    cudaMemcpy((void **) gpu_histogram, GPUO_B, sizeof(unsigned long long) * 64, cudaMemcpyDeviceToHost);
    for(int i=0;i<8;i++)
    {
        printf("B %d: %llu\n",i,gpu_histogram[i]);
    }
    return;
}