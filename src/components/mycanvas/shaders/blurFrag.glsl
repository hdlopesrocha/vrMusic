
vec4 blurFrag(vec2 textureCoordinates) {
    vec4 maskColor = texture(uSampler[1], textureCoordinates);
    vec4 color = vec4(0.0);

    if (maskColor.x > 0.0) {
        vec4 sum = vec4(0.0);
        vec2 delta = 4.0/uCanvasSize;
        int count = 0;
        int size = 4;
        for (int i=-size; i <= size; ++i) {
            for (int j=-size; j <= size; ++j) {
                sum += texture(uSampler[0], textureCoordinates+delta*vec2(i, j));
                ++count;
            }
        }
        color = (sum / float(count))*uEffectAmount+(1.0 - uEffectAmount)*texture(uSampler[0], textureCoordinates);
    }
    return color;
}