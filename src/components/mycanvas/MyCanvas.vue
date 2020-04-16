<template>
    <div>
        <canvas v-bind:width="canvasWidth" v-bind:height="canvasHeight" id="glcanvas"></canvas>
        <br>
        <button v-on:click="enableVr">VR</button>
    </div>
</template>

<script>
    import vertexShader from 'raw-loader!./vert.glsl';
    import fragmentShader from 'raw-loader!./frag.glsl';
    import perlinShader from 'raw-loader!./perlin.glsl';

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

            let fShader = fragmentShader.replace("//#PERLIN", perlinShader);
            console.log(fShader);

            const shaderProgram = webgl.initShaderProgram(gl, vertexShader, fShader);
            gl.useProgram(shaderProgram);
            const programInfo = webgl.getProgramInfo(gl, shaderProgram);


            let monkeyMesh = [];
            let spaceMesh = [];
            let billboardMesh = [];

            const loader = new GLTFLoader();
            //console.log(model);
            loader.load("models/monkey.gltf", gltf => {
                let group = [];
                for (let c of gltf.scene.children) {
                    group.push(webgl.getMesh(gl, c));
                }
                monkeyMesh.push(group);
            });
            loader.load("models/space.gltf", gltf => {
                let group = [];
                for (let c of gltf.scene.children) {
                    group.push(webgl.getMesh(gl, c));
                }
                spaceMesh.push(group);
            });
            loader.load("models/billboard.gltf", gltf => {
                let group = [];
                for (let c of gltf.scene.children) {
                    group.push(webgl.getMesh(gl, c));
                }
                billboardMesh.push(group);
            });

            // eslint-disable-next-line no-unused-vars
            function update(gl, state) {

            }

            // eslint-disable-next-line no-unused-vars
            function draw(gl, state, viewMatrix, projectionMatrix) {
                gl.uniform1f(programInfo.uniformLocations.time, state.time);
                gl.enable(gl.BLEND);
                gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

                if (viewMatrix == null) {
                    viewMatrix = glm.mat4.create();
                    let center = glm.vec3.fromValues(0, 0, -1);
                    let up = glm.vec3.fromValues(0, 1, 0);
                    let eye = glm.vec3.fromValues(0, 0, 0);
                    glm.mat4.lookAt(viewMatrix, eye, center, up);
                }
                if (projectionMatrix == null) {
                    projectionMatrix = glm.mat4.create();
                    glm.mat4.perspective(projectionMatrix, 45 * Math.PI / 180, gl.canvas.clientWidth / gl.canvas.clientHeight, 0.1, 1000.0);
                }
                gl.uniformMatrix4fv(programInfo.uniformLocations.viewMatrix, false, viewMatrix);
                gl.uniformMatrix4fv(programInfo.uniformLocations.projectionMatrix, false, projectionMatrix);

                let modelMatrix = glm.mat4.create();
                // eslint-disable-next-line no-unused-vars
                let rotation = glm.quat.create();

                // **********
                // Draw space
                // **********
                glm.mat4.identity(modelMatrix);
                glm.mat4.scale(modelMatrix, modelMatrix, glm.vec3.fromValues(400, 400, 400));
                gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                gl.uniform1i(programInfo.uniformLocations.drawMode, 0);
                gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                gl.disable(gl.DEPTH_TEST);
                gl.disable(gl.CULL_FACE);
                for (let model of spaceMesh) {
                    for (let mesh of model) {
                        webgl.drawMesh(gl, programInfo, mesh);
                    }
                }

                // **********
                // Draw model
                // **********
                glm.mat4.identity(modelMatrix);
                glm.mat4.translate(modelMatrix, modelMatrix, glm.vec3.fromValues(-2, 0, -7));
                glm.mat4.rotateY(modelMatrix, modelMatrix, state.time);
                gl.uniform1i(programInfo.uniformLocations.enableLight, 1);
                gl.uniform1i(programInfo.uniformLocations.drawMode, 0);

                gl.enable(gl.DEPTH_TEST);
                gl.enable(gl.CULL_FACE);

                gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                for (let model of monkeyMesh) {
                    for (let mesh of model) {
                        webgl.drawMesh(gl, programInfo, mesh);
                    }
                }


                // **************
                // Draw billboard
                // **************
                let position = glm.vec3.fromValues(0, 0, -5);
                let up = glm.vec3.fromValues(0, 1, 0);
                // let up = glm.vec3.fromValues(viewMatrix[4], viewMatrix[5] ,viewMatrix[6]);
                let eye = glm.vec3.fromValues(viewMatrix[12], viewMatrix[13], viewMatrix[14]);
                let modelMatrix2 = webgl.getBillboardMatrix(position, eye, up);

                gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                gl.uniform1i(programInfo.uniformLocations.drawMode, 1);
                gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix2);
                gl.enable(gl.DEPTH_TEST);
                gl.disable(gl.CULL_FACE);
                for (let model of billboardMesh) {
                    for (let mesh of model) {
                        webgl.drawMesh(gl, programInfo, mesh);
                    }
                }

            }

            // eslint-disable-next-line no-unused-vars
            function clean(gl, state) {
                gl.clearColor(0.1, 0.1, 0.1, 1.0);
                gl.enable(gl.DEPTH_TEST);
                gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
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