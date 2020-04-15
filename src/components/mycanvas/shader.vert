precision mediump float;
attribute vec4 aVertexPosition;
attribute vec3 aVertexNormal;
attribute vec2 aTextureCoordinates;

uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;
uniform mat4 uModelMatrix;

varying vec3 vNormal;
varying vec2 vTextureCoordinates;

void main(void) {
    mat4 mvp = uProjectionMatrix * uViewMatrix * uModelMatrix;
  gl_Position = mvp *aVertexPosition;
  gl_PointSize = 10.0;
  vNormal = aVertexNormal;
  vTextureCoordinates = aTextureCoordinates;
}