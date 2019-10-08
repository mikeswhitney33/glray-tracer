CC=g++
L=-Ldeps/lib -lglad -lglfw3 -ldl -lX11 -lpthread
I=-Ideps/include
GO=deps/src/glad.c

main:
	@$(CC) src/main.cpp $(I) $(L) -o bin/ray-tracer

clean:
	@rm -rf bin/ray-tracer