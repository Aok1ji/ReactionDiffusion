#include "Window.hpp"

const int WIDTH = 1280;
const int HEIGHT = 720;
const float scale  = 1.0f;
const char* title = "ReactionDiffusion";

int main() { 
	
	Window app(WIDTH, HEIGHT, scale, title);

	return app.run();
}
