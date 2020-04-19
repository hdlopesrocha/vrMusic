#version 300 es
precision highp float;
precision highp int;

uniform int uDrawMode;
uniform sampler2D uSampler[2];

uniform bool uEnableLight;
uniform float uTime;
uniform vec3 uLightDirection;
uniform vec3 uCameraPosition;
uniform vec2 uCanvasSize;

in vec3 vNormal;
in vec2 vTextureCoordinates;
in vec4 vColor;
in vec4 vPosition;

out vec4 fragColor;

//#COMMON
//#PERLIN
//#HSL2RGB

void main(void) {
    vec4 color = vec4(1.0, 1.0, 1.0, 1.0);
    vec2 textureCoordinates = vTextureCoordinates;

    if (uDrawMode == DRAW_MODE_2D_MIX) {
        vec4 maskColor = texture(uSampler[1], textureCoordinates);
        if (maskColor.w > 0.0) {
            vec4 sum = vec4(0.0);
            vec2 delta = 1.0/uCanvasSize;
            int count = 0;
            int size = 8;
            for (int i=-size; i <= size; ++i) {
                for (int j=-size; j <= size; ++j) {
                    sum += texture(uSampler[0], textureCoordinates+delta*vec2(i, j));
                    ++count;
                }
            }
            color = (sum / float(count)) + maskColor * 0.5+0.1;
            color.w = 1.0;
        } else {
            color.w = 0.0;
        }
        fragColor = color;
        return;
    } else if (uDrawMode == DRAW_MODE_TORUS) {
        color = vColor;
    } else {
        color = texture(uSampler[0], textureCoordinates)*vColor;
    }

    vec3 normal = normalize(vNormal);
    if (uEnableLight) {
        float dotFactor = dot(normal, -uLightDirection);
        fragColor = color*vec4(dotFactor, dotFactor, dotFactor, 1.0);
    } else {
        fragColor = color;
    }

    if (uDrawMode == DRAW_MODE_MASK || uDrawMode == DRAW_MODE_EDGES) {
        vec3 vertexToCam = normalize(vPosition.xyz-uCameraPosition);
        float edgeDot = abs(dot(vertexToCam, normal));
        float edgeFactor = 0.3;
        if (uDrawMode == DRAW_MODE_EDGES) {
            fragColor = edgeDot < edgeFactor ? vColor: vec4(0.0);
        }else {
            fragColor = edgeDot < edgeFactor ? vec4(0.0) : fragColor;
        }
    }

    if (uDrawMode == DRAW_MODE_SKY || uDrawMode == DRAW_MODE_BILLBOARD || uDrawMode == DRAW_MODE_MANDALA) {
        fragColor.xyz *= vColor.xyz;
    }
}