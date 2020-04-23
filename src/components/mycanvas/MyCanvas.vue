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
    const DEBUG = false;
    // 2D MODES
    const DRAW_MODE_2D_NORMAL= -9
    const DRAW_MODE_2D_WATER = -8
    const DRAW_MODE_2D_SHIFT = -7
    const DRAW_MODE_2D_RADIAL = -6
    const DRAW_MODE_2D_LENS = -5
    const DRAW_MODE_2D_BLUR = -4
    const DRAW_MODE_2D_MIX = -3
    const DRAW_MODE_2D = -2

    // 3D MODES
    const DRAW_MODE_3D_MASK = -1
    const DRAW_MODE_3D_DEFAULT = 0
    const DRAW_MODE_3D_SKY = 1
    const DRAW_MODE_3D_CYLINDER = 2
    const DRAW_MODE_3D_EDGES = 3
    const DRAW_MODE_3D_NO_EDGES_MASK = 4
    const DRAW_MODE_3D_BILLBOARD = 5
    const DRAW_MODE_3D_TORUS = 6
    const DRAW_MODE_3D_MANDALA = 7
    const DRAW_MODE_3D_CUBE = 8
    const DRAW_MODE_3D_SPHERICAL_GRID = 9
    const DRAW_MODE_3D_HEXA_GRID = 10
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
            let hexaSphereTexture = webGl.loadTexture(gl, "textures/hexa_texture.png");
            let hexaMaskTexture = webGl.loadTexture(gl, "textures/hexa_mask.png");
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
            let sphereModel = null;
            let hexaModel = null;

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
            loader.load("models/sphere.gltf", gltf => {
                sphereModel = webGl.getModel(gl, gltf);
            });
            loader.load("models/hexa.gltf", gltf => {
                hexaModel = webGl.getModel(gl, gltf);
            });
            // *******************
            // temporary variables
            // *******************
            let TEMP_UP = glm.vec3.create();
            let TEMP_EYE = glm.vec3.create();
            let TEMP_CENTER = glm.vec3.create();
            let TEMP_POSITION = glm.vec3.create();
            let TEMP_SCALE = glm.vec3.create();
            let TEMP_DIRECTION = glm.vec3.create();
            let TEMP_VIEW = glm.mat4.create();
            let TEMP_MODEL = glm.mat4.create();
            let cameraPosition = glm.vec3.create();
            let modelPosition = glm.vec3.fromValues(0,0,-6);


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
                gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
                gl.clearColor(color[0], color[1], color[2], color[3]);
                gl.enable(gl.DEPTH_TEST);
                gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
            }

            function createOrCleanFramebuffer(gl, width, height, framebuffer, color, format){
                if (!framebuffer || framebuffer.width !== width || framebuffer.height !== height) {
                    if (framebuffer != null) {
                        webGl.deleteFramebuffer(gl, framebuffer);
                    }
                    framebuffer = webGl.createFramebuffer(gl, width, height, format);
                }
                gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer.frame);
                gl.clearColor(color[0], color[1], color[2], color[3]);
                gl.enable(gl.DEPTH_TEST);
                gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

                webGl.bindTexture(gl, programInfo.uniformLocations.sampler[0], 0, pixel);
                webGl.bindTexture(gl, programInfo.uniformLocations.sampler[1], 1, pixel);
                webGl.bindTexture(gl, programInfo.uniformLocations.audioSampler, 2, audioTexture);

                return framebuffer;
            }


            // eslint-disable-next-line no-unused-vars
            function draw(gl, viewport, state, viewMatrix, projectionMatrix, mainFramebuffer, index) {
                // viewport for extra framebuffers (not for the main one)
                gl.viewport(0, 0, viewport.width, viewport.height);
                webGl.enableAttribs(gl, programInfo);

                let map = state.map || {};

                let drawFrameBuffer = createOrCleanFramebuffer(gl, viewport.width, viewport.height, map.drawFrameBuffer, webGl.TRANSPARENT,  gl.RGBA);
                let maskFrameBuffer = createOrCleanFramebuffer(gl, viewport.width, viewport.height, map.maskFrameBuffer, webGl.BLACK,  gl.RGBA);
                let normalMaskFrameBuffer = createOrCleanFramebuffer(gl, viewport.width, viewport.height, map.normalMaskFrameBuffer, webGl.BLACK,  gl.RGBA);
                let alphaFrameBuffer = createOrCleanFramebuffer(gl, viewport.width, viewport.height, map.alphaFrameBuffer, webGl.TRANSPARENT, gl.RGBA);
                let temporaryBuffer = createOrCleanFramebuffer(gl, viewport.width, viewport.height, map.temporaryBuffer, webGl.TRANSPARENT, gl.RGBA);

                state.map = {
                    drawFrameBuffer: drawFrameBuffer,
                    maskFrameBuffer: maskFrameBuffer,
                    alphaFrameBuffer: alphaFrameBuffer,
                    temporaryBuffer: temporaryBuffer,
                    normalMaskFrameBuffer: normalMaskFrameBuffer
                };

                gl.uniform1f(programInfo.uniformLocations.time, state.time+this.timeDisplacement);
                gl.uniform3fv(programInfo.uniformLocations.lightDirection, lightDirection);
                gl.uniform2f(programInfo.uniformLocations.canvasSize, viewport.width, viewport.height);

                function clamp(val, min, max) {
                    return val <min? min : val> max ? max: val;
                }

                function lerp(val, min, max) {
                    if(val < min) {
                        return 0.0;
                    } else if(val>= max){
                        return 1.0;
                    }
                    return clamp( (val-min)/(max - min) , 0.0 , 1.0);
                }

                let transitionTime = 8.0;
                let transitionTime2 = 16.0;

                let blurAmount = lerp(webAudio.myNoise3dx(perlin.noise, state.time, 0.0 ,0.0, transitionTime),0.3 , 0.6);

                let cylinderAmount = lerp(webAudio.myNoise3dx(perlin.noise, 0.0, state.time, 0.0, transitionTime),0.4, 0.6);
                let cubesAmount = lerp(webAudio.myNoise3dx(perlin.noise, 0.0, 0.0 ,state.time, transitionTime),0.4, 0.6);

                let torusAmount = lerp(webAudio.myNoise3dx(perlin.noise, state.time, state.time ,0.0, transitionTime),0.4, 0.6);
                let mandalaAmount = lerp(webAudio.myNoise3dx(perlin.noise, state.time, 0.0, state.time , transitionTime),0.4, 0.6);
                let starsAmount = lerp(webAudio.myNoise3dx(perlin.noise, 0.0, state.time,  state.time , transitionTime),0.4, 0.6);

                let modelAmount = lerp(webAudio.myNoise3dx(perlin.noise, state.time, state.time,  state.time , transitionTime),0.4, 0.5);

                let rgbShiftAmount = lerp(webAudio.myNoise3dx(perlin.noise, state.time+1024, state.time,  state.time , transitionTime2), 0.6, 0.8 );
                let waterAmount = lerp(webAudio.myNoise3dx(perlin.noise, state.time, state.time+1024,  state.time, transitionTime2),0.6, 1.0);
                let radialAmount = lerp(webAudio.myNoise3dx(perlin.noise, state.time, state.time,  state.time+1024 , transitionTime2),0.6 , 1.0);

                let sphericalGridAmount = lerp(webAudio.myNoise3dx(perlin.noise, 0.0,state.time+1024, 0.0, transitionTime),0.5, 0.7);
                let hexaGridAmount = lerp(webAudio.myNoise3dx(perlin.noise, 0.0, 0.0 ,state.time+1024, transitionTime),0.5, 0.6);

                if(DEBUG) {
                    rgbShiftAmount=0.0;
                    waterAmount =0.0;
                    radialAmount =0.0;
                    hexaGridAmount = 1.0;
                }

                let variant = 0;
                if (viewMatrix == null) {
                    viewMatrix = glm.mat4.create();
                    let center = glm.vec3.set(TEMP_CENTER, 0, 0, -1);
                    let up = glm.vec3.set(TEMP_UP, 0, 1, 0);
                    let eye = glm.vec3.set(TEMP_EYE, 0, 0, 0);
                    glm.mat4.lookAt(viewMatrix, eye, center, up);
                }
                if (projectionMatrix == null) {
                    projectionMatrix = glm.mat4.create();
                    glm.mat4.perspective(projectionMatrix, 90 * Math.PI / 180, gl.canvas.clientWidth / gl.canvas.clientHeight, 0.1, 1000.0);
                }
                gl.uniformMatrix4fv(programInfo.uniformLocations.viewMatrix, false, viewMatrix);
                gl.uniformMatrix4fv(programInfo.uniformLocations.projectionMatrix, false, projectionMatrix);

                {
                    let invertedViewMatrix = glm.mat4.invert(TEMP_VIEW, viewMatrix);
                    glm.vec3.set(cameraPosition, invertedViewMatrix[12], invertedViewMatrix[13], invertedViewMatrix[14]);
                    gl.uniform3fv(programInfo.uniformLocations.cameraPosition, cameraPosition);
                }


                // **********
                // Draw space
                // **********
                if(spaceModel) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, 1.0);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);

                    glm.mat4.scale(modelMatrix, modelMatrix, glm.vec3.set(TEMP_SCALE, 400, 400, 400));
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_3D_SKY);
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
                if(torusModel && torusAmount) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, torusAmount);

                    let position = glm.vec3.set(TEMP_POSITION, 0, 0, 0);
                    let scale =  glm.vec3.set(TEMP_SCALE, 32, 8.0, 32);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);

                    glm.vec3.add(position, position, modelPosition);
                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.scale(modelMatrix, modelMatrix, scale);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_3D_TORUS);
                    gl.enable(gl.DEPTH_TEST);
                    gl.enable(gl.CULL_FACE);

                    for (let mesh of torusModel) {
                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES);
                    }
                }

                // **********
                // Draw cubes
                // **********
                if(cubeModel && cubesAmount) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, cubesAmount);

                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_3D_CUBE);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    let size = 1;
                    let distance = 64;
                    for(let i = -size; i <= size; ++i) {
                        for(let j = -size; j <= size; ++j) {
                            for(let k = -size; k <= size; ++k) {
                                if(Math.abs(i) === size || Math.abs(j) === size || Math.abs(k) === size) {
                                    let noise = (webAudio.myNoise3dx(perlin.noise, state.time+i, state.time+j , state.time+k, 4.0)*0.2+ 0.8*this.dataArray[0]/255);

                                    let position = glm.vec3.set(TEMP_POSITION, i, j, k);
                                    let direction = glm.vec3.set(TEMP_DIRECTION, 0.0, 0.0, 0.0);
                                    let scale = glm.vec3.set(TEMP_SCALE, 1.0, 1.0, 1.0);
                                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);

                                    glm.vec3.normalize(direction, position);
                                    glm.vec3.scale(position,direction,distance - noise * distance);
                                    glm.vec3.add(position, position, modelPosition);
                                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                                    glm.mat4.scale(modelMatrix, modelMatrix, scale);
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

                // *******************
                // Draw spherical grid
                // *******************
                if(sphereModel && sphericalGridAmount) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, sphericalGridAmount);

                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_3D_SPHERICAL_GRID);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    let position = glm.vec3.copy(TEMP_POSITION, modelPosition);
                    let scale = glm.vec3.set(TEMP_SCALE, 32, 32, 32);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);

                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.scale(modelMatrix, modelMatrix, scale);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                    for (let mesh of sphereModel) {
                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES);

                    }
                }

                // *******************
                // Draw hexa grid mask
                // *******************
                if(hexaModel && hexaGridAmount) {
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, hexaGridAmount);

                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_3D_HEXA_GRID);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    let position = glm.vec3.copy(TEMP_POSITION, modelPosition);
                    let scale = glm.vec3.set(TEMP_SCALE, 32, 32, 32);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);

                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.scale(modelMatrix, modelMatrix, scale);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                    gl.bindFramebuffer(gl.FRAMEBUFFER, normalMaskFrameBuffer.frame);
                    for (let mesh of hexaModel) {
                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES, hexaMaskTexture);
                    }
                }

                // *************
                // Draw cylinder
                // *************
                if(cylinderAmount){
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, cylinderAmount);

                    gl.enable(gl.DEPTH_TEST);
                    gl.enable(gl.CULL_FACE);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_3D_CYLINDER);
                    let cylinderDistance = 20;

                    variant = 0;
                    for (let i = Math.PI / 3.0; i < 2 * Math.PI - 0.001; i += 2.0 * Math.PI / 3.0) {
                        let position = glm.vec3.set(TEMP_POSITION, -cylinderDistance * Math.sin(i), -128, -cylinderDistance * Math.cos(i));
                        let modelMatrix = glm.mat4.identity(TEMP_MODEL);
                        let scale = glm.vec3.set(TEMP_SCALE, 4, 4, 4);

                        glm.vec3.add(position, position, modelPosition);
                        glm.mat4.translate(modelMatrix, modelMatrix, position);
                        glm.mat4.scale(modelMatrix, modelMatrix, scale);
                        gl.uniform1f(programInfo.uniformLocations.drawVariant, ++variant * 4.0);
                        gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                        webGl.drawMesh(gl, programInfo, cylinderMesh, gl.TRIANGLES);
                    }

                }

                // **************
                // Draw billboard
                // **************
                if(starsAmount) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, starsAmount);

                    //let up = glm.vec3.set(TEMP_UP, viewMatrix[4], viewMatrix[5] ,viewMatrix[6]);
                    let up = glm.vec3.set(TEMP_UP ,0, 1, 0);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_3D_BILLBOARD);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);
                    variant = 0;
                    for (let i = 0; i < 2.0 * Math.PI; i += Math.PI / 8.0) {
                        let r = 24.0;
                        let position = glm.vec3.set(TEMP_POSITION,  r * Math.cos(i), 24.0, r * Math.sin(i));
                        let scale = glm.vec3.set(TEMP_SCALE, 2, 2, 2);
                        let modelMatrix = glm.mat4.identity(TEMP_MODEL);

                        glm.vec3.add(position, position, modelPosition);
                        modelMatrix = webGl.getBillboardMatrix(modelMatrix, position, cameraPosition, up);
                        glm.mat4.scale(modelMatrix, modelMatrix, scale);

                        gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                        gl.uniform1f(programInfo.uniformLocations.drawVariant, ++variant * 32.0);
                        webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, flareTexture);
                    }
                }

                // *****************
                // Draw mandala mask
                // *****************

                if(mandalaModel && blurAmount) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, maskFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, 1.0);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);
                    let position = glm.vec3.set(TEMP_POSITION, 0, -2.2, 0);
                    let scale = glm.vec3.set(TEMP_SCALE, 8, 8, 8);

                    glm.vec3.add(position, position, modelPosition);
                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.scale(modelMatrix, modelMatrix, scale);
                    glm.mat4.rotateY(modelMatrix, modelMatrix, -state.time * 0.1);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_3D_MASK);
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
                if(statueModel && blurAmount) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, maskFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, 1.0);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);
                    let position = glm.vec3.set(TEMP_POSITION ,0, 0, 0);

                    glm.vec3.add(position, position, modelPosition);
                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.rotateY(modelMatrix, modelMatrix, Math.PI / 2.0 - state.time * 0.1);

                    gl.enable(gl.DEPTH_TEST);
                    gl.enable(gl.CULL_FACE);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_3D_NO_EDGES_MASK);
                    for (let mesh of statueModel) {
                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES);
                    }
                }

                // ************
                // Draw mandala
                // ************
                if(mandalaModel && mandalaAmount) {
                    // common
                    let position = glm.vec3.set(TEMP_POSITION, 0, -2.2, 0);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);
                    let scale = glm.vec3.set(TEMP_SCALE, 8, 8, 8);

                    glm.vec3.add(position, position, modelPosition);
                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.scale(modelMatrix, modelMatrix, scale);
                    glm.mat4.rotateY(modelMatrix, modelMatrix, -state.time * 0.1);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.enable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    // 1st pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, mandalaAmount);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_3D_MANDALA);
                    for (let mesh of mandalaModel) {
                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES, mandalaTexture);
                    }
                }

                // *********
                // DRAW BLUR
                // *********
                if(blurAmount){
                    // common
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);

                    // 1st pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, temporaryBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, 1.0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D);
                    webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, drawFrameBuffer.texture);

                    // 2nd pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, blurAmount);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D_BLUR);
                    webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, temporaryBuffer.texture, maskFrameBuffer.texture);
                }

                // **********
                // Draw model
                // **********
                if(statueModel) {
                    // common
                    let position = glm.vec3.set(TEMP_POSITION, 0, 0, 0);
                    glm.vec3.add(position, position, modelPosition);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);
                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.rotateY(modelMatrix, modelMatrix, Math.PI / 2.0 - state.time * 0.1);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.enable(gl.DEPTH_TEST);
                    gl.enable(gl.CULL_FACE);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 1);

                    // 1st pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, alphaFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, 1.0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_3D_DEFAULT);
                    for (let mesh of statueModel) {
                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES);
                    }
                }


                // ****************
                // DRAW MIXBUFFER 2
                // ****************
                if(modelAmount){
                    // common
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    // 1st pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, modelAmount);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D_MIX);
                    webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, alphaFrameBuffer.texture);
                }

                // ****************
                // Draw model edges
                // ****************
                if(statueModel) {
                    // common
                    let position = glm.vec3.set(TEMP_POSITION, 0, 0, 0);
                    glm.vec3.add(position, position, modelPosition);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);
                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.rotateY(modelMatrix, modelMatrix, Math.PI / 2.0 - state.time * 0.1);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.enable(gl.DEPTH_TEST);
                    gl.enable(gl.CULL_FACE);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 1);

                    // 1st pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, 1.0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_3D_EDGES);
                    for (let mesh of statueModel) {
                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES);
                    }
                }

                // ***********
                // DRAW NORMAL
                // ***********
                if(hexaGridAmount){
                    // common
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, 1.0);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);

                    // 1st pass
                    webGl.copyBuffer(gl, drawFrameBuffer, temporaryBuffer);

                    // 2nd pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, 1.0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D_NORMAL);
                    webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, temporaryBuffer.texture, normalMaskFrameBuffer.texture);
                }

                // *******************
                // Draw hexa grid mask
                // *******************
                if(hexaModel && hexaGridAmount) {
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, hexaGridAmount);

                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_3D_HEXA_GRID);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    let position = glm.vec3.copy(TEMP_POSITION, modelPosition);
                    let scale = glm.vec3.set(TEMP_SCALE, 32, 32, 32);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);

                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.scale(modelMatrix, modelMatrix, scale);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);

                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    for (let mesh of hexaModel) {
                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES, hexaSphereTexture);
                    }
                }
                
                // ***********
                // DRAW RADIAL
                // ***********
                if(radialAmount){
                    // common
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, 1.0);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);

                    // 1st pass
                    webGl.copyBuffer(gl, drawFrameBuffer, temporaryBuffer);

                    // 2nd pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, radialAmount);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D_RADIAL);
                    webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, temporaryBuffer.texture);
                }

                // **********
                // DRAW WATER
                // **********
                if(waterAmount){
                    // common
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, 1.0);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);

                    // 1st pass
                    webGl.copyBuffer(gl, drawFrameBuffer, temporaryBuffer);

                    // 2nd pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, waterAmount);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D_WATER);
                    webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, temporaryBuffer.texture);
                }

                // **********
                // DRAW SHIFT
                // **********
                if(rgbShiftAmount){
                    // common
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, 1.0);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);

                    // 1st pass
                    webGl.copyBuffer(gl, drawFrameBuffer, temporaryBuffer);

                    // 2nd pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, rgbShiftAmount);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D_SHIFT);
                    webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, temporaryBuffer.texture);
                }

                // ****************
                // DRAW FRAMEBUFFER
                // ****************
                {
                    // common
                    gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    // 1st pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, mainFramebuffer);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, 1.0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D);
                    webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, drawFrameBuffer.texture);
                }

                // *****
                // DEBUG
                // *****
                if(DEBUG && billboardMesh){
                    gl.bindFramebuffer(gl.FRAMEBUFFER, mainFramebuffer);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, 1.0);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D);
                    gl.enable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);

                    let textures = [
                        audioTexture ,
                        maskFrameBuffer.texture,
                        alphaFrameBuffer.texture,
                        normalMaskFrameBuffer.texture
                    ];
                    let size = 0.1;

                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);
                    let position = glm.vec3.set(TEMP_POSITION, -1.0-size ,1.0-size,0.0);
                    let scale = glm.vec3.set(TEMP_SCALE, size,size,1.0);

                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.scale(modelMatrix, modelMatrix, scale);
                    position = glm.vec3.set(TEMP_POSITION, 2.0 ,0.0, 0.0);

                    for(let texture of textures) {
                        glm.mat4.translate(modelMatrix, modelMatrix, position);
                        gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                        webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, texture);
                    }
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