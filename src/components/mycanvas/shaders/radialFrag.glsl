
vec4 radialFrag(vec2 textureCoordinates) {
    vec2 delta = 4.0/uCanvasSize;

    vec2 dist = (vec2(0.5)-textureCoordinates);
    vec2 norm = normalize(dist);

    float len = length(dist);
    float p2c = 2.0*len / sqrt(2.0);
    p2c*= p2c;

    int maxIters= 32;
    int iters = clamp(int( float(maxIters)*p2c*uEffectAmount ), 1, maxIters);
    vec4 sum = vec4(0.0);
    for(int i=0; i < iters; ++i){
        sum += texture(uSampler[0], clamp(textureCoordinates+norm*delta*float(i), 0.0, 1.0 ));
    }
    return sum / float(iters);
}