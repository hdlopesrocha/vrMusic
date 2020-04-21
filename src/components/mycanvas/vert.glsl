#version 300 es
precision highp float;
precision highp int;

in vec4 aVertexPosition;
in vec4 aVertexNormal;
in vec2 aTextureCoordinates;

uniform int uDrawMode;
uniform float uDrawVariant;
uniform float uEffectAmount;
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

    if(uDrawMode <= DRAW_MODE_2D) {
        gl_Position = uOrthoMatrix * vPosition;
        vTextureCoordinates.x = tTextureCoordinates.x;
        vTextureCoordinates.y = 1.0 - tTextureCoordinates.y;
        return;
    }
    else {
        mat4 viewProjectionMatrix = uProjectionMatrix * uViewMatrix;
        float saturation = 4.0;

        if (uDrawMode == DRAW_MODE_3D_CYLINDER) {
            float cx = aTextureCoordinates.x;
            float cy = cos(aTextureCoordinates.y*2.0*PI);
            vec4 audio = texture(uAudioSampler, vec2(0.0, 0.0));

            float time = uTime+audio.x;

            // COLOR
            float colorVelocity = 0.5;// color changes quicker
            float colorFrequency = 0.2;// color is wider
            vColor.xyz = hsv2rgb(
                noise(vec4(cx*colorFrequency, cy*colorFrequency, time*colorVelocity, uDrawVariant)),
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
                noise(vec3(uDrawVariant, vPosition.y*displacementFrequency, time*displacementVelocity)),
                0.0,
                noise(vec3(uDrawVariant, time*displacementVelocity, vPosition.y*displacementFrequency)),
                0.0
            );
            vPosition += displacement;
        } else if (uDrawMode == DRAW_MODE_3D_EDGES) {
            float cx = aTextureCoordinates.x;
            float cy = cos(aTextureCoordinates.y*PI);
            vec4 audio = texture(uAudioSampler, vec2(cy, 0.0));

            float time = uTime+audio.x;


            // COLOR
            float colorVelocity = 0.2;// color changes quicker
            float colorFrequency = 0.1;// color is wider
            vColor.xyz = hsv2rgb(
                noise(vec3(cx*colorFrequency, cy*colorFrequency, time*colorVelocity)),
                1.0,
                1.0
            );
            vColor.w = 1.0;
        } else if (uDrawMode == DRAW_MODE_3D_SKY) {
            float cx = 0.0;
            float cy = cos(aTextureCoordinates.y*PI*2.0);
            vec4 audio = texture(uAudioSampler, vec2(0.0, 0.0));

            float time = uTime+audio.x*2.0;

            // COLOR
            float colorVelocity = 0.2;// color changes quicker
            float colorFrequency = 0.5;// color is wider
            vColor.xyz = hsv2rgb(
                cos(noise(vec3(cy*colorFrequency, time*colorVelocity, 0.0))*PI*0.5),
                noise(vec3(0.0, cy*colorFrequency, time*colorVelocity))*saturation,
                1.0
            );
            vColor.w = 1.0;
        } else if (uDrawMode == DRAW_MODE_3D_BILLBOARD) {
            float angle = abs(atan(vPosition.z, vPosition.x))/PI;
            vec4 audio = texture(uAudioSampler, vec2(angle, 0.0));

            float time = uTime;

            // COLOR
            float colorVelocity = 0.2;// color changes quicker
            float colorFrequency = 1.0;// color is wider
            vColor.xyz = hsv2rgb(
                noise(vec4(colorVelocity*angle, time*colorVelocity, 0.0, uDrawVariant)),
                1.0,
                1.0
            );
            vColor.w = 1.0;

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

        } else if (uDrawMode == DRAW_MODE_3D_MANDALA) {
            vec4 audio = texture(uAudioSampler, vec2(0.0, 0.0));
            float cx = aTextureCoordinates.x;
            float cy = aTextureCoordinates.y;
            float time = uTime+audio.x*4.0;

            // COLOR
            float colorVelocity = 0.2;// color changes quicker
            float colorFrequency = 32.0;// color is wider
            vColor.xyz = hsv2rgb(
                noise(vec3(cx*colorFrequency, cy*colorFrequency, time*colorVelocity)),
                1.0,
                1.0
            );
            vColor.w = 1.0;
        } else if (uDrawMode == DRAW_MODE_3D_TORUS) {
            float angle = abs(atan(vPosition.z, vPosition.x))/PI;
            vec4 audio = texture(uAudioSampler, vec2(angle, 0.0));
            float cx = 0.0;
            float cy = angle;
            float time = uTime+audio.x;

            // COLOR
            float colorVelocity = 0.2;// color changes quicker
            float colorFrequency = 100.0;// color is wider
            vColor.xyz = hsv2rgb(
                noise(vec3(cx*colorFrequency, cy, time*colorVelocity)),
                1.0,
                1.0
            );
            vColor.w =1.0;

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
        } else if (uDrawMode == DRAW_MODE_3D_CUBE) {
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
        } else if (uDrawMode == DRAW_MODE_3D_SPHERICAL_GRID) {
            float geometryVelocity = 0.2;// color changes quicker
            float geometryFrequency = 100.0;// color is wider

            float colorVelocity = 0.2;// color changes quicker
            float colorFrequency = 0.01;// color is wider
            float angle = abs(atan(vPosition.z, vPosition.x))/PI;
            vec4 audio = texture(uAudioSampler, vec2(angle, 0.0));
            float time = uTime+audio.x;

            float g = noise(vec4(vPosition.x*geometryFrequency, vPosition.z*geometryFrequency, vPosition.z*geometryFrequency, time*geometryVelocity));
            float gx = noise(vec4(vPosition.y*geometryFrequency, vPosition.x*geometryFrequency, vPosition.z*geometryFrequency, time*geometryVelocity));
            float gy = noise(vec4(vPosition.z*geometryFrequency, vPosition.x*geometryFrequency, vPosition.y*geometryFrequency, time*geometryVelocity));
            float gz = noise(vec4(vPosition.z*geometryFrequency, vPosition.y*geometryFrequency,vPosition.x*geometryFrequency, time*geometryVelocity));

            float cx = noise(vec4(vPosition.y*colorFrequency, vPosition.x*colorFrequency, vPosition.z*colorFrequency, time*colorVelocity));
            float cy = noise(vec4(vPosition.z*colorFrequency, vPosition.x*colorFrequency, vPosition.y*colorFrequency, time*colorVelocity));

            if(g<0.2){
                vColor = vec4(0.0);
            }else {
                vColor.xyz = hsv2rgb(vec3(cx, cy*0.25+0.75, 1.0));
                vColor.w = 1.0;
            }

            // POSITION
            float displacementAmplitude = 4.0;
            float displacementFrequency = 0.1;
            float displacementVelocity = 2.0;
            vec4 displacement = displacementAmplitude * vec4(
                gx-0.5,
                gy-0.5,
                gz-0.5,
                0.0
            );
            vPosition += displacement;
        }

            mat3 vNormalMatrix = transpose(inverse(mat3(uModelMatrix)));
        vNormal = normalize(vNormalMatrix * aVertexNormal.xyz);
        gl_Position = viewProjectionMatrix * vPosition;
        vTextureCoordinates = tTextureCoordinates;
    }
}