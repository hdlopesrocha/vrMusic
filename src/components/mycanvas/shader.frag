precision mediump float;
varying vec3 vNormal;
varying vec2 vTextureCoordinates;

void main(void) {
  vec3 lightDirection = vec3(0.0, 0.0, 1.0);

  float dotFactor = dot(vNormal, lightDirection);

  gl_FragColor = vec4(vec3(dotFactor)+vNormal,1.0);
}