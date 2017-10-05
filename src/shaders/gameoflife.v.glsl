attribute vec2 coord2d; 
attribute vec3 color; 

varying out vec3 ourColor; // output a color to the fragment shader

void main(void) {                        
  gl_Position = vec4(coord2d, 0.0, 1.0);
  ourColor = color;
};
