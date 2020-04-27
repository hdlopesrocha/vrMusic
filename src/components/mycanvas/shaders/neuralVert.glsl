
vec4 neuralVert(inout vec2 tTextureCoordinates) {
    float geometryVelocity = 0.2;// color changes quicker
    float geometryFrequency = 800.0;// color is wider

    float colorVelocity = 0.2;// color changes quicker
    float colorFrequency = 0.4;// color is wider
    float angle = abs(atan(vPosition.z, vPosition.x))/PI;
    float time = uTime+uAudioLevel;

    float n = noise(vec4(vPosition.x*geometryFrequency, vPosition.y*geometryFrequency, vPosition.z*geometryFrequency, time*geometryVelocity));

    float gx = noise(vec4(vPosition.y*geometryFrequency, vPosition.x*geometryFrequency, vPosition.z*geometryFrequency, time*geometryVelocity));
    float gy = noise(vec4(vPosition.z*geometryFrequency, vPosition.x*geometryFrequency, vPosition.y*geometryFrequency, time*geometryVelocity));
    float gz = noise(vec4(vPosition.z*geometryFrequency, vPosition.y*geometryFrequency,vPosition.x*geometryFrequency, time*geometryVelocity));

    float cx = noise(vec4(vPosition.y*colorFrequency, vPosition.x*colorFrequency, vPosition.z*colorFrequency, time*colorVelocity));
    float cy = noise(vec4(vPosition.z*colorFrequency, vPosition.x*colorFrequency, vPosition.y*colorFrequency, time*colorVelocity));

    if(n<0.2){
        vColor = vec4(0.0);
    }else {
        vColor.xyz = hsv2rgb(vec3(cx, cy*0.25+0.75, 1.0));
        vColor.w = 1.0;
    }

    // POSITION
    float displacementAmplitude = 0.5;
    float displacementFrequency = 0.1;
    float displacementVelocity = 2.0;
    vec4 displacement = displacementAmplitude * vec4(
        gx-0.5,
        gy-0.5,
        gz-0.5,
        0.0
    );
    return displacement;
}