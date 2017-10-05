
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include "cuda.h"
#include "globals.h"

#define THREADS_PER_BLOCK 8

int* livesArrayActual;
int N;
int size;

int* d_livesArrayActual;
int* d_livesArrayNext;

using namespace std;

__host__ __device__ bool isCellAlive(int* array, int column, int row){
	return array[row*COLUMNS + column];

}
__device__ void setCellAlive(int* array, int column, int row){
	array[row*COLUMNS + column] = 1;
}
__device__ void setCellDead(int* array, int column, int row){
	array[row*COLUMNS + column] = 0;
}
__device__ int countAliveNeighbors(int* livesArray, int column, int row){
	int neighborColumn;
	int neighborRow;
	int aliveNeighbors = 0;
	for (int x = -1; x <= 1; x++){
		for (int y = -1; y <= 1; y++){
			if (x == 0 && y == 0) // itself bypass
				continue;
			neighborColumn = column+x;
			neighborRow = row+y;

			// edge conditions
			if (neighborColumn < 0){
				neighborColumn = COLUMNS-1;
			} else if (neighborColumn > COLUMNS-1){
				neighborColumn = 0;
			} if (neighborRow < 0){
				neighborRow = ROWS-1;
			} else if (neighborRow > ROWS-1){
				neighborRow = 0;
			}

			if (isCellAlive(livesArray, neighborColumn, neighborRow)){
				aliveNeighbors++;
			}
		}
	}
	return aliveNeighbors;
}


int* generateInitialLives(int seed, int aliveCellsSize){
	int* cellIndexes = (int*) malloc(sizeof(int)*aliveCellsSize);

	srand(seed);
	for (int i = 0; i < aliveCellsSize; i++){
		int cellIndex = rand() % (COLUMNS*ROWS);
		bool validRandom = true;

		for (int j = 0; j < i; j++){
			if (cellIndexes[j] == cellIndex){
				// need to pick another random number
				i--;
				validRandom = false;
				break;
			}
		}
		if (validRandom)
			cellIndexes[i] = cellIndex;
	}
	return cellIndexes;

}


void swapLivesArrays(int** livesArrayActual, int** livesArrayNext){
	int* aux;
	aux = *livesArrayActual;
	*livesArrayActual = *livesArrayNext;
	*livesArrayNext = aux;
}


int* init_game_data(){
	N = COLUMNS*ROWS;
	size = sizeof(int)*N;

	livesArrayActual = (int*) malloc(size);

	cudaError_t code = cudaSuccess;
	cudaMalloc((void **)&d_livesArrayActual, size);
	code = cudaGetLastError();
	if (code != cudaSuccess){
		printf("error alocating d_livesArrayActual\n");
	}
	cudaMalloc((void **)&d_livesArrayNext, size);
	code = cudaGetLastError();
	if (code != cudaSuccess){
		printf("error alocating d_livesArrayNext\n");
	}

	int initialAliveCellsSize = (int) COLUMNS*ROWS*0.3;
	int* initialAliveCells = generateInitialLives(1, initialAliveCellsSize);
	for (int i = 0; i < initialAliveCellsSize; i++){
		// initial set up of lives
		livesArrayActual[initialAliveCells[i]] = 1;
	}
	free(initialAliveCells);
	cudaMemcpy(d_livesArrayActual, livesArrayActual, size, cudaMemcpyHostToDevice);
	code = cudaGetLastError();
	if (code != cudaSuccess){
		printf("error copying d_livesArrayActual\n");
	}
	return livesArrayActual;
}

__global__ void refreshLife(int* livesArrayActual, int* livesArrayNext) {
	int index = threadIdx.x + blockIdx.x * blockDim.x;
	int row = floorf(index / COLUMNS);
	int column = index - row*COLUMNS;

	int aliveNeighbors = countAliveNeighbors(livesArrayActual, column, row);
	if ((isCellAlive(livesArrayActual, column, row) && (aliveNeighbors == 2 || aliveNeighbors == 3)) ||
			(!isCellAlive(livesArrayActual, column, row) && (aliveNeighbors == 3 || aliveNeighbors == 6))){
		// life condition
		setCellAlive(livesArrayNext, column, row);
	} else {
		// death condition
		setCellDead(livesArrayNext, column, row);
	}
}

/** 
* Ejecuta kernel y retorna tiempo (en ms) total de procesamiento del kernel.
**/
float kernel_wrapper(){
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaError_t code = cudaSuccess;

	cudaEventRecord(start);
	refreshLife<<<(N + THREADS_PER_BLOCK-1)/THREADS_PER_BLOCK,THREADS_PER_BLOCK>>>(d_livesArrayActual, d_livesArrayNext);
	cudaEventRecord(stop);
	cudaEventSynchronize(stop);
	float milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, start, stop);
	// error check
	code = cudaGetLastError();
	if (code != cudaSuccess){
		printf("error kernel refreshLife %s\n",  cudaGetErrorString(code));
		exit(-1);
	}
	return milliseconds;
}

int* fetch_gpu_data(){
	cudaError_t code = cudaSuccess;
	cudaMemcpy(livesArrayActual, d_livesArrayNext, size, cudaMemcpyDeviceToHost);
	code = cudaGetLastError();
	if (code != cudaSuccess){
		printf("error copying livesArrayActual %s\n",  cudaGetErrorString(code));
	}
	cudaDeviceSynchronize();
	swapLivesArrays(&d_livesArrayActual, &d_livesArrayNext);
	return livesArrayActual;
}
void free_cuda_resources(){
	cudaFree(d_livesArrayActual); cudaFree(d_livesArrayNext);

}






