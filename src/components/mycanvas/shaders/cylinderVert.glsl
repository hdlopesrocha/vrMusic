
vec4 cylinderVert(inout vec2 tTextureCoordinates) {
    float cx = aTextureCoordinates.x;
    float cy = cos(aTextureCoordinates.y*2.0*PI);

    float time = uTimeShift*uAnimationVelocity+uAudioLevel;

    float timeGeometry = uTimeShift*uAnimationVelocity;

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
        noise(vec4(cx, cy, timeGeometry*textureNoiseVelocity, uDrawVariant)*textureNoiseFrequency),
        noise(vec4(uDrawVariant, cx, cy, timeGeometry*textureNoiseVelocity)*textureNoiseFrequency)
    );
    vec2 textureVelocity = vec2(-0.5, 0.1);
    float textureRotation = 0.5;
    float textureWaveSize = 0.4;

    vec2 dTextureCoordinates = timeGeometry*textureVelocity + noiseTexture*textureWaveSize;
    dTextureCoordinates.y=textureRotation*sin(dTextureCoordinates.y);
    tTextureCoordinates += dTextureCoordinates;

    // POSITION
    float displacementAmplitude = 16.0;
    float displacementFrequency = 0.05;
    float displacementVelocity = 0.05;
    vec4 displacement = displacementAmplitude * vec4(
        noise(vec3(uDrawVariant, vPosition.y*displacementFrequency, timeGeometry*displacementVelocity)),
        0.0,
        noise(vec3(uDrawVariant, timeGeometry*displacementVelocity, vPosition.y*displacementFrequency)),
        0.0
    );
    return displacement;
}