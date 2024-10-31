#pragma once

#include <SFML/Config.hpp>
#include <stddef.h>

class Shader {
private:
	int mWidth, 
		mHeight;

public:
	Shader(int width, int height);

	void InitCuda();
	void FreeCuda();

	void render(sf::Uint8 *pDest);
	void setSeed(int x, int y);
	void resetGrid();
};
