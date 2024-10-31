cmake_minimum_required(VERSION 3.24.0)
project("ReactionDiffusion" VERSION 0.1 LANGUAGES CXX CUDA)
enable_language(CUDA)

set(CMAKE_MODULE_PATH cmake)

message(STATUS "Compiler: " ${CMAKE_CXX_COMPILER_ID})

file(GLOB_RECURSE sources src/*.cpp src/shaders/*.cpp src/shaders/*.cu)

add_executable("${PROJECT_NAME}" "${sources}")

find_package(SFML COMPONENTS graphics audio window system REQUIRED)

if(SFML_FOUND)
	include_directories(${SFML_INCLUDE_DIR})
	
	target_link_libraries("${PROJECT_NAME}"  PRIVATE sfml-graphics sfml-audio sfml-window sfml-system)
endif()

set(CMAKE_CXX_STANDARD 17)

if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug" OR NOT CMAKE_BUILD_TYPE STREQUAL "Release")
	set(CMAKE_BUILD_TYPE Debug CACHE STRING "Choose the type of build." FORCE)
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -Wall -W")
	set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_PROJECT_DIR}/build/debug")
elseif(CMAKE_CXX_FLAGS STREQUAL "Release")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -01 -DNDEBUG")
	set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_PROJECT_DIR}/build/release")
endif()

