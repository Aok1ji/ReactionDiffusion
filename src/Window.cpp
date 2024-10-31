#include "Window.hpp"

#include <SFML/Config.hpp>
#include <SFML/Graphics/Color.hpp>
#include <SFML/Window/Event.hpp>
#include <SFML/Window/Keyboard.hpp>
#include <SFML/Window/VideoMode.hpp>


Window::Window(size_t width, size_t height, float scale, const char* title) :   mWindow(sf::VideoMode(width, height), title),
																				mpPixelBuffer(new sf::Uint8[width * height * 4]),
																				mRenderer(width, height)
{ 
	mWindow.setMouseCursorVisible(true);
	mWindow.setVerticalSyncEnabled(true);
	mWindow.pollEvent(mEvent);

	mSprite.setScale({scale, scale});
	mTexture.create(width, height);
	mRenderer.InitCuda();	
}


int Window::run() { 
	while(mWindow.isOpen()) {
		
		mWindow.clear(sf::Color::White);
		
		eventHandler();

		if(!mIsPaused) {
			mRenderer.render(mpPixelBuffer.get());
			mTexture.update(mpPixelBuffer.get());
			mSprite.setTexture(mTexture);
		}
																
		mWindow.draw(mSprite);
		mWindow.display();
	}	
	mRenderer.FreeCuda();
	return 0;
}


inline void Window::eventHandler() { 
	while(mWindow.pollEvent(mEvent)) {
		switch (mEvent.type) {
			case sf::Event::EventType::Closed :
				mWindow.close();
				break;
			case sf::Event::LostFocus : 
				mIsPaused = true;
				break;
			case sf::Event::GainedFocus : 
				mIsPaused = false;
				break;
			case sf::Event::MouseButtonPressed :
				if(mEvent.mouseButton.button == sf::Mouse::Button::Left) {
					mRenderer.setSeed(mEvent.mouseButton.x, mEvent.mouseButton.y);	
				}
				break;
			
			case sf::Event::KeyPressed:
				kbEventHandler();
				break;
		}
	}	
}

inline void Window::kbEventHandler() { 
	switch (mEvent.key.code) {
		case sf::Keyboard::Escape :
			mWindow.close();
			break;
		case sf::Keyboard::R :
			mRenderer.resetGrid();
			break;
	}
}
