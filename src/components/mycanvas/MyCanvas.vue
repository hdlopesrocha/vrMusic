<template>
    <canvas v-bind:width="canvasWidth" v-bind:height="canvasHeight" id="glcanvas"></canvas>
</template>

<script>
    import vertexShader from 'raw-loader!./shader.vert';
    import fragmentShader from 'raw-loader!./shader.frag';
    import webgl from '../../utils/webgl';
    import * as glm from 'gl-matrix'


    export default {
        name: "WebGl",

        data() {
            return {
                canvasWidth: 1920,
                canvasHeight: 1080,
                projectionMatrix: glm.mat4.create(),
                viewMatrix: glm.mat4.create(),
                worldMatrix: glm.mat4.create(),
                modelMatrix: glm.mat4.create(),
            }
        },
        mounted() {
            const canvas = document.querySelector('#glcanvas');
            const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
            const shaderProgram = webgl.initShaderProgram(gl, vertexShader, fragmentShader);
            gl.useProgram(shaderProgram);
            const programInfo = webgl.getProgramInfo(gl, shaderProgram);

            const fieldOfView = 45 * Math.PI / 180;   // in radians
            const aspect = gl.canvas.clientWidth / gl.canvas.clientHeight;
            const zNear = 0.1;
            const zFar = 100.0;


            glm.mat4.perspective(this.projectionMatrix,
                fieldOfView,
                aspect,
                zNear,
                zFar);


            let vertices = [
                0,1,0,
                Math.sin((1.0/5)*2*Math.PI),0,Math.cos((1.0/5)*2*Math.PI),
                Math.sin((2.0/5)*2*Math.PI),0,Math.cos((2.0/5)*2*Math.PI),
                Math.sin((3.0/5)*2*Math.PI),0,Math.cos((3.0/5)*2*Math.PI),
                Math.sin((4.0/5)*2*Math.PI),0,Math.cos((4.0/5)*2*Math.PI),
                Math.sin((5.0/5)*2*Math.PI),0,Math.cos((5.0/5)*2*Math.PI),
                0,-1,0,
            ];

            const indices = [
                0,  1,  2,
                0,  2,  3,
                0,  3,  4,
                0,  4,  5,
                0,  5,  1,

                6,  1,  2,
                6,  2,  3,
                6,  3,  4,
                6,  4,  5,
                6,  5,  1,
            ];

            let vertex_buffer = gl.createBuffer();
            gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
            gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);

            let index_buffer = gl.createBuffer();
            gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, index_buffer);
            gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(indices), gl.STATIC_DRAW);

            gl.bindBuffer(gl.ARRAY_BUFFER, null);

            let that = this;
            let modelViewMatrix = glm.mat4.create();

            function update(gl, state) {
                let distance = 5;
                let center = glm.vec3.fromValues(0,0,0);
                let up = glm.vec3.fromValues(0,1,0);
                let eye = glm.vec3.fromValues(distance * Math.sin(state.time), distance, distance * Math.cos(state.time) );
                glm.mat4.lookAt(that.viewMatrix, eye, center, up);

                glm.mat4.multiply(modelViewMatrix, that.viewMatrix, that.modelMatrix);
                gl.uniformMatrix4fv(programInfo.uniformLocations.projectionMatrix, false, that.projectionMatrix);
                gl.uniformMatrix4fv(programInfo.uniformLocations.modelViewMatrix, false, modelViewMatrix);
            }

            // eslint-disable-next-line no-unused-vars
            function draw(gl, state) {
                cleanScene(gl);

                gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
                gl.vertexAttribPointer(programInfo.attribLocations.vertexPosition, 3, gl.FLOAT, false, 0, 0);
                gl.enableVertexAttribArray(programInfo.attribLocations.vertexPosition);

                gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, index_buffer);

                gl.drawElements(gl.LINES, indices.length, gl.UNSIGNED_SHORT, 0);
            }

            function cleanScene(gl) {
                gl.clearColor(0, 0, 0, 1.0);
                gl.enable(gl.DEPTH_TEST);
                gl.clear(gl.COLOR_BUFFER_BIT);
                gl.viewport(0,0,canvas.width,canvas.height);
            }

            webgl.loop(gl, draw, update);
        },
    }
</script>

<style scoped>
    canvas {
        width: 100%;
    }
</style>