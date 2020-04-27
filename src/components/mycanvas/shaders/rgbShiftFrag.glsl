
vec4 rgbShiftFrag(vec2 textureCoordinates) {
    float pixelShift = 8.0;
    vec2 shift = uEffectAmount*pixelShift/uCanvasSize;

    vec4 t1 = texture(uSampler[0], clamp(textureCoordinates+shift*vec2(-0.5,-0.5), 0.0, 1.0));
    vec4 t2 = texture(uSampler[0], clamp(textureCoordinates+shift*vec2(1.0, 0.0), 0.0, 1.0));
    vec4 t3 = texture(uSampler[0], clamp(textureCoordinates+shift*vec2(0.0, 1.0), 0.0, 1.0));

    vec4 color = vec4(t1.x, t2.y, t3.z, 1.0);
    return color;
}