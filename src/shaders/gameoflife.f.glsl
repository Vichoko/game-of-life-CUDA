#version 120

varying vec3 ourColor;

void main(void) {        
  gl_FragColor[0] = ourColor.x;
  gl_FragColor[1] = ourColor.y;
  gl_FragColor[2] = ourColor.z; 
};
