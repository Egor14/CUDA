#include <mpi.h>
#include <iostream>
#include <ctime>
#include "stdlib.h"
#include "stdio.h"

using namespace std;

void print(int *mas, int n);

void init(int *mas, int size);

int main(int argc, char **argv)
{
	int size, rank;
	int const N = 8;
	MPI_Status Status;
	MPI_Init(&argc, &argv);
	MPI_Comm_size(MPI_COMM_WORLD, &size);
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);

	int A[N * N];
	init(A, N * N);

	int B[N * N];
	init(B, N * N);

	int C[N * N];

	int my_line_A[N];
	int my_recv_B[N];

	for (int j = 0; j < N; j++)
	{
		my_line_A[j] = A[rank*N + j];
		my_recv_B[j] = B[j*N + rank];
	}

	for (int i = 0; i < N*N; i++)
	{
		C[i] = 0;
	}

	for (int i = 0; i < size; i++)
	{
		for (int j = 0; j < N; j++)
		{
			C[rank*size + i] += my_line_A[j] * my_recv_B[j];
		}
		MPI_Send(my_recv_B, N, MPI_INT, (rank + 1) % size, 0, MPI_COMM_WORLD);
		MPI_Recv(my_recv_B, N, MPI_INT, (rank - 1 + size) % size, 0, MPI_COMM_WORLD, &Status);
	}

	if (rank == 0)
	{
		print(C, N);
	}

	MPI_Finalize();

	return 0;
}

void print(int *mas, int n)
{
	for (int i = 0; i < n; i++)
	{
		for (int j = 0; j < n; j++)
		{
			cout << mas[i*n + j] << " " ;
		}
	cout << endl;
	}
}

void init(int *mas, int size)
{
	srand( time(0));
	for (int i = 0; i < size; i++)
	{
		mas[i] = rand() % 1000;
	}
} 