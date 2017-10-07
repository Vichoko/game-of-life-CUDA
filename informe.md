# Juego de la vida: Secuencial vs Paralelo
* Fecha: Octubre, 2017.
* Autor: Vicente Oyanedel M.
* Profesora: Nancy Hitschfeld K.
* Ayudante: Sebastián González M.

## Introducción
### Descripción del Problema
Con la motivación de comparar el rendimiento (En particular, ‘Speed up’) en la ejecución de programas en GPU (programación paralela) y CPU (programación secuencial); se desarrolla el autómata celular conocido como **Juego de la Vida** (variante ‘High Life’) en 3 implementaciones:

* Secuencial en CPU usando C y OpenGL.
* Paralelo en GPU usando CUDA, C y OpenGL.
* Paralelo en GPU usando OpenCL, C y OpenGL.

### Resultados esperados
El juego de la vida implementado, se ejecuta fundamentalmente iterando en un "loop" en el que:

1. Se calculan las celdas vivas y muertas de siguiente iteración.
2. Se procesan y muestran las celdas vivas (blanco) y muertas (negro) en pantalla.

El cuello de botella interesante para el problema es el proceso explicado en el punto 1; calcular las celdas vivas y muertas de la siguiente iteración. 

La versión secuencial lo implementa mediante un doble "for" (iterar sobre columnas y filas de "matriz de vidas"). Sin embargo, las versiones paralelas eliminan la necesidad de este doble "for", paralelizando esta tarea en particular. Ésto por que el problema de verificar si una celda esta viva o muerta en la siguiente iteración es un problema **"data-parallel"**. 

Por lo tanto se ejecutan los kernels en ```COLUMNS*ROWS``` threads, ***paralelizando sobre cada celda para evaluar su condición de vida en la siguiente iteración***. Esto se hace calculando la cantidad de vecinos vivos (mediante "if"s); luego, calculando la condición de vida (mediante "if"s también); y finalmente, marcar en el arreglo de vida de la siguiente iteración un 1 o 0, dependiendo si vive o muere. 

Por ésto, se espera que la cantidad de celdas verificadas por segundo en la parte 1 (i.e. Calcular celdas vivas y muertas de siguiente iteración), aumente en la versión paralela, en comparación con la versión secuencial.

## Implementación
La 3 implementaciones se hicieron el proyectos separados, cada uno se debe compilar y ejecutar individualmente:

- game-of-life-CPU: https://github.com/Vichoko/game-of-life-cpu
- game-of-life-CUDA: https://github.com/Vichoko/game-of-life-CUDA
- game-of-life-OpenCL: https://github.com/Vichoko/game-of-life-OpenCl

Cada una tiene un ```README.md``` con la explicación de las dependencias necesarias, compilación, ejecución y obtención de estadísticas de rendimiento. 

Se intentó que todas las implementaciones tuvieran una interfaz de funciones similar; por lo que varios puntos de las implementaciones son parecidos. Además las funcionalidades están distribuidas de la misma manera en las tres.

Todas las implementaciones tienen un archivo **"globals.h"** que contiene las constantes del juego que se pueden modificar:

* ROWS
* COLUMNS
* INITIAL_LIVES_FRACTION

Entre otras. Todas en mayúsculas.

Todas las implementaciones tienen una separación abstracta:

* Controlador: Inicia opengl, dibuja en pantalla, ejecuta main loop, llama funciones de la lógica del juego para cambiar su estado.
* Lógica del juego: Provee API para que controlador pueda iniciar datos del juego, actualizar información (en el main loop) y finalizar el juego.

La separación de estos módulos en los distintos archivos de código varía levemente entre implementaciones, por dificultades de compilación.

### Implementación secuencial (CPU)
Se puede separar en 3 partes fundamentales:


1. Iniciación.
2. Main loop.
3. Finalización (limpieza de buffers; sin importancia para el análisis).

Además, hay **variables globales** que son de importancia para el juego:


1. ```int livesArrayActual[ROWS*COLUMNS]```: Arreglo un-dimensional, con valores 0 y 1, que codifica las células vivas y muertas de iteración actual.
1. ```int livesArrayNext[ROWS*COLUMNS]```: Ídem, pero para iteración siguiente (loop de juego modifica estas en base a livesArrayActual; luego se hace "swap" de referencias).


