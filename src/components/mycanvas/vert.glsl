#version 300 es
precision highp float;
precision highp int;

in vec4 aVertexPosition;
in vec3 aVertexNormal;
in vec2 aTextureCoordinates;

uniform int uDrawMode;
uniform int uDrawVariant;

uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;
uniform mat4 uModelMatrix;
uniform float uTime;

out vec4 vColor;
out vec3 vNormal;
out vec2 vTextureCoordinates;

//#PERLIN

void main(void) {
    mat4 mvp = uProjectionMatrix * uViewMatrix;

    // temporary variables
    vec4 tPosition = uModelMatrix*aVertexPosition;
    vec2 tTextureCoordinates = aTextureCoordinates;

    if(uDrawMode == 2) {
        float cx = aTextureCoordinates.x;
        float cy = cos(aTextureCoordinates.y*PI);
        float time = uTime;
        float variant = 4.0 * float(uDrawVariant);

        // COLOR
        float colorVelocity = 0.5; // color changes quicker
        float colorFrequency = 0.2; // color is wider
        vec4 noiseColor = vec4(
            noise(1.0*vec4(cx*colorFrequency, cy, time*colorVelocity, variant)),
            noise(1.0*vec4(variant, cx*colorFrequency, cy, colorVelocity*time)),
            noise(1.0*vec4(cx*colorFrequency, cy, variant, colorVelocity*time)),
            0.0
        );
        vColor = noiseColor;

        // TEXTURE
        float textureNoiseVelocity = 0.2;
        float textureNoiseFrequency = 0.5;
        vec2 noiseTexture = vec2(
            noise(vec4(cx, cy, time*textureNoiseVelocity, variant)*textureNoiseFrequency),
            noise(vec4(variant, cx, cy, time*textureNoiseVelocity)*textureNoiseFrequency)
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
            noise(vec4(variant, tPosition.y*displacementFrequency, 0.0, uTime*displacementVelocity)),
            0.0,
            noise(vec4(variant, 0.0, tPosition.y*displacementFrequency, uTime*displacementVelocity)),
            0.0
        );
        tPosition += displacement;
    }

  gl_Position = mvp *tPosition;
  vNormal = aVertexNormal;
  vTextureCoordinates = tTextureCoordinates;

}