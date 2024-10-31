#include "Shader.hpp"

void CudaInit(size_t width, size_t height);
void CudaExit();
void CudaComputeField(sf::Uint8 *pResult);
void CudaSetSeed(int x, int y);
void CudaResetGrid();

Shader::Shader(int width, int height) :  mWidth(width),
										 mHeight(height)
{ 

}

void Shader::InitCuda() {
	CudaInit(mWidth, mHeight);
}

void Shader::FreeCuda() { 
	CudaExit();
}

void Shader::render(sf::Uint8 *pDest) { 
	CudaComputeField(pDest);
}

void Shader::setSeed(int x, int y) { 
	CudaSetSeed(x, y);
}

void Shader::resetGrid() {
	CudaResetGrid();
}
