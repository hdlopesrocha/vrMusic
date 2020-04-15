precision mediump float;
varying vec3 vNormal;
varying vec2 vTextureCoordinates;
uniform sampler2D uSampler;

uniform bool uEnableLight;

void main(void) {
  vec3 lightDirection = vec3(0.0, 0.0, 1.0);
  if(uEnableLight) {
    float dotFactor = dot(vNormal, lightDirection);
    gl_FragColor = texture2D(uSampler, vTextureCoordinates)*vec4(dotFactor,dotFactor,dotFactor,1.0);
  } else {
    gl_FragColor = texture2D(uSampler, vTextureCoordinates);
  }

}