<template>
    <div>
        <canvas v-bind:width="canvasWidth" v-bind:height="canvasHeight" id="glcanvas"></canvas>
        <br>
        <button v-on:click="enableVr">VR</button>
    </div>
</template>

<script>
    /* eslint-disable no-unused-vars */
    const DRAW_MODE_2D_MIX = -3
    const DRAW_MODE_2D = -2
    const DRAW_MODE_WHITE = -1
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
                canvasWidth: 600,
                canvasHeight: 600,
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

            let mandalaMesh = [];
            let modelMesh = [];
            let spaceMesh = [];
            let cylinderMesh = webgl.getCylinderMesh(gl, webgl.loadTexture(gl, "models/pattern.png"));
            let flareTexture = webgl.loadTexture(gl, "models/flare.png");

            let drawFrameBuffer = null;
            let maskFrameBuffer = null;
            let mixFrameBuffer = null;

            const loader = new GLTFLoader();
            //console.log(model);
            loader.load("models/ganesha.gltf", gltf => {
                console.log("loading G...");
                let group = [];
                for (let c of gltf.scene.children) {
                    let m = webgl.getMesh(gl, c);
                    if(m!=null) {
                        group.push(m);
                    }
                }
                modelMesh.push(group);
                console.log("loaded G!");
            });
            loader.load("models/space.gltf", gltf => {
                let group = [];
                for (let c of gltf.scene.children) {
                    let m = webgl.getMesh(gl, c);
                    if(m!=null) {
                        group.push(m);
                    }
                }
                spaceMesh.push(group);
            });

            let billboardMesh2 = webgl.createBillboard(gl);

            loader.load("models/mandala.gltf", gltf => {
                let group = [];
                for (let c of gltf.scene.children) {
                    let m = webgl.getMesh(gl, c);
                    if(m!=null) {
                        group.push(m);
                    }
                }
                mandalaMesh.push(group);
            });
            // eslint-disable-next-line no-unused-vars
            function update(gl, state) {

            }

            // eslint-disable-next-line no-unused-vars
            function clean(gl, state, framebuffer) {
                gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
                gl.clearColor(0.0, 0.0, 0.0, 0.0);
                gl.enable(gl.DEPTH_TEST);
                gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
            }

            // eslint-disable-next-line no-unused-vars
            function draw(gl, state, viewMatrix, projectionMatrix, framebuffer) {
                webgl.enableAttribs(gl, programInfo);
                if(drawFrameBuffer == null || drawFrameBuffer.width !== state.width || drawFrameBuffer.height !== state.height){
                    if(drawFrameBuffer != null){
                        webgl.deleteFramebuffer(gl, drawFrameBuffer);
                        webgl.deleteFramebuffer(gl, maskFrameBuffer);
                        webgl.deleteFramebuffer(gl, mixFrameBuffer);
                    }
                    drawFrameBuffer = webgl.createFramebuffer(gl, state.width, state.height);
                    maskFrameBuffer = webgl.createFramebuffer(gl, state.width, state.height);
                    mixFrameBuffer = webgl.createFramebuffer(gl, state.width, state.height);
                }
                clean(gl, state, drawFrameBuffer.frame);
                clean(gl, state, maskFrameBuffer.frame);
                clean(gl, state, mixFrameBuffer.frame);

                gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);

                gl.uniform1f(programInfo.uniformLocations.time, state.time);
                gl.uniform3fv(programInfo.uniformLocations.lightDirection, lightDirection);

                gl.enable(gl.BLEND);
                gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
                let variant = 0;

                if (viewMatrix == null) {
                    viewMatrix = glm.mat4.create();
                    let center = glm.vec3.fromValues(0, -2, -5);
                    let up = glm.vec3.fromValues(0, 1, 0);
                    let eye = glm.vec3.fromValues(-5*Math.sin(state.time), 3, -5*Math.cos(state.time)-5);
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
                glm.mat4.identity(modelMatrix);
                glm.mat4.scale(modelMatrix, modelMatrix, glm.vec3.fromValues(400, 400, 400));
                gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_SKY);
                gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                gl.disable(gl.DEPTH_TEST);
                gl.disable(gl.CULL_FACE);
                for (let model of spaceMesh) {
                    for (let mesh of model) {
                        webgl.drawMesh(gl, programInfo, mesh);
                    }
                }

                // **************
                // Draw billboard
                // **************

                //let up = glm.vec3.fromValues(viewMatrix[4], viewMatrix[5] ,viewMatrix[6]);
                let up = glm.vec3.fromValues(0, 1, 0);
                gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_BILLBOARD);
                gl.enable(gl.DEPTH_TEST);
                gl.disable(gl.CULL_FACE);
                variant = 0;
                for(let i = 0; i < 2.0*Math.PI; i+= Math.PI/8.0) {
                    let r = 32.0;
                    let position = glm.vec3.fromValues(r*Math.cos(i), 8*Math.sin(state.time+variant), r*Math.sin(i));
                    let modelMatrix2 = webgl.getBillboardMatrix(position, cameraPosition, up);
                    glm.mat4.scale(modelMatrix2, modelMatrix2, glm.vec3.fromValues(2, 2, 2));

                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix2);
                    gl.uniform1f(programInfo.uniformLocations.drawVariant, ++variant*4.0);
                    webgl.drawMesh(gl, programInfo, billboardMesh2, flareTexture);
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
                {
                    glm.mat4.identity(modelMatrix);
                    glm.mat4.translate(modelMatrix, modelMatrix, glm.vec3.fromValues(0, -4.2, -5));
                    glm.mat4.scale(modelMatrix, modelMatrix, glm.vec3.fromValues(8, 8, 8));
                    glm.mat4.rotateY(modelMatrix, modelMatrix, -state.time*0.1);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_DEFAULT);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.enable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);
                    for (let model of mandalaMesh) {
                        for (let mesh of model) {
                            webgl.drawMesh(gl, programInfo, mesh);
                        }
                    }
                }

                // ***************
                // Draw model mask
                // ***************
                {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, maskFrameBuffer.frame);

                    glm.mat4.identity(modelMatrix);
                    glm.mat4.translate(modelMatrix, modelMatrix, glm.vec3.fromValues(0, -2, -5));
                    glm.mat4.rotateY(modelMatrix, modelMatrix, Math.PI / 2.0 - state.time * 0.1);

                    gl.disable(gl.DEPTH_TEST);
                    gl.enable(gl.CULL_FACE);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                    gl.clearColor(0.0, 0.0, 0.0, 0.0);
                    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_WHITE);

                    for (let model of modelMesh) {
                        for (let mesh of model) {
                            webgl.drawMesh(gl, programInfo, mesh);
                        }
                    }
                }

                // ****************
                // DRAW MIXBUFFER 1
                // ****************
                {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, mixFrameBuffer.frame);

                    let viewMatrix2 = glm.mat4.create();
                    let modelMatrix2 = glm.mat4.create();
                    glm.mat4.translate(modelMatrix2, modelMatrix2, glm.vec3.fromValues(0, 0, -1));

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
                // ****************
                // DRAW MIXBUFFER 2
                // ****************
                {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);

                    let viewMatrix2 = glm.mat4.create();
                    let modelMatrix2 = glm.mat4.create();
                    glm.mat4.translate(modelMatrix2, modelMatrix2, glm.vec3.fromValues(0, 0, -1));

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
                // ***************
                // Draw model mesh
                // ***************
                {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);

                    glm.mat4.identity(modelMatrix);
                    glm.mat4.translate(modelMatrix, modelMatrix, glm.vec3.fromValues(0, -2, -5));
                    glm.mat4.rotateY(modelMatrix, modelMatrix, Math.PI / 2.0 - state.time * 0.1);

                    gl.disable(gl.DEPTH_TEST);
                    gl.enable(gl.CULL_FACE);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 1);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_EDGES);
                    for (let model of modelMesh) {
                        for (let mesh of model) {
                            webgl.drawMesh(gl, programInfo, mesh);
                        }
                    }
                }

                // ****************
                // DRAW FRAMEBUFFER
                // ****************
                {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);

                    let viewMatrix2 = glm.mat4.create();
                    let modelMatrix2 = glm.mat4.create();
                    glm.mat4.translate(modelMatrix2, modelMatrix2, glm.vec3.fromValues(0, 0, -1));

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