
vec4 edgeFrag(vec2 textureCoordinates, vec3 normal) {
    vec3 vertexToCam = normalize(vPosition.xyz-uCameraPosition);
    float edgeDot = abs(dot(vertexToCam, normal));
    float edgeFactor = 0.3;
    vec4 color = edgeDot < edgeFactor ? vColor: vec4(0.0);
    color.w *= uEffectAmount;
    return color;
}