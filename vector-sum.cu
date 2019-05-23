#include "cuda.h"
#include "stdlib.h"
#include "stdio.h"
#include <iostream>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <ctime>

using namespace std;

cudaEvent_t start, end;
float Time = 0;

__global__ void sum_N_1(int *res, int *mas1, int *mas2)
{
	int i = blockIdx.x;
	res[i] = mas1[i] + mas2[i];
}

__global__ void sum_1_N(int *res, int *mas1, int *mas2)
{
	int i = threadIdx.x;
	res[i] = mas1[i] + mas2[i];
}

__global__ void sum(int *res, int *mas1, int *mas2)
{
	int i = threadIdx.x + blockIdx.x * blockDim.x;
	res[i] = mas1[i] + mas2[i];
}

void init(int *mas, int size);

void start_time();

void stop_time();

int main()
{
	int N = 100000, size = 100000;

	int *mas1 = new int[size];
	init(mas1, size);
	int *mas2 = new int[size];
	init(mas2, size);
	int *res = new int[size];

	int *cudaMas1;
	int *cudaMas2;
	int *cudaRes;

	cudaMalloc((void**)&cudaMas1, sizeof(int) * size);
	cudaMalloc((void**)&cudaMas2, sizeof(int) * size);
	cudaMalloc((void**)&cudaRes,  sizeof(int) * size);

	cudaMemcpy(cudaMas1, mas1, sizeof(int) * size, cudaMemcpyHostToDevice);
	cudaMemcpy(cudaMas2, mas2, sizeof(int) * size, cudaMemcpyHostToDevice);
	cudaMemcpy(cudaRes,  res,  sizeof(int) * size, cudaMemcpyHostToDevice);

	cudaEventCreate(&start);
	cudaEventCreate(&end);

	cout << "Сравним время работы в разных режимах";
	cout << "<<< 1,1 >>>" << endl;
	start_time();
	for (int i = 0; i < size; i++)
		sum<<<1,1>>>(&cudaRes[i], &cudaMas1[i], &cudaMas2[i]);
	cudaDeviceSynchronize();
	cudaMemcpy(res, cudaRes, sizeof(int) * size, cudaMemcpyDeviceToHost);
	stop_time();
	cout << "<<< 1, N >>>" << endl;
	start_time();
	sum_1_N<<<1,N>>>(cudaRes, cudaMas1, cudaMas2);
	cudaDeviceSynchronize();
	cudaMemcpy(res, cudaRes, sizeof(int) * size, cudaMemcpyDeviceToHost);
	stop_time();
	cout << "<<< N,1 >>>" << endl;
	start_time();
	sum_N_1<<<N,1>>>(cudaRes, cudaMas1, cudaMas2);
	cudaDeviceSynchronize();
	cudaMemcpy(res, cudaRes, sizeof(int) * size, cudaMemcpyDeviceToHost);
	stop_time();
	cout << "<<< (Num_elements + (Num_threads - 1))/Num_threads , Num_threads >>>" << endl;
	start_time();
	sum<<<(N + 31) / 32, 32>>>(cudaRes, cudaMas1, cudaMas2);
	cudaDeviceSynchronize();
	cudaMemcpy(res, cudaRes, sizeof(int) * size, cudaMemcpyDeviceToHost);
	stop_time();
	cudaFree(cudaMas1);
	cudaFree(cudaMas2);
	cudaFree(cudaRes);

	return 0;
}


void init(int *mas, int size)
{
	srand( time(0));
	for (int i = 0; i < size; i++)
	{
		mas[i] = rand() % 1000;
	}
} 

void start_time()
{
	cudaEventRecord(start);
}

void stop_time()
{
	cudaEventRecord(end);
	cudaEventSynchronize(end);	
	cudaEventElapsedTime(&Time, start, end);
	cout << "Время работы \n" << Time << endl;
}
