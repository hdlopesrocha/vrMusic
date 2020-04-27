
vec4 skyVert(inout vec2 tTextureCoordinates) {
    float saturation = 4.0;
    float cx = 0.0;
    float cy = cos(aTextureCoordinates.y*PI*2.0);
    float time = uTime+uAudioLevel;

    // COLOR
    float colorVelocity = 0.2;// color changes quicker
    float colorFrequency = 0.5;// color is wider
    vColor.xyz = hsv2rgb(
        cos(noise(vec3(cy*colorFrequency, time*colorVelocity, 0.0))*PI*0.5),
        noise(vec3(0.0, cy*colorFrequency, time*colorVelocity))*saturation,
        1.0
    );
    vColor.w = 1.0;
    return vec4(0.0);
}