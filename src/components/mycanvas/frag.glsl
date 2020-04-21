#version 300 es
precision highp float;
precision highp int;

uniform int uDrawMode;
uniform sampler2D uSampler[2];
uniform sampler2D uAudioSampler;
uniform float uEffectAmount;

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

vec4 alphaBlend(vec4 color){
    return vec4(color.x * color.w, color.y * color.w, color.z * color.w, color.w);
}

vec3 calcPosition(vec2 pos, float t) {
    float height = noise(vec3(pos, t));
    return vec3(pos, height);
}

void main(void) {
    vec4 color = vec4(1.0, 1.0, 1.0, 1.0);
    vec2 textureCoordinates = vTextureCoordinates;
    bool skipEffect = false;

    if (uDrawMode == DRAW_MODE_2D_BLUR) {
        vec4 maskColor = texture(uSampler[1], textureCoordinates);
        if (maskColor.x > 0.0) {
            vec4 sum = vec4(0.0);
            vec2 delta = 1.0/uCanvasSize;
            int count = 0;
            int size = 4;
            for (int i=-size; i <= size; ++i) {
                for (int j=-size; j <= size; ++j) {
                    sum += texture(uSampler[0], textureCoordinates+delta*vec2(i, j));
                    ++count;
                }
            }
            color = (sum / float(count))*uEffectAmount+(1.0 - uEffectAmount)*texture(uSampler[0], textureCoordinates);
            skipEffect=true;
        } else {
            color.w = 0.0;
        }
        fragColor = alphaBlend(color);
        return;
    } else if (uDrawMode == DRAW_MODE_TORUS) {
        color = vColor;
    } else if (uDrawMode == DRAW_MODE_EDGES) {
        color = texture(uSampler[0], textureCoordinates);
    } else if(uDrawMode == DRAW_MODE_2D_NORMAL_MAP){
        float textureNoiseVelocity = 1.0;
        float textureNoiseFrequency = 256.0;
        float d = 1.0/uCanvasSize.y;

        vec3 p = calcPosition(textureNoiseFrequency*textureCoordinates, uTime*textureNoiseVelocity);
        vec3 a = calcPosition(textureNoiseFrequency*textureCoordinates+ vec2(0.0, d), uTime*textureNoiseVelocity);
        vec3 b = calcPosition(textureNoiseFrequency*textureCoordinates+ vec2(d, 0.0), uTime*textureNoiseVelocity);
        vec3 n = normalize(cross(b-p,a-p));

        color =  vec4(n ,1.0);
    } else if(uDrawMode == DRAW_MODE_2D_WATER){
        vec2 dist = (vec2(0.5)-textureCoordinates);
        float len = length(dist);
        float p2c = 2.0*len / sqrt(2.0);
        p2c*= p2c;
        p2c*= p2c;


        vec4 shift = texture(uSampler[1], textureCoordinates)-0.5;

        color = texture(uSampler[0], textureCoordinates+shift.xy*p2c*uEffectAmount);
        color.xyz += length(shift)*p2c*uEffectAmount;
        skipEffect = true;
    }else if(uDrawMode == DRAW_MODE_2D_SHIFT){
        vec2 delta = 1.0/uCanvasSize;

        float pix = 4.0*uEffectAmount;

        vec4 t1 = texture(uSampler[0], textureCoordinates+vec2(-pix*delta.x*0.5,-pix*delta.y*0.5));
        vec4 t2 = texture(uSampler[0], textureCoordinates+vec2(pix*delta.x, 0.0));
        vec4 t3 = texture(uSampler[0], textureCoordinates+vec2(0.0, pix*delta.y));

        color.xyz = vec3(t1.x, t2.y, t3.z);
        color.w = 1.0;
        skipEffect = true;
    } else if(uDrawMode == DRAW_MODE_2D_LENS){
        vec2 dist = (vec2(0.5)-textureCoordinates);
        float len = length(dist);
        float p2c = 2.0*len / sqrt(2.0);
        p2c*= p2c;
        p2c*= p2c;

        color.xyz = texture(uSampler[0], textureCoordinates+dist*p2c*uEffectAmount).xyz;
        color.w = 1.0;
        skipEffect = true;
    } else if(uDrawMode == DRAW_MODE_2D_RADIAL){
        vec2 delta = 4.0/uCanvasSize;

        vec2 dist = (vec2(0.5)-textureCoordinates);
        vec2 norm = normalize(dist);

        float len = length(dist);
        float p2c = 2.0*len / sqrt(2.0);
        p2c*= p2c;
        p2c*= p2c;

        int maxIters= 32;
        int iters = clamp(int( float(maxIters)*p2c*uEffectAmount ), 1, maxIters);
        vec4 sum = vec4(0.0);
        for(int i=0; i < iters; ++i){
            sum += texture(uSampler[0], textureCoordinates+norm*delta*float(i));
        }
        sum /= float(iters);
        color = sum;
        skipEffect = true;
    } else {
        color = texture(uSampler[0], textureCoordinates)*vColor;
    }

    vec3 normal = normalize(vNormal);
    if (uEnableLight) {
        float dotFactor = dot(normal, -uLightDirection);
        color = color*vec4(dotFactor, dotFactor, dotFactor, 1.0);
    }

    if (uDrawMode == DRAW_MODE_2D_MIX){
        color *= 0.5;
        color.xyz += 0.3;
    }
    else if (uDrawMode == DRAW_MODE_NO_EDGES_MASK || uDrawMode == DRAW_MODE_EDGES) {
        vec3 vertexToCam = normalize(vPosition.xyz-uCameraPosition);
        float edgeDot = abs(dot(vertexToCam, normal));
        float edgeFactor = 0.3;
        if (uDrawMode == DRAW_MODE_EDGES) {
            color = edgeDot < edgeFactor ? vColor: vec4(0.0);
        }else {
            color = edgeDot < edgeFactor ? vec4(0.0) : vec4(1.0);
        }
    }

    if (uDrawMode == DRAW_MODE_SKY || uDrawMode == DRAW_MODE_BILLBOARD || uDrawMode == DRAW_MODE_MANDALA) {
        color.xyz *= vColor.xyz;
    }
    if(!skipEffect) {
        color.w *= uEffectAmount;
    }
    fragColor = alphaBlend(color);

}