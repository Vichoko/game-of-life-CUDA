# game-of-life-cuda
Game of Life in CUDA, displayed using C++ and OpenGL.

## Dependencias
* GL/glew.h
* SDL.h
* CUDA

## Compilación
```
$ make
```

Limpiar con;
```
$ make clean
```

### Configurar makefile
Si tienes problemas con los include, hay que configurar:
* CUDA Compiler: Ingresar directorio de NVCC en makefile:5 (Ej. /usr/local/cuda-8.0/bin/nvcc)
* SDL: Ingresar directorio de SDL en makefile:2 (Ej. /usr/include/SDL2)

## Ejecución
```
$ ./controller
```

## Customización
Se pueden modificar constantes en "src/globals.h".
### Resolución de vidas
Se pueden variar la cantidad de columnas (```COLUMNS```) y filas (```ROWS```).
### Cantidad inicial de vidas
Se puede variar el porcentaje de casillas inicial con vidas (```INITIAL_LIVES_FRACTION```).
### Frame rate
Se puede variar la cantidad de fotogramas por segundo máxima (```FRAMERATE```).
### Resolución de ventana
Se pueden variar la cantidad de pixeles (```WIDTH``` y ```HEIGHT```).
