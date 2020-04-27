
vec4 hexagonFrag(vec2 textureCoordinates) {
    vec4 color = vec4(0.0);
    if(vColor.w > 0.95){
        color = texture(uSampler[0], vTextureCoordinates)*vColor;
    }
    color.w *= uEffectAmount;
    return color;
}