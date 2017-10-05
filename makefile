CPP = g++
CPPFLAGS = -I/usr/include/SDL2 -g
LDLIBS = -lSDL2 -lGLEW -lGL

NVCC = /usr/local/cuda-8.0/bin/nvcc
NVFLAGS = --compile --relocatable-device-code=false -gencode arch=compute_50,code=compute_50 -gencode arch=compute_50,code=sm_50  -x cu


controller : cuda.o controller.o
	$(NVCC) -o controller cuda.o controller.o $(LDLIBS)

controller.o : src/controller.cpp
	$(CPP) $(CPPFLAGS) -c src/controller.cpp $(LDLIBS)


cuda.o : src/cuda.cu src/cuda.h
	$(NVCC) $(NVFLAGS) src/cuda.cu

clean :
	rm -f *.o controller



