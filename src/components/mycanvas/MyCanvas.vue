<template>
    <div>
        <canvas v-bind:width="canvasWidth" v-bind:height="canvasHeight" id="glcanvas"></canvas>
        <br>
        <button v-on:click="enableVr">VR</button>
    </div>
</template>

<script>
    /* eslint-disable no-unused-vars */
    import {mat4} from "gl-matrix";

    const DRAW_MODE_2D_MIX = -3
    const DRAW_MODE_2D = -2
    const DRAW_MODE_MASK = -1
    const DRAW_MODE_DEFAULT = 0
    const DRAW_MODE_CYLINDER = 2
    const DRAW_MODE_EDGES = 3
    const DRAW_MODE_SKY = 4
    const DRAW_MODE_BILLBOARD = 5
    /* eslint-enable no-unused-vars */


    import vertexShader from 'raw-loader!./vert.glsl';
    import fragmentShader from 'raw-loader!./frag.glsl';
    import perlinShader from 'raw-loader!./perlin.glsl';
    import commonShader from 'raw-loader!./common.glsl';

    import webgl from '../../utils/webgl';
    import * as glm from 'gl-matrix'
    import GLTFLoader from 'three-gltf-loader';

    export default {
        name: "WebGl",

        data() {
            return {
                canvasWidth: 512,
                canvasHeight: 512,
                state: null,
                gl: null
            }
        },
        methods: {
            enableVr() {
                webgl.loopVr(this.gl, this.state);
            },
        },
        mounted() {
            const canvas = document.querySelector('#glcanvas');
            const gl = canvas.getContext('webgl2', {xrCompatible: true});
            this.gl = gl;
            canvas.addEventListener("contextmenu", (event) => {
                event.preventDefault();
            });

            let fShader = fragmentShader.replace("//#PERLIN", perlinShader).replace("//#COMMON", commonShader);
            let vShader = vertexShader.replace("//#PERLIN", perlinShader).replace("//#COMMON", commonShader);

            const shaderProgram = webgl.initShaderProgram(gl, vShader, fShader);
            gl.useProgram(shaderProgram);
            const programInfo = webgl.getProgramInfo(gl, shaderProgram);

            let lightDirection = glm.vec3.fromValues(-1.0, -1.0, -1.0);
            glm.vec3.normalize(lightDirection, lightDirection);

            let mandalaMesh = null;
            let modelMesh = null;
            let spaceMesh = null;
            let cylinderMesh = webgl.getCylinderMesh(gl, webgl.loadTexture(gl, "models/pattern.png"));
            let flareTexture = webgl.loadTexture(gl, "models/flare.png");

            const loader = new GLTFLoader();
            //console.log(model);
            loader.load("models/ganesha.gltf", gltf => {
                modelMesh = webgl.getModel(gl, gltf);
            });
            loader.load("models/space.gltf", gltf => {
                spaceMesh = webgl.getModel(gl, gltf);
            });

            let billboardMesh2 = webgl.createBillboard(gl);

            loader.load("models/mandala.gltf", gltf => {
                mandalaMesh = webgl.getModel(gl, gltf);
            });

            // eslint-disable-next-line no-unused-vars
            function update(gl, state) {

            }

            // eslint-disable-next-line no-unused-vars
            function clean(gl, framebuffer) {
                gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
                gl.clearColor(0.0, 0.0, 0.0, 0.0);
                gl.enable(gl.DEPTH_TEST);
                gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
            }

            // eslint-disable-next-line no-unused-vars
            function draw(gl, viewport, state, viewMatrix, projectionMatrix, mainFramebuffer, index) {
                webgl.enableAttribs(gl, programInfo);
                // viewport for extra framebuffers (not for the main one)
                gl.viewport(0, 0, viewport.width, viewport.height);

                let map = state.map[index];
                if (!map) {
                    map = {};
                }
                let drawFrameBuffer = map.drawFrameBuffer;
                let maskFrameBuffer = map.maskFrameBuffer;
                let mixFrameBuffer = map.mixFrameBuffer;

                if (drawFrameBuffer == null || drawFrameBuffer.width !== viewport.width || drawFrameBuffer.height !== viewport.height) {
                    if (drawFrameBuffer != null) {
                        webgl.deleteFramebuffer(gl, drawFrameBuffer);
                        webgl.deleteFramebuffer(gl, maskFrameBuffer);
                        webgl.deleteFramebuffer(gl, mixFrameBuffer);
                    }
                    drawFrameBuffer = webgl.createFramebuffer(gl, viewport.width, viewport.height);
                    maskFrameBuffer = webgl.createFramebuffer(gl, viewport.width, viewport.height);
                    mixFrameBuffer = webgl.createFramebuffer(gl, viewport.width, viewport.height);
                }
                clean(gl, drawFrameBuffer.frame);
                clean(gl, maskFrameBuffer.frame);
                clean(gl, mixFrameBuffer.frame);

                state.map[index] = {
                    drawFrameBuffer: drawFrameBuffer,
                    maskFrameBuffer: maskFrameBuffer,
                    mixFrameBuffer: mixFrameBuffer
                };

                gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);

                gl.uniform1f(programInfo.uniformLocations.time, state.time);
                gl.uniform3fv(programInfo.uniformLocations.lightDirection, lightDirection);
                gl.uniform2f(programInfo.uniformLocations.canvasSize, viewport.width, viewport.height);

                gl.enable(gl.BLEND);
                gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
                let variant = 0;

                if (viewMatrix == null) {
                    viewMatrix = glm.mat4.create();
                    let center = glm.vec3.fromValues(0, -2, -5);
                    let up = glm.vec3.fromValues(0, 1, 0);
                    let eye = glm.vec3.fromValues(-5 * Math.sin(state.time), 3, -5 * Math.cos(state.time) - 5);
                    glm.mat4.lookAt(viewMatrix, eye, center, up);
                }
                if (projectionMatrix == null) {
                    projectionMatrix = glm.mat4.create();
                    glm.mat4.perspective(projectionMatrix, 90 * Math.PI / 180, gl.canvas.clientWidth / gl.canvas.clientHeight, 0.1, 1000.0);
                }
                gl.uniformMatrix4fv(programInfo.uniformLocations.viewMatrix, false, viewMatrix);
                gl.uniformMatrix4fv(programInfo.uniformLocations.projectionMatrix, false, projectionMatrix);

                let invertedViewMatrix = glm.mat4.invert(glm.mat4.create(), viewMatrix);
                let cameraPosition = glm.vec3.fromValues(invertedViewMatrix[12], invertedViewMatrix[13], invertedViewMatrix[14]);
                gl.uniform3fv(programInfo.uniformLocations.cameraPosition, cameraPosition);

                let modelMatrix = glm.mat4.create();


                // **********
                // Draw space
                // **********
                if(spaceMesh) {
                    glm.mat4.identity(modelMatrix);
                    glm.mat4.scale(modelMatrix, modelMatrix, glm.vec3.fromValues(400, 400, 400));
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_SKY);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);
                    for (let mesh of spaceMesh) {
                        webgl.drawMesh(gl, programInfo, mesh);
                    }
                }

                // **************
                // Draw billboard
                // **************
                {
                    //let up = glm.vec3.fromValues(viewMatrix[4], viewMatrix[5] ,viewMatrix[6]);
                    let up = glm.vec3.fromValues(0, 1, 0);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_BILLBOARD);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);
                    variant = 0;
                    for (let i = 0; i < 2.0 * Math.PI; i += Math.PI / 8.0) {
                        let r = 32.0;
                        let position = glm.vec3.fromValues(r * Math.cos(i), 8 * Math.sin(state.time + variant), r * Math.sin(i));
                        let modelMatrix2 = webgl.getBillboardMatrix(position, cameraPosition, up);
                        glm.mat4.scale(modelMatrix2, modelMatrix2, glm.vec3.fromValues(2, 2, 2));

                        gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix2);
                        gl.uniform1f(programInfo.uniformLocations.drawVariant, ++variant * 4.0);
                        webgl.drawMesh(gl, programInfo, billboardMesh2, flareTexture);
                    }
                }

                // *************
                // Draw cylinder
                // *************
                {
                    gl.enable(gl.DEPTH_TEST);
                    gl.enable(gl.CULL_FACE);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_CYLINDER);
                    let cylinderDistance = 20;

                    variant = 0;
                    for (let i = Math.PI / 3.0; i < 2 * Math.PI - 0.001; i += 2.0 * Math.PI / 3.0) {
                        glm.mat4.identity(modelMatrix);
                        glm.mat4.translate(modelMatrix, modelMatrix, glm.vec3.fromValues(-cylinderDistance * Math.sin(i), -128, -cylinderDistance * Math.cos(i) - 5));
                        glm.mat4.scale(modelMatrix, modelMatrix, glm.vec3.fromValues(4, 4, 4));
                        gl.uniform1f(programInfo.uniformLocations.drawVariant, ++variant * 4.0);
                        gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                        webgl.drawMesh(gl, programInfo, cylinderMesh);
                    }
                }


                // ************
                // Draw mandala
                // ************
                if(mandalaMesh) {
                    glm.mat4.identity(modelMatrix);
                    glm.mat4.translate(modelMatrix, modelMatrix, glm.vec3.fromValues(0, -4.2, -5));
                    glm.mat4.scale(modelMatrix, modelMatrix, glm.vec3.fromValues(8, 8, 8));
                    glm.mat4.rotateY(modelMatrix, modelMatrix, -state.time * 0.1);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_DEFAULT);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.enable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);
                    for (let mesh of mandalaMesh) {
                        webgl.drawMesh(gl, programInfo, mesh);
                    }
                }

                // ***************
                // Draw model mask
                // ***************
                if(modelMesh) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, maskFrameBuffer.frame);

                    glm.mat4.identity(modelMatrix);
                    glm.mat4.translate(modelMatrix, modelMatrix, glm.vec3.fromValues(0, -2, -5));
                    glm.mat4.rotateY(modelMatrix, modelMatrix, Math.PI / 2.0 - state.time * 0.1);

                    gl.enable(gl.DEPTH_TEST);
                    gl.enable(gl.CULL_FACE);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 1);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_MASK);

                    for (let mesh of modelMesh) {
                        webgl.drawMesh(gl, programInfo, mesh);
                    }
                }

                // ****************
                // DRAW MIXBUFFER 1
                // ****************
                {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, mixFrameBuffer.frame);

                    let viewMatrix2 = glm.mat4.ortho(glm.mat4.create(), -1, 1, -1, 1, -1.0, 1.0);
                    let modelMatrix2 = glm.mat4.create();


                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D_MIX);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.viewMatrix, false, viewMatrix2);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix2);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    webgl.drawMesh(gl, programInfo, billboardMesh2, drawFrameBuffer.texture, maskFrameBuffer.texture);

                    // Reset
                    gl.uniformMatrix4fv(programInfo.uniformLocations.viewMatrix, false, viewMatrix);

                }

                // ***************
                // Draw model mesh
                // ***************
                if(modelMesh) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);

                    glm.mat4.identity(modelMatrix);
                    glm.mat4.translate(modelMatrix, modelMatrix, glm.vec3.fromValues(0, -2, -5));
                    glm.mat4.rotateY(modelMatrix, modelMatrix, Math.PI / 2.0 - state.time * 0.1);

                    gl.enable(gl.DEPTH_TEST);
                    gl.enable(gl.CULL_FACE);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 1);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_EDGES);
                    for (let mesh of modelMesh) {
                        webgl.drawMesh(gl, programInfo, mesh);
                    }
                }

                // ****************
                // DRAW MIXBUFFER 2
                // ****************
                {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);

                    let viewMatrix2 = glm.mat4.ortho(glm.mat4.create(), -1, 1, -1, 1, -1.0, 1.0);
                    let modelMatrix2 = glm.mat4.create();

                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.viewMatrix, false, viewMatrix2);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix2);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    webgl.drawMesh(gl, programInfo, billboardMesh2, mixFrameBuffer.texture);

                    // Reset
                    gl.uniformMatrix4fv(programInfo.uniformLocations.viewMatrix, false, viewMatrix);
                }

                // ****************
                // DRAW FRAMEBUFFER
                // ****************
                {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, mainFramebuffer);
                    // viewport for main framebuffer
                    gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height);

                    let viewMatrix2 = glm.mat4.ortho(glm.mat4.create(), -1, 1, -1, 1, -1.0, 1.0);
                    let modelMatrix2 = glm.mat4.create();

                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.viewMatrix, false, viewMatrix2);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix2);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    webgl.drawMesh(gl, programInfo, billboardMesh2, drawFrameBuffer.texture);
                }
            }


            this.state = webgl.createState(clean, draw, update);
            webgl.loop(this.gl, this.state);

        },
    }
</script>

<style scoped>

    button {
        padding: 10px;
    }
</style>