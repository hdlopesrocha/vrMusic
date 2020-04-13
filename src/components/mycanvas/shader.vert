attribute vec4 aVertexPosition;
attribute vec3 aVertexNormal;

uniform mat4 uModelViewMatrix;
uniform mat4 uProjectionMatrix;

varying lowp vec4 vColor;

void main(void) {
    vec3 lightDirection = vec3(0.0, 0.0, 1.0);

  gl_Position = uProjectionMatrix * uModelViewMatrix * aVertexPosition;
  gl_PointSize = 10.0;

    float dotFactor = dot(aVertexNormal, lightDirection);
  vColor = vec4(vec3(dotFactor),1.0);
}