# game-of-life-cuda
Game of Life in CUDA, displayed using C++ and OpenGL.

## Dependencias
* GL/glew.h
* SDL.h
* CUDA

### Instalar dependencias (Linux)
Si tira errores al compilar:

**Instalar librerías**
```
// GLEW, SDL2 (+SDL2_Image)

sudo apt-get install libglew-dev libsdl2-dev libsdl2-image-dev  # Debian, Ubuntu
sudo dnf install glew-devel SDL2-devel SDL2_image-devel # fedora
sudo pacman -S glew sdl2 sdl2_image # arch
```


**Asegurar tener compilador**:
```
sudo apt-get install build-essential libgl1-mesa-dev  # Debian, Ubuntu
sudo dnf install make gcc-c++  # Fedora
```

Para instalar CUDA debes instalar el toolkit; para ello aplica Google.

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
Al precionar ```CTRL+C``` la aplicación terinará y mostrará estadísticas de cantidad de celulas evaluadas por segundo, y más.

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
