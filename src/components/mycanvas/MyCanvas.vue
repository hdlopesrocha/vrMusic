<template>
    <div>
        <canvas v-bind:width="canvasWidth" v-bind:height="canvasHeight" id="glcanvas"></canvas>
        <br><button v-on:click="enableVr">VR</button>
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
                canvasWidth: 800,
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
            const gl = canvas.getContext('webgl',  { xrCompatible: true });
            this.gl = gl;
            canvas.addEventListener("contextmenu", (event) => { event.preventDefault(); });


            const shaderProgram = webgl.initShaderProgram(gl, vertexShader, fragmentShader);
            gl.useProgram(shaderProgram);
            const programInfo = webgl.getProgramInfo(gl, shaderProgram);


            let models = [];

            const loader = new GLTFLoader();
            //console.log(model);
            loader.parse(model, "",  gltf  => {
                console.log(gltf);
                let group = [];
                for (let c of gltf.scene.children) {
                    group.push(webgl.getMesh(gl, c));
                }
                models.push(group);
            });


            // eslint-disable-next-line no-unused-vars
            function update(gl, state) {
                let viewMatrix = glm.mat4.create();
                let modelMatrix = glm.mat4.create();
                let projectionMatrix = glm.mat4.create();
                let center = glm.vec3.fromValues(0, 0, -1);
                let up = glm.vec3.fromValues(0, 1, 0);
                let eye = glm.vec3.fromValues(0 , 0, 0);
                glm.mat4.lookAt(viewMatrix, eye, center, up);
                glm.mat4.perspective(projectionMatrix, 45 * Math.PI / 180, gl.canvas.clientWidth / gl.canvas.clientHeight, 0.1, 1000.0);

                glm.mat4.identity(modelMatrix);
                glm.mat4.translate(modelMatrix, modelMatrix, glm.vec3.fromValues(0, 0 ,-5));
                glm.mat4.rotateY(modelMatrix, modelMatrix, state.time);

                gl.uniformMatrix4fv(programInfo.uniformLocations.projectionMatrix, false, projectionMatrix);
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