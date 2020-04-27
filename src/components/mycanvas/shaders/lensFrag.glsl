
vec4 lensFrag(vec2 textureCoordinates) {
    vec2 dist = (vec2(0.5)-textureCoordinates);
    float len = length(dist);
    float p2c = 2.0*len / sqrt(2.0);
    p2c*= p2c;
    p2c*= p2c;

    return vec4(texture(uSampler[0], clamp(textureCoordinates+dist*p2c*uEffectAmount, 0.0, 1.0)).xyz, 1.0);
}