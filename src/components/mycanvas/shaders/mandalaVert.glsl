
vec4 mandalaVert(inout vec2 tTextureCoordinates) {
    vec4 audio = texture(uAudioSampler, vec2(0.0, 0.0));
    float cx = aTextureCoordinates.x;
    float cy = aTextureCoordinates.y;
    float time = uTime+uAudioLevel;

    // COLOR
    float colorVelocity = 0.2;// color changes quicker
    float colorFrequency = 32.0;// color is wider
    vColor.xyz = hsv2rgb(
        noise(vec3(cx*colorFrequency, cy*colorFrequency, time*colorVelocity)),
        1.0,
        1.0
    );
    vColor.w = 1.0;
    return vec4(0.0);
}