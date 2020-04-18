#version 300 es
precision highp float;
precision highp int;

uniform int uDrawMode;
uniform sampler2D uSampler0;
uniform sampler2D uSampler1;

uniform bool uEnableLight;
uniform float uTime;
uniform vec3 uLightDirection;
uniform vec3 uCameraPosition;

in vec3 vNormal;
in vec2 vTextureCoordinates;
in vec4 vColor;
in vec4 vPosition;

out vec4 fragColor;

//#COMMON
//#PERLIN

void main(void) {
  vec4 color = vec4(1.0, 1.0, 1.0, 1.0);
  vec2 textureCoordinates = vTextureCoordinates;


  if(uDrawMode == DRAW_MODE_WHITE) {
    fragColor = color;
    return;
  }
  if(uDrawMode == DRAW_MODE_2D || uDrawMode == DRAW_MODE_2D_MIX) {
    textureCoordinates.y = 1.0 - vTextureCoordinates.y;
  }

  vec3 normal = normalize(vNormal);

  if(uDrawMode == 1){
    float n = noise(vec4(textureCoordinates, 0.0, uTime*0.1));
    vec2 p = 2.0*textureCoordinates - vec2(1.0, 1.0);
    float pd = clamp(length(p), 0.0, 1.0);
    float pr = 1.0 - pd*pd*pd;

    float pc = clamp(pr*n+pr*0.25, 0.0, 1.0);
    color = vec4(1.0, pc*2.0, 0.0,pc);
  } else if(uDrawMode == DRAW_MODE_CYLINDER) {
    vec4 c = texture(uSampler0, textureCoordinates);
    color = clamp(c+vec4(vColor.xyz, 0.0), 0.0, 1.0);
  } else if(uDrawMode == DRAW_MODE_2D_MIX) {
    vec4 maskColor = texture(uSampler1, textureCoordinates);
    if(maskColor.w > 0.0) {
      vec4 sum = vec4(0.0);
      float delta = 0.005;
      int count = 0;
      int size = 3;
      for(int i=-size; i <= size; ++i) {
        for(int j=-size; j <= size; ++j) {

          sum += texture(uSampler0, textureCoordinates+delta*vec2(i,j));
          ++count;
        }
      }
      color = (sum / float(count)) * maskColor;
      color.w = 1.0;
     // color = vec4(1.0, 0.0, 0.0, 1.0);
    } else {
      color.w = 0.0;
    }

    //color.x = 0.5;
  } else {
    color = texture(uSampler0, textureCoordinates);
  }

  if(uEnableLight) {
    float dotFactor = dot(normal, -uLightDirection);
    fragColor = color*vec4(dotFactor,dotFactor,dotFactor,1.0);
  } else {
    fragColor = color;
  }

  if(uDrawMode == DRAW_MODE_EDGES) {

    vec3 vertexToCam = normalize(vPosition.xyz-uCameraPosition);
    float edgeDot = abs(dot(vertexToCam, normal));
    if(edgeDot < 0.2) {
      float minColor = 0.5;
      vec3 c = vColor.xyz*8.0 + minColor;

      fragColor.xyz = clamp(c, minColor, 1.0);
      fragColor.w = 1.0;
    } else {
      float l = 1.0-length(fragColor.xyz);
      fragColor.w = (1.0 - l*l*l)*0.1;
    }
  }
  if (uDrawMode == DRAW_MODE_SKY) {
    float gradient = 150.0;
    fragColor.xyz += vColor.xyz*clamp(1.0 - abs(vPosition.y)/gradient, 0.0, 0.5);
  }

  if (uDrawMode == DRAW_MODE_BILLBOARD) {
    fragColor.xyz += vColor.xyz;
  }
}