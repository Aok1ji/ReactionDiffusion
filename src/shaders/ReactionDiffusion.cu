#include <SFML/Config.hpp>
#include <cmath>
#include <csignal>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <cuda_runtime_api.h>
#include <cudart_platform.h>

#include <iostream>

#define CUDA_CALL(x) cudaError_t error = cudaGetLastError(); if (error != cudaSuccess) { std::cout << cudaGetErrorName(error) << std::endl; std::abort(); } x
 
struct Cell {
	float a = 1, 
		  b = 0;
};

enum eChemicals {
	A, 
	B
};

static struct CudaConfigs {
	int xThreads = 80,
		yThreads = 1;
} cConfig;


static sf::Uint8 *pPixelField;
static Cell *pCurrentGrid;
static Cell *pNextGrid;
static size_t xSize; 
static size_t ySize;

static float killRate = 0.90f; 
static float feedRate = 0.80f;

static float diffusionA = 1.0f;
static float diffusionB = 0.5f;

static float dT = 1.0f;


void CudaInit(size_t width, size_t height) { 
	xSize = width;
	ySize = height;

	CUDA_CALL(cudaSetDevice(0));
	cudaMalloc(&pCurrentGrid, width * height * sizeof(Cell));
	cudaMalloc(&pNextGrid, width * height * sizeof(Cell));
	cudaMalloc(&pPixelField, width * height * sizeof(sf::Uint8) * 4);
}

void CudaExit() {
	cudaFree(pCurrentGrid);
	cudaFree(pNextGrid);
	cudaFree(pPixelField);
}

__device__ float laplacian(eChemicals type, int x, int y, Cell* pCurrentGrid, size_t xSize, size_t ySize) {
	float sum = 0;
	if(x > 0 && x < xSize && y > 0 && y < ySize)
		switch (type) {
			case eChemicals::A:
				sum += pCurrentGrid[y * xSize + x].a * -1;
				sum += pCurrentGrid[y * xSize + (x - 1)].a * 0.2;
				sum += pCurrentGrid[y * xSize + (x + 1)].a * 0.2;
				sum += pCurrentGrid[(y + 1) * xSize + x].a * 0.2;
				sum += pCurrentGrid[(y - 1) * xSize + x].a * 0.2;	
				sum += pCurrentGrid[(y - 1) * xSize + (x - 1)].a * 0.05;
				sum += pCurrentGrid[(y - 1) * xSize + (x + 1)].a * 0.05;
				sum += pCurrentGrid[(y + 1) * xSize + (x - 1)].a * 0.05;
				sum += pCurrentGrid[(y + 1) * xSize + (x + 1)].a * 0.05;

				break;
			case eChemicals::B:
				sum += pCurrentGrid[y * xSize + x].b * -1;
				sum += pCurrentGrid[y * xSize + (x - 1)].b * 0.2;
				sum += pCurrentGrid[y * xSize + (x + 1)].b * 0.2;
				sum += pCurrentGrid[(y + 1) * xSize + x].b * 0.2;
				sum += pCurrentGrid[(y - 1) * xSize + x].b * 0.2;
				sum += pCurrentGrid[(y - 1) * xSize + (x - 1)].b * 0.05;
				sum += pCurrentGrid[(y - 1) * xSize + (x + 1)].b * 0.05;
				sum += pCurrentGrid[(y + 1) * xSize + (x - 1)].b * 0.05;
				sum += pCurrentGrid[(y + 1) * xSize + (x + 1)].b * 0.05;
		
				break;
		}	

	return sum;
}

__device__ float reactionA(float valueA, float valueB, int x, int y, Cell *pCurrentGrid, float killRate, float feedRate, float diffusionA, float dT, size_t xSize, size_t ySize) { 
	return valueA + ((diffusionA * laplacian(eChemicals::A, x, y, pCurrentGrid, xSize, ySize) * valueA) - (valueA * valueB * valueB) + (feedRate * (1 - valueA))) * dT;
}

__device__ float reactionB(float valueA, float valueB, int x, int y, Cell *pCurrentGrid, float killRate, float feedRate, float diffusionB ,float dT, size_t xSize, size_t ySize) { 
	return valueB + ((diffusionB * laplacian(eChemicals::B, x, y, pCurrentGrid, xSize, ySize) * valueB) + (valueA * valueB * valueB) - ((killRate + feedRate) * valueB)) * dT;
}

__global__ void setColor(sf::Uint8 *pPixelField, Cell* pCurrentGrid, size_t xSize) { 
	int x = blockIdx.x * blockDim.x + threadIdx.x;
	int y = blockIdx.y * blockDim.y + threadIdx.y;
	
	Cell& currCell = pCurrentGrid[y * xSize + x];
	
	size_t pixelAddress = 4 * (y * xSize + x);

	pPixelField[pixelAddress + 0] = std::floor(currCell.a * 255);
	pPixelField[pixelAddress + 1] = std::floor((currCell.a + currCell.b) * 255);
	pPixelField[pixelAddress + 2] = std::floor(currCell.b * 255);
	pPixelField[pixelAddress + 3] = 255;
}

__global__ void ComputeState(Cell *pCurrentGrid, Cell *pNextGrid, size_t xSize, size_t ySize, float diffusionA, float diffusionB, float killRate, float feedRate, float dT) { 
	
	int x = blockIdx.x * blockDim.x + threadIdx.x;
	int y = blockIdx.y * blockDim.y + threadIdx.y;

	int cellAddress = y * xSize + x;

	Cell& prevState = pCurrentGrid[cellAddress];
	Cell& nextState = pNextGrid[cellAddress];

	nextState.a = reactionA(prevState.a, prevState.b, x, y, pCurrentGrid, killRate, feedRate, diffusionA, dT, xSize, ySize);
	nextState.b = reactionB(prevState.a, prevState.b, x, y, pCurrentGrid, killRate, feedRate, diffusionB, dT, xSize, ySize);
}

__global__ void setBValue(int xPos, int yPos, size_t xSize, Cell *pCurrentGrid) { 
	pCurrentGrid[yPos * xSize + xPos].b = 1;
}

void CudaSetSeed(int x, int y) {
	dim3 threadsPerBlock(cConfig.xThreads, cConfig.yThreads);
	dim3 numBlocks(xSize/threadsPerBlock.x, ySize/threadsPerBlock.y);

	setBValue<<<numBlocks, threadsPerBlock>>>(x, y, xSize, pCurrentGrid);
}

void CudaResetGrid() {
	cudaMemset(pCurrentGrid, 0, xSize * ySize * sizeof(Cell));
	cudaMemset(pNextGrid, 0, xSize * ySize * sizeof(Cell));
}

void CudaComputeField(sf::Uint8 *pResult) {

	dim3 threadsPerBlock(cConfig.xThreads, cConfig.yThreads);
	dim3 numBlocks(xSize/threadsPerBlock.x, ySize/threadsPerBlock.y);

	ComputeState<<<numBlocks, threadsPerBlock>>>(pCurrentGrid, pNextGrid, xSize, ySize, diffusionA, diffusionB, killRate, feedRate, dT);

	std::swap(pCurrentGrid, pNextGrid);

	setColor<<<numBlocks, threadsPerBlock>>>(pPixelField, pCurrentGrid, xSize);

	//cudaDeviceSynchronize();
	cudaMemcpy(pResult, pPixelField, ySize * xSize * sizeof(sf::Uint8) * 4, cudaMemcpyDeviceToHost);

	cudaError_t err = cudaGetLastError();
	if (err != cudaSuccess)
		std::cerr << cudaGetErrorName(err) << std::endl;
}

