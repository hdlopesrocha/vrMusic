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


            const programInfo = {
                program: shaderProgram,
                attribLocations: {
                    vertexPosition: gl.getAttribLocation(shaderProgram, 'aVertexPosition'),
                },
                uniformLocations: {
                    projectionMatrix: gl.getUniformLocation(shaderProgram, 'uProjectionMatrix'),
                    modelViewMatrix: gl.getUniformLocation(shaderProgram, 'uModelViewMatrix'),
                },
            };



            const fieldOfView = 45 * Math.PI / 180;   // in radians
            const aspect = gl.canvas.clientWidth / gl.canvas.clientHeight;
            const zNear = 0.1;
            const zFar = 100.0;


            glm.mat4.perspective(this.projectionMatrix,
                fieldOfView,
                aspect,
                zNear,
                zFar);

            let then = 0;

            let vertices = [
                0,0,0,
                0,0,1,
                0,1,0,
                0,1,1,
                1,0,0,
                1,0,1,
                1,1,0,
                1,1,1,
            ];

            let vertex_buffer = gl.createBuffer();
            gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
            gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
            gl.bindBuffer(gl.ARRAY_BUFFER, null);
            let that = this;
            let modelViewMatrix = glm.mat4.create();


            // eslint-disable-next-line no-unused-vars
            function drawScene(gl, programInfo, deltaTime, now) {
                cleanScene(gl);

                let distance = 5;
                let center = glm.vec3.fromValues(0.5,0.5,0.5);
                let up = glm.vec3.fromValues(0,0,1);
                let eye = glm.vec3.fromValues(distance * Math.sin(now), distance * Math.cos(now) , distance);
                glm.mat4.lookAt(that.viewMatrix, eye, center, up);


                glm.mat4.multiply(modelViewMatrix, that.viewMatrix, that.modelMatrix);
                gl.uniformMatrix4fv(programInfo.uniformLocations.projectionMatrix, false, that.projectionMatrix);
                gl.uniformMatrix4fv(programInfo.uniformLocations.modelViewMatrix, false, modelViewMatrix);

                console.log(that.projectionMatrix);

                gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
                gl.vertexAttribPointer(programInfo.attribLocations.vertexPosition, 3, gl.FLOAT, false, 0, 0);
                gl.enableVertexAttribArray(programInfo.attribLocations.vertexPosition);

                gl.drawArrays(gl.POINTS, 0, vertices.length/3);

            }

            function cleanScene(gl) {
                gl.clearColor(0, 0, 0, 1.0);
                gl.enable(gl.DEPTH_TEST);
                gl.clear(gl.COLOR_BUFFER_BIT);
                gl.viewport(0,0,canvas.width,canvas.height);
            }

            function render(now) {
                now *= 0.001;  // convert to seconds
                const deltaTime = now - then;
                then = now;
                drawScene(gl, programInfo, deltaTime, now);
                requestAnimationFrame(render);
            }
            requestAnimationFrame(render);
        },
    }
</script>

<style scoped>
    canvas {
        width: 100%;
    }
</style>