<template>
    <canvas width="1920" height="1080" id="glcanvas"></canvas>
</template>

<script>
    import vertexShader from 'raw-loader!./shader.vert';
    import fragmentShader from 'raw-loader!./shader.frag';
    import webgl from '../../utils/webgl';


    export default {
        name: "WebGl",
        mounted() {
            const canvas = document.querySelector('#glcanvas');
            const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
            const shaderProgram = webgl.initShaderProgram(gl, vertexShader, fragmentShader);

            const programInfo = {
                program: shaderProgram,
                attribLocations: {
                    vertexPosition: gl.getAttribLocation(shaderProgram, 'aVertexPosition'),
                    vertexColor: gl.getAttribLocation(shaderProgram, 'aVertexColor'),
                },
                uniformLocations: {
                    projectionMatrix: gl.getUniformLocation(shaderProgram, 'uProjectionMatrix'),
                    modelViewMatrix: gl.getUniformLocation(shaderProgram, 'uModelViewMatrix'),
                },
            };
            let then = 0;

            // eslint-disable-next-line no-unused-vars
            function drawScene(gl, programInfo, deltaTime) {

            }

            function render(now) {
                now *= 0.001;  // convert to seconds
                const deltaTime = now - then;
                then = now;
                drawScene(gl, programInfo, deltaTime);
                requestAnimationFrame(render);
            }
            requestAnimationFrame(render);

            console.log(programInfo);
        },
    }
</script>

<style scoped>

</style>