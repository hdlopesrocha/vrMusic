#version 300 es
precision highp float;
precision highp int;

in vec4 aVertexPosition;
in vec4 aVertexNormal;
in vec2 aTextureCoordinates;

uniform int uDrawMode;
uniform float uDrawVariant;
uniform float uEffectAmount;
uniform sampler2D uAudioSampler;

uniform mat4 uViewMatrix;
uniform mat4 uOrthoMatrix;
uniform mat4 uProjectionMatrix;
uniform mat4 uModelMatrix;
uniform vec3 uLightDirection;
uniform float uTime;
uniform float uTimeShift;
uniform float uAnimationVelocity;
uniform float uAudioLevel;
uniform vec4 uAmbientColor;
uniform vec4 uModelColor;

out vec4 vColor;
out vec3 vNormal;
out vec3 vLightDirection;
out vec2 vTextureCoordinates;
out vec4 vPosition;

#include "common.glsl"
#include "libs/perlin.glsl"
#include "libs/hsl2rgb.glsl"
#include "shaders/cylinderVert.glsl"
#include "shaders/edgeVert.glsl"
#include "shaders/skyVert.glsl"
#include "shaders/billboardVert.glsl"
#include "shaders/mandalaVert.glsl"
#include "shaders/torusVert.glsl"
#include "shaders/cubeVert.glsl"
#include "shaders/pyramidVert.glsl"
#include "shaders/neuralVert.glsl"
#include "shaders/hexagonVert.glsl"

void main(void) {
    vec2 tTextureCoordinates = aTextureCoordinates;
    vColor = vec4(1.0,1.0,1.0,1.0);
    vPosition = uModelMatrix*aVertexPosition;

    if(uDrawMode <= DRAW_MODE_2D) {
        gl_Position = uOrthoMatrix * vPosition;
        vTextureCoordinates.x = tTextureCoordinates.x;
        vTextureCoordinates.y = 1.0 - tTextureCoordinates.y;
        return;
    }
    else {
        mat4 viewProjectionMatrix = uProjectionMatrix * uViewMatrix;

        if (uDrawMode == DRAW_MODE_3D_CYLINDER) {
            vPosition += cylinderVert(tTextureCoordinates);
        } else if (uDrawMode == DRAW_MODE_3D_EDGES) {
            vPosition += edgeVert(tTextureCoordinates);
        } else if (uDrawMode == DRAW_MODE_3D_SKY) {
            vPosition += skyVert(tTextureCoordinates);
        } else if (uDrawMode == DRAW_MODE_3D_BILLBOARD) {
            vPosition += billboardVert(tTextureCoordinates);
        } else if (uDrawMode == DRAW_MODE_3D_MANDALA) {
            vPosition += mandalaVert(tTextureCoordinates);
        } else if (uDrawMode == DRAW_MODE_3D_TORUS) {
            vPosition += torusVert(tTextureCoordinates);
        } else if (uDrawMode == DRAW_MODE_3D_CUBE) {
            vPosition += cubeVert(vTextureCoordinates);
        } else if (uDrawMode == DRAW_MODE_3D_PYRAMID) {
            vPosition += pyramidVert(vTextureCoordinates);
        } else if (uDrawMode == DRAW_MODE_3D_NEURAL_GRID) {
           vPosition += neuralVert(vTextureCoordinates);
        }else if (uDrawMode == DRAW_MODE_3D_HEXAGON_GRID) {
            vPosition += hexagonVert(vTextureCoordinates);
        } else {
            vColor = uModelColor;
        }

        mat3 vNormalMatrix = transpose(inverse(mat3(uModelMatrix)));
        vNormal = normalize(vNormalMatrix * aVertexNormal.xyz);
        gl_Position = viewProjectionMatrix * vPosition;
        vTextureCoordinates = tTextureCoordinates;
    }
}