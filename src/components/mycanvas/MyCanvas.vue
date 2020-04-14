<template>
    <div>
        <canvas v-bind:width="canvasWidth" v-bind:height="canvasHeight" id="glcanvas"></canvas>
        <button v-on:click="enableVr">VR</button>
    </div>
</template>

<script>
    import vertexShader from 'raw-loader!./shader.vert';
    import fragmentShader from 'raw-loader!./shader.frag';
    import model from 'raw-loader!../../assets/models/monkey.gltf';

    import webgl from '../../utils/webgl';
    import * as glm from 'gl-matrix'
    import GLTFLoader from 'three-gltf-loader';


    export default {
        name: "WebGl",

        data() {
            return {
                canvasWidth: 1920,
                canvasHeight: 800,
                projectionMatrix: glm.mat4.create(),
                viewMatrix: glm.mat4.create(),
                worldMatrix: glm.mat4.create(),
                modelMatrix: glm.mat4.create(),
                state: webgl.createState
            }
        },
        methods: {
            enableVr() {
                webgl.enableVr(this.state);
            }
        },
        mounted() {
            const canvas = document.querySelector('#glcanvas');
            const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
            const shaderProgram = webgl.initShaderProgram(gl, vertexShader, fragmentShader);
            gl.useProgram(shaderProgram);
            const programInfo = webgl.getProgramInfo(gl, shaderProgram);

            glm.mat4.perspective(this.projectionMatrix, 45 * Math.PI / 180, gl.canvas.clientWidth / gl.canvas.clientHeight, 0.1, 100.0);

            let models = [];

            const loader = new GLTFLoader();
            //console.log(model);
            loader.parse(model, "",
                ( gltf ) => {
                    let group = [];
                    for(let c of gltf.scene.children) {
                        group.push(webgl.getMesh(gl, c.geometry));
                    }
                    models.push(group);
                }
            );


            let that = this;
            let viewMatrix = glm.mat4.create();
            let modelMatrix = glm.mat4.create();


            // eslint-disable-next-line no-unused-vars
            function update(gl, state) {
                let distance = 2;
                let center = glm.vec3.fromValues(0, 0, 0);
                let up = glm.vec3.fromValues(0, 1, 0);
                let eye = glm.vec3.fromValues(0 , 0, distance);
                glm.mat4.lookAt(that.viewMatrix, eye, center, up);
                glm.mat4.multiply(viewMatrix, that.viewMatrix, that.modelMatrix);

                glm.mat4.identity(modelMatrix);
                glm.mat4.translate(modelMatrix, modelMatrix, glm.vec3.fromValues(0, 0 ,-1.5));
                glm.mat4.rotateY(modelMatrix, modelMatrix, state.time);

                gl.uniformMatrix4fv(programInfo.uniformLocations.projectionMatrix, false, that.projectionMatrix);
                gl.uniformMatrix4fv(programInfo.uniformLocations.viewMatrix, false, viewMatrix);
                gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
            }

            // eslint-disable-next-line no-unused-vars
            function draw(gl, state, viewMatrix, projectionMatrix) {
                if(viewMatrix != null) {
                    gl.uniformMatrix4fv(programInfo.uniformLocations.viewMatrix, false, viewMatrix);
                }
                if(projectionMatrix != null) {
                    gl.uniformMatrix4fv(programInfo.uniformLocations.projectionMatrix, false, projectionMatrix);
                }


                for(let model of models) {
                    for(let mesh of model) {
                        webgl.drawMesh(gl, programInfo, mesh);
                    }
                }
            }

            function clean(gl) {
                gl.clearColor(0.1, 0.1, 0.1, 1.0);
                gl.enable(gl.DEPTH_TEST);
                gl.clear(gl.COLOR_BUFFER_BIT);
            }

            webgl.loop(gl, this.state, canvas, clean, draw, update);
        },
    }
</script>

<style scoped>
    canvas {
        width: 100%;
    }
    button {
        padding: 10px;
    }
</style>