#### Iniciación
1. Se cambia comportamiento de SIGINT (Ctrl + C) para que cuando llegue, muestre las métricas necesarias para los experimentos (Ej. Cantidad de celdas evaluadas por segundo).
2. Se inician los datos de juego (```int* init_game_data()```)
	1. Se asignan arreglos globales (con ```malloc```).
	2. se generan vidas en ```INITIAL_LIVES_FRACTION``` casillas aleatorias (```int* generateInitialLives()```).
3. Se inicia ventana y recursos gráficos (sin importancia para el análisis).

### Main loop
1. Renderizar vidas contenidas en arreglo binario ```int* livesArrayActual```.
2. **Evaluar nuevas vidas (aquí está el doble "for" y cuello de botella)** en base a ```int*  livesArrayActual``` y dejándolas en ```int* livesArrayNext``` 
3. Intercambio (swap) de referencias ```int* livesArrayActual``` y ```int* livesArrayNext```, para siguiente iteración.
4. Actualizar mediciones.


### Implementación paralela en CUDA
Tiene 2 archivos:

* controller.cpp: Inicia recursos, ejecuta main loop, muestra en pantalla y libera recursos.
* cuda.cu: Provee lógica del juego.

#### controller.cpp

Requiere **variables globales** que son de importancia para el juego:

* ```int* livesArray```: Arreglo un-dimensional, con valores 0 y 1, que codifica las células vivas y muertas de iteración actual.
* ```container_t* vertex_n_colors```: Struct que contiene arreglo con vértices y colores para dibujar con OpenGL.

Como se mencionó brevemente, la arquitectura de control en estas versiones es la siguiente:


1. ```controller.cpp```: Ejecuta función main que:
    1. Captura CTRL + C para mostrar métricas.
	2. Inicia OpenGL y recursos.
	3. Inicia recursos y datos del juego (*).
	4. Main Loop de la aplicación.
		1. Renderiza vidas contenidas en ```int* livesArray```.
		2. Llama a kernel (*).
		3. Recibe datos de GPU a "Host (*)".
		4. Actualiza métricas.
	5. Libera recursos de CUDA (*).
	6. Libera resto de los recursos.


Lo que aparece con (*) se hace mediante llamadas a la API que provee el archivo ```cuda.h```, funciones implementadas en ```cuda.cu```.

#### cuda.cu

En este archivo está implementada la lógica del juego: 

* Inicialización.
* Actualización de vidas paralela.
* Limpieza de recursos.

Funciones provistas mediante una API suficiente para que el controlador pueda ejecutar el juego correctamente:
```
int* init_game_data(); // se llama al comienzo; devuelve puntero a arreglo de vidas inicial
float kernel_wrapper(); // llamado cada 'frame'; retorna tiempo en segundos 
int* fetch_gpu_data(); // llamado cada 'frame'; retorna puntero a arreglo de vidas actualizado
void free_cuda_resources(); // call at end
```

Para ello requiere las **variables globales**:
```
// host
int* livesArrayActual; // arreglo con células vivas (1) y muertas (0).
int N; // tamaño del problema = COULUMNS * ROWS
int size; // tamaño de arreglo de vidas = Sizeof(int) * N
// device
int* d_livesArrayActual; // puntero a memoria de GPU con vidas actuales.
int* d_livesArrayNext; // puntero a memoria de GPU con vidas siguientes.
```

