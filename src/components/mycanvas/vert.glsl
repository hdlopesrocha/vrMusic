#version 300 es
precision highp float;

in vec4 aVertexPosition;
in vec3 aVertexNormal;
in vec2 aTextureCoordinates;

uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;
uniform mat4 uModelMatrix;

out vec3 vNormal;
out vec2 vTextureCoordinates;

void main(void) {
    mat4 mvp = uProjectionMatrix * uViewMatrix * uModelMatrix;
  gl_Position = mvp *aVertexPosition;
  vNormal = aVertexNormal;
  vTextureCoordinates = aTextureCoordinates;
}