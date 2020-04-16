#version 300 es
precision highp float;
precision highp int;

in vec4 aVertexPosition;
in vec3 aVertexNormal;
in vec2 aTextureCoordinates;

uniform int uDrawMode;
uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;
uniform mat4 uModelMatrix;
uniform float uTime;

out vec4 vColor;
out vec3 vNormal;
out vec2 vTextureCoordinates;

//#PERLIN

void main(void) {
    mat4 mvp = uProjectionMatrix * uViewMatrix * uModelMatrix;
    vec4 position = aVertexPosition;

    if(uDrawMode == 2) {
        float cx = aTextureCoordinates.x;
        float cy = cos(aTextureCoordinates.y*PI);
        float cz = uTime*0.1;

        float nx = noise(vec4(cx,cy,cz, 0.0));
        float ny = noise(vec4(0.0, cx,cy,cz));
        float nz = noise(vec4(cx,cy, 0.0, cz));

        vColor = vec4(nx,ny,nz, 0.0);
       // position.x += nx;
       // position.z += nz;
    }

  gl_Position = mvp *position;
  vNormal = aVertexNormal;
  vTextureCoordinates = aTextureCoordinates;

}