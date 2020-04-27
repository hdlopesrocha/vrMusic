
vec4 cubeVert(inout vec2 tTextureCoordinates) {
    float angle = abs(atan(vPosition.z, vPosition.x))/PI;
    float cx = 0.0;
    float cy = angle;
    float time = uTime+uAudioLevel;

    // COLOR
    float colorVelocity = 0.2;// color changes quicker
    float colorFrequency = 100.0;// color is wider
    vColor.xyz = hsv2rgb(
        noise(vec4(cx*colorFrequency, cy, time*colorVelocity, uDrawVariant)),
        1.0,
        1.0
    );
    vColor.w = 1.0;
    return vec4(0.0);
}