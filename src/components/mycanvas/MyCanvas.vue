<template>
    <div>
        <canvas v-bind:width="canvasWidth" v-bind:height="canvasHeight" id="glcanvas"></canvas>

        <table>
            <tr>
                <td>Step 1:</td>
                <td>
                    <button v-on:click="pickFile" >File</button>
                    or
                    <button v-on:click="enableMic">Mic</button>
                </td>
            </tr>
            <tr>
                <td>Step 2:</td>
                <td>
                    <button v-on:click="enableVr" >Enter VR</button>
                </td>
            </tr>
        </table>
        <input id="file" ref="file" style="display: none" v-on:change="enableMusic" type="file" name="file" accept="audio/*">
    </div>
</template>

<script>
    /* eslint-disable no-unused-vars */
    const DRAW_MODE_2D_BLUR = -4
    const DRAW_MODE_2D_MIX = -3
    const DRAW_MODE_2D = -2
    const DRAW_MODE_MASK = -1
    const DRAW_MODE_DEFAULT = 0
    const DRAW_MODE_SKY = 1
    const DRAW_MODE_CYLINDER = 2
    const DRAW_MODE_EDGES = 3
    const DRAW_MODE_NO_EDGES_MASK = 4
    const DRAW_MODE_BILLBOARD = 5
    const DRAW_MODE_TORUS = 6
    const DRAW_MODE_MANDALA = 7
    const DRAW_MODE_CUBE = 8

    /* eslint-enable no-unused-vars */


    import vertexShader from 'raw-loader!./vert.glsl';
    import fragmentShader from 'raw-loader!./frag.glsl';
    import perlinShader from 'raw-loader!./perlin.glsl';
    import hsl2rgbShader from 'raw-loader!./hsl2rgb.glsl';
    import commonShader from 'raw-loader!./common.glsl';

    import webGl from '../../utils/webGl'
    import webAudio from '../../utils/webAudio';
    import perlin from '../../utils/perlin';

    import * as glm from 'gl-matrix'
    import GLTFLoader from 'three-gltf-loader';
    export default {
        name: "WebGl",

        data() {
            return {
                canvasWidth: 512,
                canvasHeight: 512,
                state: null,
                gl: null,
                source: null,
                isPlaying: false,
                audioContext: null,
                analyser: null,
                freqArray: null,
                dataArray: null,
                timeDisplacement: 0,
                fftSize: 512
            }
        },
        methods: {
            enableVr() {
                webGl.toggleVR(this.gl, this.state);
            },
            enableMic() {
                function handleSound(stream) {
                    this.audioContext = new AudioContext();
                    this.analyser = this.audioContext.createAnalyser();
                    this.analyser.fftSize = this.fftSize;

                    this.source = this.audioContext.createMediaStreamSource(stream);
                    this.source.connect(this.analyser);
                    this.isPlaying = true;
                }
                if(!this.audioContext) {
                    navigator.getUserMedia = (navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia);
                    navigator.mediaDevices.getUserMedia({ audio: true, video: false }).then(handleSound.bind(this));
                }
            },
            pickFile(){
                this.$refs.file.click();
            },
            enableMusic(event){
                this.audioContext = new AudioContext();
                this.analyser = this.audioContext.createAnalyser();
                this.analyser.fftSize = this.fftSize;

                let file = event.target.files[0];
                if (file) {
                    var reader = new FileReader();
                    reader.readAsArrayBuffer(file);
                    reader.onload = function(e) {
                        let data = e.target.result;
                        this.audioContext.decodeAudioData(data, function(buffer) {
                            this.source = this.audioContext.createBufferSource();
                            this.source.buffer = buffer;
                            this.source.loop = true;
                            this.source.start(0);
                            this.source.connect(this.analyser);
                            this.analyser.connect(this.audioContext.destination);
                        }.bind(this));
                    }.bind(this);
                }

            }
        },
        mounted() {
            const canvas = document.querySelector('#glcanvas');
            const gl = canvas.getContext('webgl2', {xrCompatible: true});
            this.gl = gl;
            canvas.addEventListener("contextmenu", (event) => {
                event.preventDefault();
            });

            let fShader = fragmentShader
                .replace("//#PERLIN", perlinShader)
                .replace("//#COMMON", commonShader)
                .replace("//#HSL2RGB", hsl2rgbShader);
            let vShader = vertexShader
                .replace("//#PERLIN", perlinShader)
                .replace("//#COMMON", commonShader)
                .replace("//#HSL2RGB", hsl2rgbShader);


            const shaderProgram = webGl.initShaderProgram(gl, vShader, fShader);
            gl.useProgram(shaderProgram);
            const programInfo = webGl.getProgramInfo(gl, shaderProgram);

            let lightDirection = glm.vec3.fromValues(-1.0, -1.0, -1.0);
            glm.vec3.normalize(lightDirection, lightDirection);

            let orthoMatrix = glm.mat4.ortho(glm.mat4.create(), -1, 1, -1, 1, -1.0, 1.0);
            gl.uniformMatrix4fv(programInfo.uniformLocations.orthoMatrix, false, orthoMatrix);

            gl.enable(gl.BLEND);
            gl.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA);

            // *************
            // load textures
            // *************
            let pixel = webGl.loadTexture(gl, "textures/pixel.png");
            let patternTexture = webGl.loadTexture(gl, "textures/pattern.png");
            let cylinderMesh = webGl.getCylinderMesh(gl, patternTexture);
            let flareTexture = webGl.loadTexture(gl, "textures/flare.png");
            let mandalaTexture = webGl.loadTexture(gl, "textures/mandala.png");
            let mandalaMaskTexture = webGl.loadTexture(gl, "textures/mandala_mask.png");
            let billboardMesh = webGl.createBillboard(gl);

            // **********************
            // initialize audio state
            // **********************
            let audioTexture = gl.createTexture();
            this.freqArray = new Uint8Array(this.fftSize);
            this.dataArray = new Uint8Array(this.fftSize);
            webAudio.initializeArray(this.freqArray);
            webAudio.initializeArray(this.dataArray);
            webGl.initializeTexture(gl, audioTexture);

            perlin.noise.seed(Math.random());


            // ***********
            // load models
            // ***********
            let mandalaModel = null;
            let statueModel = null;
            let spaceModel = null;
            let torusModel = null;
            let cubeModel = null;

            const loader = new GLTFLoader();
            loader.load("models/ganesha.gltf", gltf => {
                statueModel = webGl.getModel(gl, gltf);
            });
            loader.load("models/space.gltf", gltf => {
                spaceModel = webGl.getModel(gl, gltf);
            });
            loader.load("models/mandala.gltf", gltf => {
                mandalaModel = webGl.getModel(gl, gltf);
            });
            loader.load("models/torus.gltf", gltf => {
                torusModel = webGl.getModel(gl, gltf);
            });
            loader.load("models/cube.gltf", gltf => {
                cubeModel = webGl.getModel(gl, gltf);
            });

            // ********
            // fun zone
            // ********

            // eslint-disable-next-line no-unused-vars
            function update(gl, state) {
                if(this.audioContext) {
                    if (this.analyser) {
                        this.analyser.getByteTimeDomainData(this.dataArray);
                        webGl.loadAudio(gl,audioTexture, this.fftSize, this.dataArray);
                        webGl.bindTexture(gl, programInfo.uniformLocations.audioSampler, 2, audioTexture);
                    }
                    this.timeDisplacement = 0.0;
                }
            }

            // eslint-disable-next-line no-unused-vars
            function clean(gl, framebuffer, color) {
                webGl.bindTexture(gl, programInfo.uniformLocations.sampler[0], 0, pixel);
                webGl.bindTexture(gl, programInfo.uniformLocations.sampler[1], 1, pixel);
                webGl.bindTexture(gl, programInfo.uniformLocations.audioSampler, 2, pixel);

                gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);

                gl.clearColor(color[0], color[1], color[2], color[3]);
                gl.enable(gl.DEPTH_TEST);
                gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
            }

            function createOrCleanFramebuffer(gl, viewport, framebuffer, color){
                if (framebuffer == null || framebuffer.width !== viewport.width || framebuffer.height !== viewport.height) {
                    if (framebuffer != null) {
                        webGl.deleteFramebuffer(gl, framebuffer);
                    }
                    framebuffer = webGl.createFramebuffer(gl, viewport.width, viewport.height, gl.RGBA);
                }
                clean(gl, framebuffer.frame, color);
                return framebuffer;
            }


            // eslint-disable-next-line no-unused-vars
            function draw(gl, viewport, state, viewMatrix, projectionMatrix, mainFramebuffer, index) {
                // viewport for extra framebuffers (not for the main one)
                gl.viewport(0, 0, viewport.width, viewport.height);
                webGl.enableAttribs(gl, programInfo);

                let map = state.map[index];
                if (!map) {
                    map = {};
                }
                let drawFrameBuffer = createOrCleanFramebuffer(gl, viewport, map.drawFrameBuffer, webGl.TRANSPARENT);
                let maskFrameBuffer = createOrCleanFramebuffer(gl, viewport, map.maskFrameBuffer, webGl.BLACK);
                let blurFrameBuffer = createOrCleanFramebuffer(gl, viewport, map.blurFrameBuffer, webGl.TRANSPARENT);
                let mixFrameBuffer = createOrCleanFramebuffer(gl, viewport, map.mixFrameBuffer, webGl.TRANSPARENT);
                let debug = true;

                state.map[index] = {
                    drawFrameBuffer: drawFrameBuffer,
                    maskFrameBuffer: maskFrameBuffer,
                    blurFrameBuffer: blurFrameBuffer,
                    mixFrameBuffer: mixFrameBuffer
                };


                gl.uniform1f(programInfo.uniformLocations.time, state.time+this.timeDisplacement);
                gl.uniform3fv(programInfo.uniformLocations.lightDirection, lightDirection);
                gl.uniform2f(programInfo.uniformLocations.canvasSize, viewport.width, viewport.height);

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
                let center = glm.vec3.fromValues(0,0,-6);

                // **********
                // Draw space
                // **********
                if(spaceModel) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);

                    glm.mat4.identity(modelMatrix);
                    glm.mat4.scale(modelMatrix, modelMatrix, glm.vec3.fromValues(400, 400, 400));
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_SKY);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);
                    for (let mesh of spaceModel) {
                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES);
                    }
                }

                // **********
                // Draw torus
                // **********
                if(torusModel) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);

                    let position = glm.vec3.fromValues(0, 0, 0);
                    glm.vec3.add(position, position, center);
                    glm.mat4.identity(modelMatrix);
                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.scale(modelMatrix, modelMatrix, glm.vec3.fromValues(32, 8.0, 32));
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_TORUS);
                    gl.enable(gl.DEPTH_TEST);
                    gl.enable(gl.CULL_FACE);

                    for (let mesh of torusModel) {
                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES);
                    }
                }

                // **********
                // Draw cubes
                // **********
                if(cubeModel) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);

                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_CUBE);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    let size = 1;
                    let distance = 64;
                    for(let i = -size; i <= size; ++i) {
                        for(let j = -size; j <= size; ++j) {
                            for(let k = -size; k <= size; ++k) {
                                if(Math.abs(i) === size || Math.abs(j) === size || Math.abs(k) === size) {
                                    let noise = (webAudio.myNoise3dx(perlin.noise, state.time+i, state.time+j , state.time+k, 4.0)*0.2+ 0.8*this.dataArray[0]/255);

                                    let position = glm.vec3.fromValues(i, j, k);
                                    let direction = glm.vec3.create();

                                    glm.vec3.normalize(direction, position);
                                    glm.vec3.scale(position,direction,distance - noise * distance);
                                    glm.vec3.add(position, position, center);
                                    glm.mat4.identity(modelMatrix);
                                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                                    glm.mat4.scale(modelMatrix, modelMatrix, glm.vec3.fromValues(1.0, 1.0, 1.0));
                                    glm.mat4.rotate(modelMatrix, modelMatrix, noise*Math.PI*2.0, direction);

                                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                                    for (let mesh of cubeModel) {
                                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES);
                                    }

                                }
                            }
                        }
                    }

                }

                // *************
                // Draw cylinder
                // *************
                {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);

                    gl.enable(gl.DEPTH_TEST);
                    gl.enable(gl.CULL_FACE);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_CYLINDER);
                    let cylinderDistance = 20;

                    variant = 0;
                    for (let i = Math.PI / 3.0; i < 2 * Math.PI - 0.001; i += 2.0 * Math.PI / 3.0) {
                        let position = glm.vec3.fromValues(-cylinderDistance * Math.sin(i), -128, -cylinderDistance * Math.cos(i));
                        glm.mat4.identity(modelMatrix);
                        glm.vec3.add(position, position, center);
                        glm.mat4.translate(modelMatrix, modelMatrix, position);
                        glm.mat4.scale(modelMatrix, modelMatrix, glm.vec3.fromValues(4, 4, 4));
                        gl.uniform1f(programInfo.uniformLocations.drawVariant, ++variant * 4.0);
                        gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                        webGl.drawMesh(gl, programInfo, cylinderMesh, gl.TRIANGLES);
                    }

                }

                // **************
                // Draw billboard
                // **************
                {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);

                    //let up = glm.vec3.fromValues(viewMatrix[4], viewMatrix[5] ,viewMatrix[6]);
                    let up = glm.vec3.fromValues(0, 1, 0);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_BILLBOARD);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);
                    variant = 0;
                    for (let i = 0; i < 2.0 * Math.PI; i += Math.PI / 8.0) {
                        let r = 4.0;
                        let position = glm.vec3.fromValues(r * Math.cos(i), 8.0+Math.sin(state.time*4.0 + i*2.0), r * Math.sin(i));
                        glm.vec3.add(position, position, center);

                        modelMatrix = webGl.getBillboardMatrix(position, cameraPosition, up);
                        glm.mat4.scale(modelMatrix, modelMatrix, glm.vec3.fromValues(2, 2, 2));

                        gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                        gl.uniform1f(programInfo.uniformLocations.drawVariant, ++variant * 4.0);
                        webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, flareTexture);
                    }
                }

                // ************
                // Draw mandala
                // ************
                if(mandalaModel) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);

                    let position = glm.vec3.fromValues(0, -2.2, 0);
                    glm.vec3.add(position, position, center);
                    glm.mat4.identity(modelMatrix);
                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.scale(modelMatrix, modelMatrix, glm.vec3.fromValues(8, 8, 8));
                    glm.mat4.rotateY(modelMatrix, modelMatrix, -state.time * 0.1);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_MANDALA);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.enable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);
                    for (let mesh of mandalaModel) {
                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES, mandalaTexture);
                    }
                }

                // *****************
                // Draw mandala mask
                // *****************
                if(mandalaModel) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, maskFrameBuffer.frame);

                    let position = glm.vec3.fromValues(0, -2.2, 0);
                    glm.vec3.add(position, position, center);
                    glm.mat4.identity(modelMatrix);
                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.scale(modelMatrix, modelMatrix, glm.vec3.fromValues(8, 8, 8));
                    glm.mat4.rotateY(modelMatrix, modelMatrix, -state.time * 0.1);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_MASK);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.enable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);
                    for (let mesh of mandalaModel) {
                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES, mandalaMaskTexture);
                    }
                }

                // ***************
                // Draw model mask
                // ***************
                if(statueModel) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, maskFrameBuffer.frame);

                    let position = glm.vec3.fromValues(0, 0, 0);
                    glm.vec3.add(position, position, center);
                    glm.mat4.identity(modelMatrix);
                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.rotateY(modelMatrix, modelMatrix, Math.PI / 2.0 - state.time * 0.1);

                    gl.enable(gl.DEPTH_TEST);
                    gl.enable(gl.CULL_FACE);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_NO_EDGES_MASK);

                    for (let mesh of statueModel) {
                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES);
                    }
                }

                // *********
                // DRAW BLUR
                // *********
                {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, blurFrameBuffer.frame);

                    glm.mat4.identity(modelMatrix);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D_BLUR);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, drawFrameBuffer.texture, maskFrameBuffer.texture);
                }

                // ****************
                // DRAW MIXBUFFER 1
                // ****************
                {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);

                    glm.mat4.identity(modelMatrix);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, blurFrameBuffer.texture);
                }

                // **********
                // Draw model
                // **********
                if(statueModel) {

                    let position = glm.vec3.fromValues(0, 0, 0);
                    glm.vec3.add(position, position, center);
                    glm.mat4.identity(modelMatrix);
                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.rotateY(modelMatrix, modelMatrix, Math.PI / 2.0 - state.time * 0.1);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                    gl.enable(gl.DEPTH_TEST);
                    gl.enable(gl.CULL_FACE);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 1);

                    gl.bindFramebuffer(gl.FRAMEBUFFER, mixFrameBuffer.frame);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_DEFAULT);
                    for (let mesh of statueModel) {
                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES);
                    }
                }


                // ****************
                // DRAW MIXBUFFER 2
                // ****************
                {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);

                    glm.mat4.identity(modelMatrix);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D_MIX);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, mixFrameBuffer.texture);
                }

                // ****************
                // Draw model edges
                // ****************
                if(statueModel) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);

                    let position = glm.vec3.fromValues(0, 0, 0);
                    glm.vec3.add(position, position, center);
                    glm.mat4.identity(modelMatrix);
                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.rotateY(modelMatrix, modelMatrix, Math.PI / 2.0 - state.time * 0.1);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                    gl.enable(gl.DEPTH_TEST);
                    gl.enable(gl.CULL_FACE);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 1);

                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_EDGES);
                    for (let mesh of statueModel) {
                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES);
                    }
                }

                // *****
                // DEBUG
                // *****
                if(debug && billboardMesh){
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);

                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D);
                    gl.enable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    let textures = [
                        audioTexture ,
                        maskFrameBuffer.texture,
                        blurFrameBuffer.texture,
                        mixFrameBuffer.texture
                    ];
                    let size = 0.1;





                    for(let i in textures) {
                        let texture = textures[i];
                        glm.mat4.identity(modelMatrix);
                        glm.mat4.translate(modelMatrix, modelMatrix, glm.vec3.fromValues(-1.0+(i*2+1)*size ,1.0-size,0.0));
                        glm.mat4.scale(modelMatrix, modelMatrix, glm.vec3.fromValues(size,size,1.0));
                        gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                        webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, texture);
                    }
                }
                // ****************
                // DRAW FRAMEBUFFER
                // ****************
                {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, mainFramebuffer);
                    // viewport for main framebuffer
                    gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height);

                    glm.mat4.identity(modelMatrix);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, drawFrameBuffer.texture);
                }
            }

            this.state = webGl.createState(
                clean.bind(this),
                draw.bind(this),
                update.bind(this)
            );
            webGl.loop(this.gl, this.state);

        },
    }
</script>

<style scoped>

    button {
        padding: 10px;
    }
</style>