2. ```cuda.cu```: Provee API:
	1. ```int* init_game_data()```: 
		1. Asigna variables del juego en 'Host'.
		2. Asigna variables del juego en GPU.
		3. Genera vidas en ```INITIAL_LIVES_FRACTION``` casillas aleatorias (```int* generateInitialLives```).
		4. Copia vidas iniciales de 'Host' a GPU.
		5. Retorna puntero a arreglo con celdas vivas (1) y muertas(0) en "Host" ```int* livesArrayActual```.
	2. ```float kernel_wrapper()```:
		1. Ejecuta kernel ```refreshLife``` (de manera bloqueante): Se ejecuta sobre cada celda: Se lanzan COLUMNS*ROWS threads en varios bloques (depende de global ```THREADS_PER_BLOCK```).
			1. Se calculan cantidad de vecinos vivos. Esto se hace mediante una iteración de 8 pasos y utilizando "if"s (```countAliveNeighbors```).
			2. Se decide si celda estará viva en siguiente iteración o no, mediante "if"s. 
		2. Retorna segundos que tardan en completar todos los threads en kernel.
	3. ```int* fetch_gpu_data()```: Trae a 'Host' nuevas vidas calculadas en GPU y hace swap de referencias en GPU.
		1. Copia resultado de kernel ```int* d_livesArrayNext``` a ```int* livesArrayActual```.
		2. Hace swap de referencias ```int* d_livesArrayNext``` con ```int* d_livesArrayActual```; para siguiente iteración.
	4. ```void free_cuda_resources()```: Limpia espacios asignados, etc.


Las llamadas a ```kernel_wrapper()``` y ```fetch_gpu_data()``` son de especial importancia porque se llaman en cada frame del juego, es decir, en cada iteración del MainLoop en ```controller.cpp```; y representan el cuello de botella que se quiere optimizar (doble 'for' de versión secuencial).

### Implementación paralela en OpenCL

Dado el buen funcionamiento de esta arquitectura ```controlador - API - lógica del juego``` en CUDA, se replica en la implementación usando OpenCL.

Cabe destacar que para esta implementación se codificó todo en un mismo archivo "controller.cpp", dado que tenía problemas para compilar. Sin embargo, la separación modular expuesta se mantiene de igual manera.

El controlador mantiene la misma implementación que la descrita en la parte anterior; pero por consistencia se repite a continuación.

#### controller

En el archivo ```controller.cpp```:

Requiere **variables globales** que son de importancia para el juego:
* ```int* livesArray```: Arreglo un-dimensional, con valores 0 y 1, que codifica las células vivas y muertas de iteración actual.
* ```container_t* vertex_n_colors```: Struct que contiene arreglo con vértices y colores para dibujar con OpenGL.

Como se mencionó brevemente, la arquitectura de control en estas versiones es la siguiente:


1. ```controller.cpp```: Ejecuta función main que:
	1. Captura CTRL + C para mostrar métricas.
	2. Inicia OpenGL y recursos.
	3. Inicia recursos y datos del juego (*).
	4. Main Loop de la aplicación.
		1. Renderiza ```livesArray```.
		2. Llama a kernel (*).
		3. Recibe datos de GPU a "Host (*)".
		4. Actualiza métricas.
	5. Libera recursos de OpenCL (*).
	6. Libera recursos.


Lo que aparece con (*) se hace mediante llamadas a la API que provee el archivo ```game_logic.h```, funciones implementadas en ```controller.cpp``` (por problemas del compilación, tuve que implementarlas en este archivo).


#### game logic

La lógica del juego: 

* Inicialización.
* Actualización de vidas paralela.
* Limpieza de recursos.

Funcionalidad implementada mediante la API de ```game_logic.h```:
```
int* init_game_data(); // se llama al comienzo; devuelve puntero a arreglo de vidas inicial
float kernel_wrapper(); // llamado cada 'frame'; retorna tiempo en segundos 
int* fetch_gpu_data(); // llamado cada 'frame'; retorna puntero a arreglo de vidas actualizado
void free_opencl_resources(); // call at end
```

Ahora, la API se describe acorde a las especificaciones de OpenCL:

1. ```int* init_game_data()```: 
	1. Asigna variables del juego en 'Host' (con ```malloc```).
	2. Genera vidas en ```INITIAL_LIVES_FRACTION``` casillas aleatorias (```int* generateInitialLives```).
	3. Inicia recursos de OpenCL.
		1. Inicia programa.
		2. Compila kernel ```__kernel void refresh_life(int* d_livesArrayActual, int* d_livesArrayNext, int* rows,  int* columns)``` (en ```kernel.cl```).
		3. Asigna variables del juego en GPU.
		4. Copia variables iniciales de 'Host' a GPU.
		5. Asigna argumentos para la inminente llamada al kernel.
	5. Retorna puntero a arreglo con celdas vivas (1) y muertas(0) en "Host".
