#version 300 es
precision highp float;
precision highp int;

uniform int uDrawMode;
uniform sampler2D uSampler[2];
uniform sampler2D uAudioSampler;
uniform float uEffectAmount;

uniform bool uEnableLight;
uniform float uTime;
uniform float uTimeShift;
uniform float uAnimationVelocity;
uniform float uAudioLevel;
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

vec3 getPositionAtCoords(vec2 pos, float t) {
    float height = noise(vec3(pos, t));
    return vec3(pos, height);
}

vec3 getNormalAtPosition(vec2 position, float textureNoiseFrequency) {
    float textureNoiseVelocity = 1.0;
    vec2 d = 1.0/uCanvasSize;

    vec3 p = getPositionAtCoords(textureNoiseFrequency*position, uTime*textureNoiseVelocity);
    vec3 a = getPositionAtCoords(textureNoiseFrequency*position+ vec2(0.0, d.y), uTime*textureNoiseVelocity);
    vec3 b = getPositionAtCoords(textureNoiseFrequency*position+ vec2(d.x, 0.0), uTime*textureNoiseVelocity);
    vec3 n = normalize(cross(b-p,a-p));
    return n;
}

float toGrayScale(vec3 color){
    return max(color.x, max(color.y, color.z));
}


vec3 getPositionAtTexture(vec2 pos) {
    vec4 color = texture(uSampler[1], pos);
    float height = toGrayScale(color.xyz);
    return vec3(pos, height);
}

vec3 getNormalAtTexture(vec2 pos) {
    vec2 d = 1.0/uCanvasSize;
    vec3 p = getPositionAtTexture(pos);
    vec3 a = getPositionAtTexture(pos+ vec2(0.0, d.y));
    vec3 b = getPositionAtTexture(pos+ vec2(d.x, 0.0));
    vec3 n = normalize(cross(b-p,a-p));
    return n;
}

void main(void) {
    vec4 color = vec4(1.0, 1.0, 1.0, 1.0);
    vec2 textureCoordinates = vTextureCoordinates;
    bool skipEffect = false;

    if (uDrawMode == DRAW_MODE_2D_BLUR) {
        vec4 maskColor = texture(uSampler[1], textureCoordinates);
        if (maskColor.x > 0.0) {
            vec4 sum = vec4(0.0);
            vec2 delta = 4.0/uCanvasSize;
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
    } else if (uDrawMode == DRAW_MODE_3D_TORUS) {
        color = vColor;
    } else if (uDrawMode == DRAW_MODE_3D_EDGES) {
        color = texture(uSampler[0], textureCoordinates);
    } else if(uDrawMode == DRAW_MODE_2D_WATER){
        vec3 normal = getNormalAtPosition(textureCoordinates, 48.0)-0.5;

        vec2 dist = (vec2(0.5)-textureCoordinates);
        float len = length(dist);
        float p2c = 2.0*len / sqrt(2.0);
        p2c*= p2c;
        p2c*= p2c;

        color = texture(uSampler[0], clamp(textureCoordinates+normal.xy*p2c*uEffectAmount, 0.0, 1.0));
        color.xyz += p2c*uEffectAmount*0.5;
        skipEffect = true;
    } else if(uDrawMode == DRAW_MODE_2D_NORMAL){
        vec3 normal = getNormalAtTexture(textureCoordinates);
        vec2 delta = 32.0/uCanvasSize;

        vec4 height = texture(uSampler[1], textureCoordinates);
        float superficialRefraction = 1.0 - toGrayScale(height.xyz);


        color = texture(uSampler[0], textureCoordinates+normal.xy*delta*uEffectAmount*superficialRefraction);

        //color = texture(uSampler[1], textureCoordinates);

        skipEffect = true;
    } else if(uDrawMode == DRAW_MODE_2D_SHIFT){
        float pixelShift = 8.0;
        vec2 shift = uEffectAmount*pixelShift/uCanvasSize;

        vec4 t1 = texture(uSampler[0], clamp(textureCoordinates+shift*vec2(-0.5,-0.5), 0.0, 1.0));
        vec4 t2 = texture(uSampler[0], clamp(textureCoordinates+shift*vec2(1.0, 0.0), 0.0, 1.0));
        vec4 t3 = texture(uSampler[0], clamp(textureCoordinates+shift*vec2(0.0, 1.0), 0.0, 1.0));

        color.xyz = vec3(t1.x, t2.y, t3.z);
        color.w = 1.0;
        skipEffect = true;
    } else if(uDrawMode == DRAW_MODE_2D_LENS){
        vec2 dist = (vec2(0.5)-textureCoordinates);
        float len = length(dist);
        float p2c = 2.0*len / sqrt(2.0);
        p2c*= p2c;
        p2c*= p2c;

        color.xyz = texture(uSampler[0], clamp(textureCoordinates+dist*p2c*uEffectAmount, 0.0, 1.0)).xyz;
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
            sum += texture(uSampler[0], clamp(textureCoordinates+norm*delta*float(i), 0.0, 1.0 ));
        }
        sum /= float(iters);
        color = sum;
        skipEffect = true;
    } else if (uDrawMode == DRAW_MODE_3D_SPHERICAL_GRID) {
        if(vColor.w < 0.95){
            color = vec4(0.0);
        }else {
            color = texture(uSampler[0], textureCoordinates)*vColor;
        }
    } else if (uDrawMode == DRAW_MODE_3D_HEXA_GRID) {
        if(vColor.w < 0.95){
            color = vec4(0.0);
        }else {
            color = texture(uSampler[0], textureCoordinates)*vColor;
        }
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
    else if (uDrawMode == DRAW_MODE_3D_NO_EDGES_MASK || uDrawMode == DRAW_MODE_3D_EDGES) {
        vec3 vertexToCam = normalize(vPosition.xyz-uCameraPosition);
        float edgeDot = abs(dot(vertexToCam, normal));
        float edgeFactor = 0.3;
        if (uDrawMode == DRAW_MODE_3D_EDGES) {
            color = edgeDot < edgeFactor ? vColor: vec4(0.0);
        }else {
            color = edgeDot < edgeFactor ? vec4(0.0) : vec4(1.0);
        }
    }

    if (uDrawMode == DRAW_MODE_3D_SKY || uDrawMode == DRAW_MODE_3D_BILLBOARD || uDrawMode == DRAW_MODE_3D_MANDALA) {
        color.xyz *= vColor.xyz;
    }
    if(!skipEffect) {
        color.w *= uEffectAmount;
    }
    fragColor = alphaBlend(color);

}