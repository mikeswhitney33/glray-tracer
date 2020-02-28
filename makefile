ifeq ($(OS),Windows_NT)
	OSFLAG =windows
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OSTYPE =linux
	endif
	ifeq ($(UNAME_S),Darwin)
		OSTYPE =osx
	endif
endif


CPP = g++
CPP_FLAGS = -std=c++17 -Ideps/include
CPP_LD_FLAGS = -Ldeps/lib -lglad -lglfw3
ifeq ($(OSTYPE), linux)
	CPP_LD_FLAGS += -ldl -lX11 -lpthread
endif
ifeq ($(OSTYPE), osx)
	FRAMEWORKS = -framework Cocoa -framework IOKit
endif
BINARY_DIR = bin
SOURCE_DIR = src

main: deps $(SOURCE_DIR)/main.cpp $(SOURCE_DIR)/camera.cpp $(SOURCE_DIR)/shader.cpp
	@mkdir -p bin
	$(CPP) $(CPP_FLAGS) -o $(BINARY_DIR)/glray-tracer $(SOURCE_DIR)/main.cpp $(SOURCE_DIR)/camera.cpp $(SOURCE_DIR)/shader.cpp $(CPP_LD_FLAGS) $(FRAMEWORKS)
.PHONY: main

deps:
	@mkdir -p deps/include
	@mkdir -p deps/lib
	@mkdir -p glfw/build
	@mkdir -p glad/build
	@cd glfw/build && cmake .. && make
	@cd glad/build && cmake .. && make
	@cp glfw/build/src/libglfw3.a deps/lib/
	@cp -r glfw/include/GLFW deps/include/
	@cp -r glm/glm deps/include/
	@cp glad/build/libglad.a deps/lib/
	@cp -r glad/build/include/glad deps/include/
	@cp -r glad/build/include/KHR deps/include/

clean:
	rm -rf deps
	rm bin/*
.PHONY: clean

test: main
	./bin/glray-tracer
