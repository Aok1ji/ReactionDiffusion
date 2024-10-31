#pragma once

#include <SFML/Config.hpp>
#include <SFML/Graphics.hpp>
#include <SFML/Graphics/RenderWindow.hpp>
#include <SFML/Graphics/Sprite.hpp>
#include <SFML/Graphics/Texture.hpp>
#include <SFML/Window/Event.hpp>
#include <memory>

#include "shaders/Shader.hpp"

class Window {
private:
	sf::RenderWindow mWindow;
	sf::Event mEvent;
	
	sf::Texture mTexture;
	sf::Sprite	mSprite;
	
	std::unique_ptr<sf::Uint8> mpPixelBuffer;

	bool mIsPaused = false;
	Shader mRenderer;
public:
	Window(size_t width, size_t height, float scale, const char* title);
	
	int run();

private:
	
	inline void eventHandler();
	inline void kbEventHandler();
};
