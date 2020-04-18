#version 300 es
precision highp float;
precision highp int;

in vec4 aVertexPosition;
in vec4 aVertexNormal;
in vec2 aTextureCoordinates;

uniform int uDrawMode;
uniform float uDrawVariant;

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

void main(void) {
    vec2 tTextureCoordinates = aTextureCoordinates;

    vPosition = uModelMatrix*aVertexPosition;

    if(uDrawMode == DRAW_MODE_2D || uDrawMode == DRAW_MODE_2D_MIX) {
        gl_Position = uOrthoMatrix * vPosition;
        vTextureCoordinates = tTextureCoordinates;
        return;
    }
    else {
        mat4 viewProjectionMatrix = uProjectionMatrix * uViewMatrix;


        if (uDrawMode == DRAW_MODE_CYLINDER) {
            float cx = aTextureCoordinates.x;
            float cy = cos(aTextureCoordinates.y*PI);
            float time = uTime;

            // COLOR
            float colorVelocity = 0.5;// color changes quicker
            float colorFrequency = 0.2;// color is wider
            vec4 noiseColor = vec4(
                noise(vec4(cx*colorFrequency, cy, time*colorVelocity, uDrawVariant)),
                noise(vec4(uDrawVariant, cx*colorFrequency, cy, colorVelocity*time)),
                noise(vec4(cx*colorFrequency, cy, uDrawVariant, colorVelocity*time)),
                0.0
            );
            vColor = noiseColor;

            // TEXTURE
            float textureNoiseVelocity = 0.2;
            float textureNoiseFrequency = 0.5;
            vec2 noiseTexture = vec2(
                noise(vec4(cx, cy, time*textureNoiseVelocity, uDrawVariant)*textureNoiseFrequency),
                noise(vec4(uDrawVariant, cx, cy, time*textureNoiseVelocity)*textureNoiseFrequency)
            );

            vec2 textureVelocity = vec2(-1.0, 0.5);
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
                noise(vec4(uDrawVariant, vPosition.y*displacementFrequency, 0.0, uTime*displacementVelocity)),
                0.0,
                noise(vec4(uDrawVariant, 0.0, vPosition.y*displacementFrequency, uTime*displacementVelocity)),
                0.0
            );
            vPosition += displacement;
        } else if (uDrawMode == DRAW_MODE_EDGES) {
            float cx = aTextureCoordinates.x;
            float cy = cos(aTextureCoordinates.y*PI);
            float time = uTime;

            // COLOR
            float colorVelocity = 0.2;// color changes quicker
            float colorFrequency = 0.1;// color is wider
            vec4 noiseColor = vec4(
                noise(1.0*vec4(cx*colorFrequency, cy, time*colorVelocity, uDrawVariant)),
                noise(1.0*vec4(uDrawVariant, cx*colorFrequency, cy, colorVelocity*time)),
                noise(1.0*vec4(cx*colorFrequency, cy, uDrawVariant, colorVelocity*time)),
                0.0
            );
            vColor = noiseColor;
        } else if (uDrawMode == DRAW_MODE_SKY) {
            float cx = 0.0;
            float cy = cos(aTextureCoordinates.y*PI);
            float time = uTime;

            // COLOR
            float colorVelocity = 0.5;// color changes quicker
            float colorFrequency = 1.0;// color is wider
            vec4 noiseColor = vec4(
                noise(1.0*vec4(cx*colorFrequency, cy, time*colorVelocity, uDrawVariant)),
                noise(1.0*vec4(uDrawVariant, cx*colorFrequency, cy, colorVelocity*time)),
                noise(1.0*vec4(cx*colorFrequency, cy, uDrawVariant, colorVelocity*time)),
                0.0
            );
            vColor = noiseColor;
        } else if (uDrawMode == DRAW_MODE_BILLBOARD) {
            float cx = aTextureCoordinates.x;
            float cy = aTextureCoordinates.y;
            float time = uTime;

            // COLOR
            float colorVelocity = 0.2;// color changes quicker
            float colorFrequency = 0.1;// color is wider
            vec4 noiseColor = vec4(
                noise(vec4(cx*colorFrequency, cy, time*colorVelocity, uDrawVariant)),
                noise(vec4(uDrawVariant, cx*colorFrequency, cy, colorVelocity*time)),
                noise(vec4(cx*colorFrequency, cy, uDrawVariant, colorVelocity*time)),
                0.0
            );
            vColor = noiseColor;
        } else if (uDrawMode == DRAW_MODE_TORUS) {
            float cx = aTextureCoordinates.x;
            float cy = cos(aTextureCoordinates.y*PI);
            float time = uTime;

            // COLOR
            float colorVelocity = 0.5;// color changes quicker
            float colorFrequency = 0.1;// color is wider
            vec4 noiseColor = vec4(
                noise(vec4(cx*colorFrequency, cy, time*colorVelocity, uDrawVariant)),
                noise(vec4(uDrawVariant, cx*colorFrequency, cy, colorVelocity*time)),
                noise(vec4(cx*colorFrequency, cy, uDrawVariant, colorVelocity*time)),
                0.0
            );
            vColor = noiseColor;

            // POSITION
            float displacementAmplitude = 8.0;
            float displacementFrequency = 0.1;
            float displacementVelocity = 2.0;
            vec4 displacement = displacementAmplitude * vec4(
                0.0,
                noise(vec4(uDrawVariant, vPosition.x*displacementFrequency, vPosition.z*displacementFrequency, uTime*displacementVelocity)),
                0.0,
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