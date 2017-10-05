#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <cstdlib>
#include <iostream>
/* Use glew.h instead of gl.h to get all the GL prototypes declared */
#include <GL/glew.h>
/* Using SDL2 for the base window and OpenGL context init */
#include <SDL.h>
#include <fstream>

#include "globals.h"
using namespace std;
typedef struct {
	float* array;
	int total_len;
	int vertex_len;
	} container_t;


extern char* file_read(const char* filename);
extern void print_log(GLuint object);
extern GLuint create_shader(const char* filename, GLenum type);





