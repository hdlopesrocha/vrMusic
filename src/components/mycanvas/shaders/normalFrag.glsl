
vec4 normalFrag(vec2 textureCoordinates) {
    vec3 normal = getNormalAtTexture(textureCoordinates, 1.0/uCanvasSize);
    vec2 delta = 32.0/uCanvasSize;

    vec4 height = texture(uSampler[1], textureCoordinates);
    float superficialRefraction = 1.0 - toGrayScale(height.xyz);

    return texture(uSampler[0], textureCoordinates+normal.xy*delta*uEffectAmount*superficialRefraction);
}