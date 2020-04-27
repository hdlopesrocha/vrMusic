#version 300 es
precision highp float;
precision highp int;

uniform int uDrawMode;
uniform sampler2D uSampler[4];
uniform sampler2D uAudioSampler;

uniform bool uEnableLight;
uniform float uTime;
uniform float uTimeShift;
uniform float uAnimationVelocity;
uniform float uAudioLevel;
uniform vec3 uLightDirection;
uniform vec3 uCameraPosition;
uniform vec2 uCanvasSize;
uniform float uEffectAmount;
uniform vec4 uAmbientColor;

in vec3 vNormal;
in vec2 vTextureCoordinates;
in vec4 vColor;
in vec4 vPosition;

out vec4 fragColor;

#include "common.glsl"
#include "libs/perlin.glsl"
#include "libs/hsl2rgb.glsl"
#include "shaders/utilFrag.glsl"
#include "shaders/waterFrag.glsl"
#include "shaders/rgbShiftFrag.glsl"
#include "shaders/filterFrag.glsl"
#include "shaders/blurFrag.glsl"
#include "shaders/radialFrag.glsl"
#include "shaders/normalFrag.glsl"
#include "shaders/lensFrag.glsl"
#include "shaders/neuralFrag.glsl"
#include "shaders/hexagonFrag.glsl"
#include "shaders/edgeFrag.glsl"

void main(void) {
    vec4 ambientLight = vec4(0.0, 0.0, 0.0, 0.0);
    vec4 color = vec4(1.0, 1.0, 1.0, 1.0);

    if (uDrawMode == DRAW_MODE_2D_BLUR) {
        color = blurFrag(vTextureCoordinates);
    } else if(uDrawMode == DRAW_MODE_2D_WATER){
        color = waterFrag(vTextureCoordinates);
    } else if(uDrawMode == DRAW_MODE_2D_NORMAL){
        color = normalFrag(vTextureCoordinates);
    } else if(uDrawMode == DRAW_MODE_2D_SHIFT){
        color = rgbShiftFrag(vTextureCoordinates);
    } else if(uDrawMode == DRAW_MODE_2D_LENS){
        color = lensFrag(vTextureCoordinates);
    } else if(uDrawMode == DRAW_MODE_2D_FILTER){
        color = filterFrag(vTextureCoordinates);
    } else if(uDrawMode == DRAW_MODE_2D_RADIAL){
        color = radialFrag(vTextureCoordinates);
    } else if (uDrawMode == DRAW_MODE_3D_NEURAL_GRID) {
        color = neuralFrag(vTextureCoordinates);
    } else if (uDrawMode == DRAW_MODE_3D_HEXAGON_GRID) {
        color = hexagonFrag(vTextureCoordinates);
    } else if (
                uDrawMode == DRAW_MODE_2D_MIX ||
                uDrawMode == DRAW_MODE_3D_PYRAMID ||
                uDrawMode == DRAW_MODE_3D_CUBE ||
                uDrawMode == DRAW_MODE_3D_BILLBOARD ||
                uDrawMode == DRAW_MODE_3D_MANDALA ||
                uDrawMode == DRAW_MODE_3D_CYLINDER ||
                uDrawMode == DRAW_MODE_3D_TORUS
        ){
        color = texture(uSampler[0], vTextureCoordinates)*vColor;
        color.w *= uEffectAmount;
    } else {
        color = texture(uSampler[0], vTextureCoordinates)*vColor;
    }

    bool calculateNormal = uEnableLight || uDrawMode == DRAW_MODE_3D_EDGES;
    vec3 normal = calculateNormal ? normalize(vNormal) : vec3(0.0);
    if (uEnableLight) {
        float dotFactor = dot(normal, -uLightDirection);
        color *= vec4(dotFactor, dotFactor, dotFactor, 1.0);
        color += uAmbientColor;
    }

    if (uDrawMode == DRAW_MODE_3D_EDGES) {
        color = edgeFrag(vTextureCoordinates, normal);
    }

    fragColor = alphaBlend(color);

}