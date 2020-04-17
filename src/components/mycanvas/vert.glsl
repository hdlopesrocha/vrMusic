#version 300 es
precision highp float;
precision highp int;

in vec4 aVertexPosition;
in vec4 aVertexNormal;
in vec2 aTextureCoordinates;

uniform int uDrawMode;
uniform float uDrawVariant;

uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;
uniform mat4 uModelMatrix;
uniform vec3 uLightDirection;
uniform float uTime;

out vec4 vColor;
out vec3 vNormal;
out vec3 vLightDirection;
out vec2 vTextureCoordinates;
out vec4 vPosition;

//#PERLIN

void main(void) {
    vPosition = uModelMatrix*aVertexPosition;

    // temporary variables
    vec4 tNormal = uModelMatrix*aVertexNormal;
    vec2 tTextureCoordinates = aTextureCoordinates;


    if (uDrawMode == 2) {
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
    } else if (uDrawMode == 3) {
        float cx = aTextureCoordinates.x;
        float cy = cos(aTextureCoordinates.y*PI);
        float time = uTime;

        // COLOR
        float colorVelocity = 0.5;// color changes quicker
        float colorFrequency = 0.2;// color is wider
        vec4 noiseColor = vec4(
            noise(1.0*vec4(cx*colorFrequency, cy, time*colorVelocity, uDrawVariant)),
            noise(1.0*vec4(uDrawVariant, cx*colorFrequency, cy, colorVelocity*time)),
            noise(1.0*vec4(cx*colorFrequency, cy, uDrawVariant, colorVelocity*time)),
        0.0
        );
        vColor = noiseColor;
    } else if (uDrawMode == 4) {
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
    }

    mat4 mv = uViewMatrix*uModelMatrix;
    mat3 vNormalMatrix = transpose(inverse(mat3(mv)));

    mat4 viewProjectionMatrix = uProjectionMatrix * uViewMatrix;

    gl_Position = viewProjectionMatrix * vPosition;
    vNormal = normalize(vNormalMatrix * aVertexNormal.xyz);
    vTextureCoordinates = tTextureCoordinates;

}