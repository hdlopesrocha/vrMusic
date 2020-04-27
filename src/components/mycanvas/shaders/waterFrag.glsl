
vec4 waterFrag(vec2 textureCoordinates) {
    vec3 normal = getNormalAtPosition(textureCoordinates, 48.0, 1.0/uCanvasSize)-0.5;

    vec2 dist = (vec2(0.5)-textureCoordinates);
    float len = length(dist);
    float p2c = 2.0*len / sqrt(2.0);
    p2c*= p2c;
    p2c*= p2c;

    vec3 lightDirection = normalize(vec3(1.0,1.0,1.0));
    float diffuseFactor = dot(normalize(normal),lightDirection)*uEffectAmount;

    vec4 color = texture(uSampler[0], clamp(textureCoordinates+normal.xy*p2c*uEffectAmount, 0.0, 1.0));
    color.rgb += (1.0-diffuseFactor)*uEffectAmount*p2c;
    return color;
}