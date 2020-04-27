
vec4 torusVert(inout vec2 tTextureCoordinates) {
    float angle = abs(atan(vPosition.z, vPosition.x))/PI;
    vec4 audio = texture(uAudioSampler, vec2(angle, 0.0));
    float cx = 0.0;
    float cy = angle;
    float time = uTime+uAudioLevel;

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
    return displacement;
}