#version 300 es
precision highp float;
precision highp int;

uniform int uDrawMode;
uniform sampler2D uSampler;
uniform bool uEnableLight;
uniform float uTime;

in vec3 vNormal;
in vec2 vTextureCoordinates;
in vec4 vColor;

out vec4 fragColor;

//#PERLIN

void main(void) {
  vec4 color = vec4(0.0, 0.0, 0.0, 0.0);
  if(uDrawMode == 0) {
    color = texture(uSampler, vTextureCoordinates);
  } else if(uDrawMode == 1){
    float n = noise(vec4(vTextureCoordinates.x, vTextureCoordinates.y, 0.0, uTime*0.1));
    float px = 2.0*vTextureCoordinates.x - 1.0;
    float py = 2.0*vTextureCoordinates.y - 1.0;
    float pd = clamp(sqrt(px*px+py*py), 0.0, 1.0);
    float pr = 1.0 - pd*pd*pd;

    float pc = clamp(pr*n+pr*0.25, 0.0, 1.0);
    color = vec4(1.0, pc*2.0, 0.0,pc);
  } else if(uDrawMode == 2) {
    float nx = vColor.x;
    float ny = vColor.y;
    float nz = vColor.z;

    vec4 c = texture(uSampler, vTextureCoordinates);

    color = clamp(c+vec4(nx,ny,nz, 0.0), 0.0, 1.0);
  }

  if(uEnableLight) {
    vec3 lightDirection = vec3(0.0, 0.0, 1.0);
    float dotFactor = dot(vNormal, lightDirection);
    fragColor = color*vec4(dotFactor,dotFactor,dotFactor,1.0);
  } else {
    fragColor = color;
  }

}