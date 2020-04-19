#version 300 es
precision highp float;
precision highp int;

in vec4 aVertexPosition;
in vec4 aVertexNormal;
in vec2 aTextureCoordinates;

uniform int uDrawMode;
uniform float uDrawVariant;
uniform sampler2D uAudioSampler;

uniform mat4 uViewMatrix;
uniform mat4 uOrthoMatrix;
uniform mat4 uProjectionMatrix;
uniform mat4 uModelMatrix;
uniform vec3 uLightDirection;
uniform float uTime;

out vec4 vColor;
out vec3 vNormal;
out vec3 vLightDirection;
out vec2 vTextureCoordinates;
out vec4 vPosition;

//#COMMON
//#PERLIN
//#HSL2RGB

void main(void) {
    vec2 tTextureCoordinates = aTextureCoordinates;
    vColor = vec4(1.0,1.0,1.0,1.0);
    vPosition = uModelMatrix*aVertexPosition;

    if(uDrawMode == DRAW_MODE_2D || uDrawMode == DRAW_MODE_2D_MIX) {
        gl_Position = uOrthoMatrix * vPosition;
        vTextureCoordinates.x = tTextureCoordinates.x;
        vTextureCoordinates.y = 1.0 - tTextureCoordinates.y;
        return;
    }
    else {
        mat4 viewProjectionMatrix = uProjectionMatrix * uViewMatrix;
        float saturation = 4.0;

        if (uDrawMode == DRAW_MODE_CYLINDER) {
            float cx = aTextureCoordinates.x;
            float cy = cos(aTextureCoordinates.y*2.0*PI);
            vec4 audio = texture(uAudioSampler, vec2(aTextureCoordinates.x, 0.0));

            float time = uTime+audio.x*2.0;

            // COLOR
            float colorVelocity = 0.5;// color changes quicker
            float colorFrequency = 0.2;// color is wider
            vColor.xyz = hsv2rgb(
                noise(vec4(cx*colorFrequency, cy, time*colorVelocity, uDrawVariant)),
                1.0,
                1.0
            );
            vColor.w = 1.0;

            // TEXTURE
            float textureNoiseVelocity = 0.2;
            float textureNoiseFrequency = 0.5;
            vec2 noiseTexture = vec2(
                noise(vec4(cx, cy, uTime*textureNoiseVelocity, uDrawVariant)*textureNoiseFrequency),
                noise(vec4(uDrawVariant, cx, cy, uTime*textureNoiseVelocity)*textureNoiseFrequency)
            );

            vec2 textureVelocity = vec2(-0.5, 0.1);
            float textureRotation = 0.5;
            float textureWaveSize = 0.4;

            vec2 dTextureCoordinates = uTime*textureVelocity + noiseTexture*textureWaveSize;
            dTextureCoordinates.y=textureRotation*sin(dTextureCoordinates.y);
            tTextureCoordinates += dTextureCoordinates;

            // POSITION
            float displacementAmplitude = 16.0;
            float displacementFrequency = 0.05;
            float displacementVelocity = 0.05;
            vec4 displacement = displacementAmplitude * vec4(
                noise(vec4(uDrawVariant, vPosition.y*displacementFrequency, 0.0, time*displacementVelocity)),
                0.0,
                noise(vec4(uDrawVariant, 0.0, vPosition.y*displacementFrequency, time*displacementVelocity)),
                0.0
            );
            vPosition += displacement;
        } else if (uDrawMode == DRAW_MODE_EDGES) {
            float cx = aTextureCoordinates.x;
            float cy = cos(aTextureCoordinates.y*PI);
            vec4 audio = texture(uAudioSampler, vec2(cx, 0.0));

            float time = uTime+audio.x*4.0;


            // COLOR
            float colorVelocity = 0.2;// color changes quicker
            float colorFrequency = 0.1;// color is wider
            vColor.xyz = hsv2rgb(
                noise(1.0*vec4(cx*colorFrequency, cy*colorFrequency, time*colorVelocity, uDrawVariant)),
                1.0,
                1.0
            );
            vColor.w = 1.0;
        } else if (uDrawMode == DRAW_MODE_SKY) {
            float cx = 0.0;
            float cy = cos(aTextureCoordinates.y*PI);
            vec4 audio = texture(uAudioSampler, vec2(cy, 0.0));

            float time = uTime+audio.x;

            // COLOR
            float colorVelocity = 0.5;// color changes quicker
            float colorFrequency = 1.0;// color is wider
            vColor.xyz = hsv2rgb(
                noise(1.0*vec4(cx*colorFrequency, cy, time*colorVelocity, uDrawVariant)),
                noise(1.0*vec4(uDrawVariant, cx*colorFrequency, cy, colorVelocity*time))*saturation,
                1.0
            );
            vColor.w = 1.0;
        } else if (uDrawMode == DRAW_MODE_BILLBOARD) {
            float cx = aTextureCoordinates.x;
            float cy = aTextureCoordinates.y;
            float time = uTime;

            // COLOR
            float colorVelocity = 0.2;// color changes quicker
            float colorFrequency = 0.1;// color is wider
            vColor.xyz = hsv2rgb(
                noise(vec4(cx*colorFrequency, cy, time*colorVelocity, uDrawVariant)),
                1.0,
                1.0
            );
            vColor.w = 1.0;
        } else if (uDrawMode == DRAW_MODE_MANDALA) {
            vec4 audio = texture(uAudioSampler, vec2(0.0, 0.0));
            float cx = aTextureCoordinates.x;
            float cy = aTextureCoordinates.y;
            float time = uTime+audio.x*4.0;

            // COLOR
            float colorVelocity = 0.2;// color changes quicker
            float colorFrequency = 32.0;// color is wider
            vColor.xyz = hsv2rgb(
                noise(vec4(cx*colorFrequency, cy*colorFrequency, time*colorVelocity, uDrawVariant)),
                1.0,
                1.0
            );
            vColor.w = 1.0;
        } else if (uDrawMode == DRAW_MODE_TORUS) {
            float angle = abs(atan(vPosition.z, vPosition.x))/PI;
            vec4 audio = texture(uAudioSampler, vec2(angle, 0.0));
            float cx = 0.0;
            float cy = angle;
            float time = uTime+audio.x;

            // COLOR
            float colorVelocity = 0.2;// color changes quicker
            float colorFrequency = 100.0;// color is wider
            vColor.xyz = hsv2rgb(
                noise(vec4(cx*colorFrequency, cy, time*colorVelocity, uDrawVariant)),
                1.0,
                1.0
            );
            vColor.w = 0.5;

            // POSITION
            float displacementAmplitude = 16.0;
            float displacementFrequency = 0.1;
            float displacementVelocity = 2.0;
            vec4 displacement = displacementAmplitude * vec4(
                0.0,
                audio.x-0.5,
                0.0,
                0.0
            );
            vPosition += displacement;
        } else if (uDrawMode == DRAW_MODE_CUBE) {
            float angle = abs(atan(vPosition.z, vPosition.x))/PI;
            vec4 audio = texture(uAudioSampler, vec2(angle, 0.0));
            float cx = 0.0;
            float cy = angle;
            float time = uTime+audio.x;

            // COLOR
            float colorVelocity = 0.2;// color changes quicker
            float colorFrequency = 100.0;// color is wider
            vColor.xyz = hsv2rgb(
                noise(vec4(cx*colorFrequency, cy, time*colorVelocity, uDrawVariant)),
                1.0,
                1.0
            );
            vColor.w = 1.0;
        }

        mat3 vNormalMatrix = transpose(inverse(mat3(uModelMatrix)));
        vNormal = normalize(vNormalMatrix * aVertexNormal.xyz);
        gl_Position = viewProjectionMatrix * vPosition;
        vTextureCoordinates = tTextureCoordinates;
    }
}