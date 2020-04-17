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
in vec3 vLightDirection;
in vec3 vCameraPosition;
in vec4 vPosition;

out vec4 fragColor;

//#PERLIN

void main(void) {
  vec4 color = vec4(1.0, 1.0, 1.0, 1.0);
  vec3 normal = normalize(vNormal);

  if(uDrawMode == 0 || uDrawMode == 4) {
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

    vec4 c = texture(uSampler, vTextureCoordinates);
    color = clamp(c+vec4(vColor.xyz, 0.0), 0.0, 1.0);
  }

  if(uEnableLight) {
    float dotFactor = dot(normal, -vLightDirection);
    fragColor = color*vec4(dotFactor,dotFactor,dotFactor,1.0);
  } else {
    fragColor = color;
  }

  if(uDrawMode == 3) {

    vec3 vertexToCam = normalize(vCameraPosition-vPosition.xyz);
    float edgeDot = abs(dot(vertexToCam, normal));
    if(edgeDot < 0.3) {
      color = clamp(vec4(vColor.xyz, 0.0)*8.0, 0.5, 1.0);
      fragColor.xyz = color.xyz;
      fragColor.w = 1.0;
    } else {
      float l = 1.0-length(fragColor.xyz);
      fragColor.w = (1.0 - l*l*l)*0.2;
    }
  }
  if (uDrawMode == 4) {
    float gradient = 32.0;
    fragColor.xyz += vColor.xyz*clamp(1.0 - abs(vPosition.y)/gradient, 0.0, 0.5);
  }
}