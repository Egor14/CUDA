#include "cuda.h"
#include "stdlib.h"
#include "stdio.h"
#include <iostream>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <ctime>

using namespace std;

__global__ void sum_cuda(int *res, int *mas1, int *mas2, int N, int M)
{
	int i = threadIdx.x + blockIdx.x * blockDim.x;
	int j = threadIdx.y + blockIdx.y * blockDim.y;
	int tx = i * N + j;
	res[tx] = mas1[tx] + mas2[tx];
}

void init(int *mas, int size);

void sum(int *res, int *mas1, int *mas2, int N, int M);

void print(int *mas, int N, int M);

int main()
{
	int N = 4, M = 4, dimN = 2, dimM = 2;

	int mas1[N * M];
	init(mas1, N * M);

	int mas2[N * M];
	init(mas2, N*M);

	int *res = new int[N * M];

	int *cudaMas1;
	int *cudaMas2;
	int *cudaRes;

	float time = 0;

	cudaMalloc((void**)&cudaMas1, sizeof(int) * N * M);
	cudaMalloc((void**)&cudaMas2, sizeof(int) * N * M);
	cudaMalloc((void**)&cudaRes,  sizeof(int) * N * M);

	cudaMemcpy(cudaMas1, mas1, sizeof(int) * N * M, cudaMemcpyHostToDevice);
	cudaMemcpy(cudaMas2, mas2, sizeof(int) * N * M, cudaMemcpyHostToDevice);
	cudaMemcpy(cudaRes,  res,  sizeof(int) * N * M, cudaMemcpyHostToDevice);

	cudaEvent_t start, end;
	cudaEventCreate(&start);
	cudaEventCreate(&end);

	print(mas1, N, M);
	print(mas2, N, M);

	cudaEventRecord(start);
	sum(res, mas1, mas2, N, M);
	cudaEventRecord(end);
	cudaEventSynchronize(end);	

	print(res, N, M);
	cudaEventElapsedTime(&time, start, end);
	cout << "Последовательно " << time << endl;

	dim3 blocks(N / dimN, M / dimM);
	dim3 threads(dimN, dimM);

	cudaEventRecord(start);
	sum_cuda<<< blocks, threads >>>(cudaRes, cudaMas1, cudaMas2, N, M);
	cudaDeviceSynchronize();
	cudaEventRecord(end);

	cudaMemcpy(res, cudaRes, sizeof(int) * N * M, cudaMemcpyDeviceToHost);

	print(res, N, M);
 	cudaEventElapsedTime(&time, start, end);
   	cout << "Параллельно " << time << endl;

	cudaFree(cudaMas1);
	cudaFree(cudaMas2);
	cudaFree(cudaRes);

	return 0;
}


void sum(int *res, int *mas1, int *mas2, int N, int M)
{
	for (int i = 0; i < N; i++){
		for (int j = 0; j < M; j++)
			res[i*N + j] = mas1[i*N + j] + mas2[i*N + j];
	}
}

void print(int *mas, int N, int M)
{
	for (int i = 0; i < N; i++){
		for (int j = 0; j < M; j++)
			cout << mas[i*N + j] << " ";
		cout << endl;
	}
	cout << endl;
}

void init(int *mas, int size)
{
	srand( time(0));
	for (int i = 0; i < size; i++)
	{
		mas[i] = rand() % 1000;
	}
} 
