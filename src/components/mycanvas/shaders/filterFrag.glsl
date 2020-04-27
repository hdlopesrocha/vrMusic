
vec4 filterFrag(vec2 textureCoordinates) {
    vec2 dist = (vec2(0.5)-textureCoordinates);
    vec2 norm = normalize(dist);
    float len = length(dist);
    float p2c = 2.0*len / sqrt(2.0);
    p2c*= p2c;

    float filterSize = 2.0;
    vec3 filterNormal = 2.0*(texture(uSampler[1], textureCoordinates*filterSize).xyz-vec3(0.5));
    vec3 filterBump = texture(uSampler[2], textureCoordinates*filterSize).xyz;
    float bumpHeight = 16.0;
    vec3 bump = filterBump*bumpHeight*p2c;

    vec2 delta = 128.0/uCanvasSize;
    vec3 lightDirection = normalize(vec3(1.0,1.0,1.0));
    vec3 tex = texture(uSampler[0], textureCoordinates+filterNormal.xy*delta*bump.x*uEffectAmount).xyz;
    float diffuseFactor = dot(normalize(filterNormal),lightDirection)*uEffectAmount;

    tex.rgb += (1.0-diffuseFactor)*uEffectAmount*p2c;
    return vec4(tex, 1.0);
}