2. ```float kernel_wrapper()```:
	1. Ejecuta kernel ```refresh_life``` (bloqueante): Se ejecuta sobre cada celda: Se lanzan COLUMNS*ROWS threads.
		1. Se calculan cantidad de vecinos vivos. Esto se hace mediante una iteración de 8 pasos y utilizando "if"s.
		2. Se decide si celda estará viva en siguiente iteración o no, mediante "if"s. 
	2. Retorna segundos que tarda en completar todos los threads en kernel.
3. ```int* fetch_gpu_data()```: Trae a "Host" nuevas vidas calculadas en GPU y hace swap de referencias en GPU.
	1. Copia resultado de kernel ```int* d_livesArrayNext``` a ```int* livesArrayActual``` (gpu->'host').
	2. Copia contenido de ```int* livesArrayActual``` a ```int* d_livesArrayActual``` ('host'->gpu), para siguiente iteración.
4. ```void free_opencl_resources()```: Limpia espacios asignados, etc.

### Variaciones en configuración
En el archivo ```globals.h``` se pueden configurar variaciones. Las disponibles son:
```
#define WIDTH 800 // ancho en pixeles de ventana
#define HEIGHT 800 // ancho en pixeles de ventana
#define ROWS 64 // alto en filas en grilla de celdas
#define COLUMNS 64 // ancho en columnas en grillas de celdas p
#define FRAMERATE 150 // fotogramas por segundo
#define INITIAL_LIVES_FRACTION 0.9 // fracción de celdas que iniciaran con vida
#define THREADS_PER_BLOCK 8 // cantidad de threads por unidad de trabajo (blocks o work-group)
```

## Resultados experimentales relevantes
Para los experimentos se limitó la forma de grilla a un cuadrado. 
Se varió la cantidad de filas y columnas, obteniendo la cantidad de celdas evaluadas por segundo para cada uno; luego de ejecutar cada implementación hasta que el juego de la vida convergiera a su final.

![Celdas evaluadas por segundo vs tamaño de grilla](https://i.imgur.com/RQdxXoP.png)

Al analizar los datos se verifica que el speedup aumenta con el tamaño de la grilla. Por limitaciones de la implementación no se logró medir para tamaños de grilla mayores a N=512*512. Por lo que el máximo speedup logrado es:```13.58x```

![Celdas evaluadas por segundo vs cantidad de filas](https://i.imgur.com/gDx34z7.png)

Por otro lado, al analizar los datos y la interpolación se puede ver que el speedup comienza a inclinarse para las implementaciones paralelas en GPU desde N=128*128 celdas. A la vez, se deja ver que la implementación en CUDA logra el mejor desempeño y crecimiento.

Cabe destacar que en éste ultimo gráfico, el eje x corresponde a la cantidad de filas y columnas por si solas. Es decir, para calcular el tamaño total de la grilla corresponde al cuadrado del valor de la columna.

## Análisis
Para tamaños de grilla pequeños, menores a N=10,000 celdas se evidencia un rendimiento mejor en CPU. A partir de N=16,384 comienza a ser conveniente usar GPU.

El desempeño con CUDA supera al desempeño con OpenCL en todos los contextos. Lo cual puede ser porque es posible que haya ejecutado el código OpenCl en mi CPU Intel. Sin embargo, la implementación en OpenCL supera la en CPU desde el umbral mencionado previamente.

Otra observación es que no se logró experimentar para tamaños de grilla más grandes, lo cual deja inconcluso si el speed up en CUDA puede seguir creciendo.

## Conclusiones
Si se tiene un problema paralelizable; llegar y usar GPU para resolverlo puede no ser una buena idea. En especial si el tamaño del problema es pequeño. 
Una decisión sabia recae en poder analizar el problema y evaluar si usar GPU puede lograr un ‘speed up’, con respecto a la decisión secuencial o incluso paralela pero en CPU.


Por otro lado, los resultados de la implementación en CUDA dejó bastante claro el poder de procesamiento de mi GPU. Por lo que si tuviera que resolver un gran problema paralelizable no duraría en preferir CUDA, frente a OpenCL.

## Fuentes
- Tutorial usado para aprender a dibujar con OpenGL: [https://en.wikibooks.org/wiki/OpenGL_Programming/Modern_OpenGL_Introduction]






























