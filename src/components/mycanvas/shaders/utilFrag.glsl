vec4 alphaBlend(vec4 color){
    return vec4(color.x * color.w, color.y * color.w, color.z * color.w, color.w);
}

vec3 getPositionAtCoords(vec2 pos, float t) {
    float height = noise(vec3(pos, t));
    return vec3(pos, height);
}

vec3 getNormalAtPosition(vec2 position, float textureNoiseFrequency, vec2 delta) {
    float textureNoiseVelocity = 1.0;

    vec3 p = getPositionAtCoords(textureNoiseFrequency*position, uTime*textureNoiseVelocity);
    vec3 a = getPositionAtCoords(textureNoiseFrequency*position+ vec2(0.0, delta.y), uTime*textureNoiseVelocity);
    vec3 b = getPositionAtCoords(textureNoiseFrequency*position+ vec2(delta.x, 0.0), uTime*textureNoiseVelocity);
    vec3 n = normalize(cross(b-p,a-p));
    return n;
}

float toGrayScale(vec3 color){
    return max(color.x, max(color.y, color.z));
}

vec3 getPositionAtTexture(vec2 pos) {
    vec4 color = texture(uSampler[1], pos);
    float height = toGrayScale(color.xyz);
    return vec3(pos, height);
}

vec3 getNormalAtTexture(vec2 pos, vec2 delta) {
    vec3 p = getPositionAtTexture(pos);
    vec3 a = getPositionAtTexture(pos+ vec2(0.0, delta.y));
    vec3 b = getPositionAtTexture(pos+ vec2(delta.x, 0.0));
    vec3 n = normalize(cross(b-p,a-p));
    return n;
}