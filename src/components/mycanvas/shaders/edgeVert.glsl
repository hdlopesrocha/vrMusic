
vec4 edgeVert(inout vec2 tTextureCoordinates) {
    float cx = aTextureCoordinates.x;
    float cy = cos(aTextureCoordinates.y*PI);
    float time = uTime+uAudioLevel;

    // COLOR
    float colorVelocity = 0.2;// color changes quicker
    float colorFrequency = 0.1;// color is wider
    vColor.xyz = hsv2rgb(
        noise(vec3(cx*colorFrequency, cy*colorFrequency, time*colorVelocity)),
        1.0,
        1.0
    );
    vColor.w = 1.0;
    return vec4(0.0);
}