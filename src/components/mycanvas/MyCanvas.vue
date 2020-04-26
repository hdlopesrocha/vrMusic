<template>
    <div>
        <table v-if="!hidden">
            <tr>
                <td>Step 1:</td>
                <td colspan="2">
                    <button v-on:click="pickFile" >File</button>
                    or
                    <button v-on:click="enableMic">Mic</button>
                </td>
            </tr>
            <tr>
                <td>Step 2:</td>
                <td colspan="2">
                    <button v-on:click="enableVr" >Enter VR</button>
                    or
                    <button v-on:click="enableCubeMap" >Cube</button>
                    or
                    <button v-on:click="hideTable" >Hide</button>
                </td>
            </tr>
            <tr>
                <td colspan="3">
                    Donate:
                    <ul>
                        <li>BTC: 37z5ap84nNA1VMrF8QNJ6XYVGrKn1GopKH</li>
                        <li>ETH: 0x13CBcCCA8910DdCc007aa73eed031E2C7eE1Bf62</li>
                    </ul>
                </td>
            </tr>
            <tr>
                <td><b>Effect</b></td>
                <td><b>Transition</b></td>
                <td><b>Period</b></td>
            </tr>
            <tr>
                <td><small>3D</small></td>
            </tr>
            <tr>
                <td>Blur:</td>
                <td><vue-slider v-model="blurTransition" :min-range="1" :max-range="100" style="width: 100%" ></vue-slider></td>
                <td><input type="number" v-model="blurPeriod" style="width: 32px"></td>
            </tr>
            <tr>
                <td>Cubes:</td>
                <td><vue-slider v-model="cubesTransition" :min-range="1" :max-range="100" style="width: 100%" ></vue-slider></td>
                <td><input type="number" v-model="cubesPeriod" style="width: 32px"></td>
            </tr>
            <tr>
                <td>Cylinders:</td>
                <td><vue-slider v-model="cylindersTransition" :min-range="1" :max-range="100" style="width: 100%" ></vue-slider></td>
                <td><input type="number" v-model="cylindersPeriod" style="width: 32px"></td>
            </tr>
            <tr>
                <td>Hexagons:</td>
                <td><vue-slider v-model="hexagonsTransition" :min-range="1" :max-range="100" style="width: 100%" ></vue-slider></td>
                <td><input type="number" v-model="hexagonsPeriod" style="width: 32px"></td>
            </tr>
            <tr>
                <td>Mandala:</td>
                <td><vue-slider v-model="mandalaTransition" :min-range="1" :max-range="100" style="width: 100%" ></vue-slider></td>
                <td><input type="number" v-model="mandalaPeriod" style="width: 32px"></td>
            </tr>
            <tr>
                <td>Model:</td>
                <td><vue-slider v-model="modelTransition" :min-range="1" :max-range="100" style="width: 100%" ></vue-slider></td>
                <td><input type="number" v-model="modelPeriod" style="width: 32px"></td>
            </tr>
            <tr>
                <td>Neural:</td>
                <td><vue-slider v-model="neuralTransition" :min-range="1" :max-range="100" style="width: 100%" ></vue-slider></td>
                <td><input type="number" v-model="neuralPeriod" style="width: 32px"></td>
            </tr>
            <tr>
                <td>Pyramids:</td>
                <td><vue-slider v-model="pyramidsTransition" :min-range="1" :max-range="100" style="width: 100%" ></vue-slider></td>
                <td><input type="number" v-model="pyramidsPeriod" style="width: 32px"></td>
            </tr>
            <tr>
                <td>Stars:</td>
                <td><vue-slider v-model="starsTransition" :min-range="1" :max-range="100" style="width: 100%" ></vue-slider></td>
                <td><input type="number" v-model="starsPeriod" style="width: 32px"></td>
            </tr>
            <tr>
                <td>Torus:</td>
                <td><vue-slider v-model="torusTransition" :min-range="1" :max-range="100" style="width: 100%" ></vue-slider></td>
                <td><input type="number" v-model="torusPeriod" style="width: 32px"></td>
            </tr>
            <tr>
                <td><small>2D</small></td>
            </tr>
            <tr>
                <td>Filter:</td>
                <td><vue-slider v-model="filterTransition" :min-range="1" :max-range="100" style="width: 100%" ></vue-slider></td>
                <td><input type="number" v-model="filterPeriod" style="width: 32px"></td>
            </tr>
            <tr>
                <td>Radial:</td>
                <td><vue-slider v-model="radialTransition" :min-range="1" :max-range="100" style="width: 100%" ></vue-slider></td>
                <td><input type="number" v-model="radialPeriod" style="width: 32px"></td>
            </tr>
            <tr>
                <td>RGB:</td>
                <td><vue-slider v-model="rgbTransition" :min-range="1" :max-range="100" style="width: 100%" ></vue-slider></td>
                <td><input type="number" v-model="rgbPeriod" style="width: 32px"></td>
            </tr>
            <tr>
                <td>Water:</td>
                <td><vue-slider v-model="waterTransition" :min-range="1" :max-range="100" style="width: 100%" ></vue-slider></td>
                <td><input type="number" v-model="waterPeriod" style="width: 32px"></td>
            </tr>
            <tr>
                <td>Mic Amplification:</td>
                <td><input type="number" v-model="micAmp" style="width: 32px"></td>
            </tr>
        </table>
        <canvas v-bind:width="canvasWidth" v-bind:height="canvasHeight" id="glcanvas"></canvas>
        <input id="file" ref="file" style="display: none" v-on:change="enableMusic" type="file" name="file" accept="audio/*">
    </div>
</template>

<script>
    /* eslint-disable no-unused-vars */
    const DEBUG = false;
    const MOUSE_SPEED = 0.003;

    // 2D MODES
    const DRAW_MODE_2D_FILTER = -10
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
    const DRAW_MODE_3D_PYRAMID = 11
    const DRAW_MODE_3D_MODEL = 12
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

    import VueSlider from 'vue-slider-component'
    import 'vue-slider-component/theme/default.css'

    export default {
        name: "VrMusic",
        components: {
            VueSlider
        },
        data() {
            return {
                canvasWidth: window.innerWidth,
                canvasHeight: window.innerHeight,
                state: null,
                gl: null,
                source: null,
                isPlaying: false,
                audioContext: null,
                analyser: null,
                freqArray: null,
                dataArray: null,
                fftSize: 512,
                audioLevel: 0,
                softAudioLevel: 0,
                timeShift: 0,
                hidden: false,
                micAmp: 1.0,


                waterTransition: [80,100],
                radialTransition: [80,100],
                rgbTransition: [60,80],
                blurTransition: [30,60],
                cubesTransition: [50,70],
                modelTransition: [40,50],
                mandalaTransition: [40,60],
                torusTransition: [40,60],
                starsTransition: [40,60],
                cylindersTransition: [40,60],
                hexagonsTransition: [50,70],
                pyramidsTransition: [50,70],
                neuralTransition: [50,70],
                filterTransition: [100,100],

                waterPeriod: 16,
                radialPeriod: 16,
                rgbPeriod: 16,
                blurPeriod: 8,
                cubesPeriod: 8,
                modelPeriod: 8,
                mandalaPeriod: 8,
                torusPeriod: 8,
                starsPeriod: 8,
                cylindersPeriod: 8,
                hexagonsPeriod:8,
                pyramidsPeriod: 8,
                neuralPeriod: 8,
                filterPeriod: 8,

                mousePitch: 0,
                mouseYaw: 0,
            }
        },
        methods: {
            enableVr() {
                webGl.toggleVR(this.gl, this.state);
            },
            enableCubeMap(){
                webGl.toggleCubeMap(this.gl, this.state);
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
            hideTable() {
                this.hidden = true;
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

            },
            rotateViewBy(dx, dy) {
                this.mouseYaw -= dx * MOUSE_SPEED;
                this.mousePitch -= dy * MOUSE_SPEED;

                if (this.mousePitch < -Math.PI * 0.5) {
                    this.mousePitch = -Math.PI * 0.5;
                } else if (this.mousePitch > Math.PI * 0.5) {
                    this.mousePitch = Math.PI * 0.5;
                }
            },
            handlePointerMove(event) {
                if (event.buttons & 1) {
                    this.rotateViewBy(event.movementX, event.movementY);
                }
            }
        },
        mounted() {
            const canvas = document.querySelector('#glcanvas');
            const gl = canvas.getContext('webgl2', {xrCompatible: true});
            this.gl = gl;
            if(!DEBUG) {
                canvas.addEventListener("contextmenu", (event) => {
                    event.preventDefault();
                });
            }
            canvas.addEventListener("pointermove", this.handlePointerMove);


            window.addEventListener("resize", function() {
                this.canvasWidth= window.innerWidth;
                this.canvasHeight= window.innerHeight;
                console.log(this);
            }.bind(this));

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
            let filterNormalTexture = webGl.loadTexture(gl, "textures/filter_normal.jpg");
            let filterBumpTexture = webGl.loadTexture(gl, "textures/filter_bump.jpg");
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
            let pyramidModel = null;

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
            loader.load("models/pyramid.gltf", gltf => {
                pyramidModel = webGl.getModel(gl, gltf);
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
            // eslint-disable-next-line no-unused-vars
            let TEMP_VIEW = glm.mat4.create();
            let TEMP_INV_VIEW = glm.mat4.create();
            let TEMP_MODEL = glm.mat4.create();
            let TEMP_PROJECTION = glm.mat4.create();
            let cameraPosition = glm.vec3.create();
            let modelPosition = glm.vec3.fromValues(0,0,-6);


            // ********
            // fun zone
            // ********


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

            // eslint-disable-next-line no-unused-vars
            function update(gl, state) {
                if(this.audioContext) {
                    if (this.analyser) {
                        this.analyser.getByteTimeDomainData(this.dataArray);
                        for(let i=0; i < this.dataArray.length ; ++i){
                            this.dataArray[i] *= this.micAmp;
                        }
                        webGl.loadAudio(gl,audioTexture, this.fftSize, this.dataArray);
                        webGl.bindTexture(gl, programInfo.uniformLocations.audioSampler, 2, audioTexture);
                        this.audioLevel = 2.0*( webAudio.max(this.dataArray) / 255.0 - 0.5);
                        let timeToConverge = 0.25;
                        let amountToShift = clamp(state.delta / timeToConverge, 0.0, 1.0);
                        this.softAudioLevel = (1.0-amountToShift)*this.softAudioLevel + amountToShift*this.audioLevel;
                    }
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
            function draw(gl, viewport, state, viewMatrix, projectionMatrix, mainFramebuffer, extraEffectsEnabled) {
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

                this.timeShift += state.delta*this.softAudioLevel;

                gl.uniform1f(programInfo.uniformLocations.time, state.time);
                gl.uniform1f(programInfo.uniformLocations.timeShift, this.timeShift);
                gl.uniform1f(programInfo.uniformLocations.audioLevel, this.audioLevel);
                gl.uniform3fv(programInfo.uniformLocations.lightDirection, lightDirection);
                gl.uniform2f(programInfo.uniformLocations.canvasSize, viewport.width, viewport.height);

                let angularVelocity = 0.5;

                let blurAmount = lerp(webAudio.myNoise3dx(perlin.noise, state.time, 0.0 ,0.0, this.blurPeriod),this.blurTransition[0]/100.0, this.blurTransition[1]/100.0);

                let cylinderAmount = lerp(webAudio.myNoise3dx(perlin.noise, 0.0, state.time, 0.0, this.cylindersPeriod),this.cylindersTransition[0]/100.0, this.cylindersTransition[1]/100.0);
                let cubesAmount = lerp(webAudio.myNoise3dx(perlin.noise, 0.0, 0.0 ,state.time, this.cubesPeriod),this.cubesTransition[0]/100.0, this.cubesTransition[1]/100.0);

                let torusAmount = lerp(webAudio.myNoise3dx(perlin.noise, state.time, state.time ,0.0, this.torusPeriod),this.torusTransition[0]/100.0, this.torusTransition[1]/100.0);
                let mandalaAmount = lerp(webAudio.myNoise3dx(perlin.noise, state.time, 0.0, state.time , this.mandalaPeriod),this.mandalaTransition[0]/100.0, this.mandalaTransition[1]/100.0);
                let starsAmount = lerp(webAudio.myNoise3dx(perlin.noise, 0.0, state.time,  state.time , this.starsPeriod),this.starsTransition[0]/100.0, this.starsTransition[1]/100.0);

                let modelAmount = lerp(webAudio.myNoise3dx(perlin.noise, state.time, state.time,  state.time , this.modelPeriod),this.modelTransition[0]/100.0, this.modelTransition[1]/100.0);

                let rgbShiftAmount = lerp(webAudio.myNoise3dx(perlin.noise, state.time+1024, state.time,  state.time , this.rgbPeriod), this.rgbTransition[0]/100.0, this.rgbTransition[1]/100.0 );
                let waterAmount = lerp(webAudio.myNoise3dx(perlin.noise, state.time, state.time+1024,  state.time, this.waterPeriod),this.waterTransition[0]/100.0, this.waterTransition[1]/100.0);
                let radialAmount = lerp(webAudio.myNoise3dx(perlin.noise, state.time, state.time,  state.time+1024 , this.radialPeriod),this.radialTransition[0]/100.0, this.radialTransition[1]/100.0);

                let sphericalGridAmount = lerp(webAudio.myNoise3dx(perlin.noise, state.time+1024, 0.0, 0.0, this.neuralPeriod),this.neuralTransition[0]/100.0, this.neuralTransition[1]/100.0);
                let hexaGridAmount = lerp(webAudio.myNoise3dx(perlin.noise, 0.0,state.time+1024, 0.0, this.hexagonsPeriod),this.hexagonsTransition[0]/100.0, this.hexagonsTransition[1]/100.0);
                let pyramidsAmount = lerp(webAudio.myNoise3dx(perlin.noise, 0.0, 0.0 ,state.time+1024, this.pyramidsPeriod),this.pyramidsTransition[0]/100.0, this.pyramidsTransition[1]/100.0);

                let filterAmount = lerp(webAudio.myNoise3dx(perlin.noise, 0.0, 0.0 ,state.time+2048, this.filterPeriod),this.filterTransition[0]/100.0, this.filterTransition[1]/100.0);

                if(DEBUG) {
                    rgbShiftAmount=0.0;
                    waterAmount =0.0;
                    radialAmount =0.0;
                }

                let variant = 0;
                if (viewMatrix == null) {
                    viewMatrix = glm.mat4.create();
                    let center = glm.vec3.set(TEMP_CENTER, 0, 0, -1);
                    let up = glm.vec3.set(TEMP_UP, 0, 1, 0);
                    let eye = glm.vec3.set(TEMP_EYE, 0, 0, 0);
                    glm.mat4.lookAt(viewMatrix, eye, center, up);

                    glm.mat4.rotateX(viewMatrix, viewMatrix, this.mousePitch);
                    glm.mat4.rotateY(viewMatrix, viewMatrix, this.mouseYaw);
                }
                if (projectionMatrix == null) {
                    projectionMatrix = glm.mat4.identity(TEMP_PROJECTION);
                    glm.mat4.perspective(projectionMatrix, 90 * Math.PI / 180, gl.canvas.clientWidth / gl.canvas.clientHeight, 0.1, 1000.0);
                }
                gl.uniformMatrix4fv(programInfo.uniformLocations.viewMatrix, false, viewMatrix);
                gl.uniformMatrix4fv(programInfo.uniformLocations.projectionMatrix, false, projectionMatrix);

                {
                    let invertedViewMatrix = glm.mat4.invert(TEMP_INV_VIEW, viewMatrix);
                    glm.vec3.set(cameraPosition, invertedViewMatrix[12], invertedViewMatrix[13], invertedViewMatrix[14]);
                    gl.uniform3fv(programInfo.uniformLocations.cameraPosition, cameraPosition);
                }


                // **********
                // Draw space
                // **********
                if(spaceModel) {
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
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
                                    let noise = this.softAudioLevel;

                                    let position = glm.vec3.set(TEMP_POSITION, i, j, k);
                                    let direction = glm.vec3.set(TEMP_DIRECTION, 0.0, 0.0, 0.0);
                                    let scale = glm.vec3.set(TEMP_SCALE, 1.0, 1.0, 1.0);
                                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);

                                    glm.vec3.normalize(direction, position);
                                    glm.vec3.scale(position,direction,distance * (1.0 - noise));
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

                // *************
                // Draw pyramids
                // *************
                if(pyramidModel && pyramidsAmount){
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, pyramidsAmount);

                    gl.disable(gl.DEPTH_TEST);
                    gl.disable(gl.CULL_FACE);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 0);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_3D_PYRAMID);
                    let cylinderDistance = 32;

                    variant = 0;
                    for (let i = Math.PI / 3.0; i < 2 * Math.PI - 0.001; i += Math.PI / 3.0) {
                        let position = glm.vec3.set(TEMP_POSITION, -cylinderDistance * Math.sin(i), 0, -cylinderDistance * Math.cos(i));
                        let modelMatrix = glm.mat4.identity(TEMP_MODEL);
                        let scale = glm.vec3.set(TEMP_SCALE, 4, 4, 4);

                        glm.vec3.add(position, position, modelPosition);
                        glm.mat4.translate(modelMatrix, modelMatrix, position);
                        glm.mat4.scale(modelMatrix, modelMatrix, scale);
                        glm.mat4.rotateY(modelMatrix, modelMatrix, -this.timeShift);
                        gl.uniform1f(programInfo.uniformLocations.drawVariant, ++variant * 4.0);
                        gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                        for (let mesh of pyramidModel) {
                            webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES);
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

                    let scale = glm.vec3.set(TEMP_SCALE, 4, 4, 4);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);

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

                    let scale = glm.vec3.set(TEMP_SCALE, 2, 2, 2);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);

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
                    gl.uniform1f(programInfo.uniformLocations.animationVelocity, 2.0);
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
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);
                    let position = glm.vec3.set(TEMP_POSITION, 0, -2.2, 0);
                    let scale = glm.vec3.set(TEMP_SCALE, 8, 8, 8);

                    glm.vec3.add(position, position, modelPosition);
                    glm.mat4.translate(modelMatrix, modelMatrix, position);
                    glm.mat4.scale(modelMatrix, modelMatrix, scale);
                    glm.mat4.rotateY(modelMatrix, modelMatrix, -this.timeShift*angularVelocity);
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
                    glm.mat4.rotateY(modelMatrix, modelMatrix, Math.PI / 2.0 - this.timeShift*angularVelocity);

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
                    glm.mat4.rotateY(modelMatrix, modelMatrix, -this.timeShift*angularVelocity);
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
                    webGl.prepareFor2D(gl, programInfo);

                    // 1st pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, temporaryBuffer.frame);
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
                    glm.mat4.rotateY(modelMatrix, modelMatrix, Math.PI / 2.0 - this.timeShift*angularVelocity);
                    gl.uniformMatrix4fv(programInfo.uniformLocations.modelMatrix, false, modelMatrix);
                    gl.enable(gl.DEPTH_TEST);
                    gl.enable(gl.CULL_FACE);
                    gl.uniform1i(programInfo.uniformLocations.enableLight, 1);

                    // 1st pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, alphaFrameBuffer.frame);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_3D_MODEL);
                    for (let mesh of statueModel) {
                        webGl.drawMesh(gl, programInfo, mesh, gl.TRIANGLES);
                    }
                }


                // ****************
                // DRAW MIXBUFFER 2
                // ****************
                if(modelAmount){
                    // common
                    webGl.prepareFor2D(gl, programInfo);

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
                    glm.mat4.rotateY(modelMatrix, modelMatrix, Math.PI / 2.0 - this.timeShift*angularVelocity);
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
                    webGl.copyBuffer(gl, drawFrameBuffer, temporaryBuffer);
                    webGl.prepareFor2D(gl, programInfo);

                    // 2nd pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
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

                    let scale = glm.vec3.set(TEMP_SCALE, 2, 2, 2);
                    let modelMatrix = glm.mat4.identity(TEMP_MODEL);

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
                if(radialAmount && extraEffectsEnabled){
                    // common
                    webGl.copyBuffer(gl, drawFrameBuffer, temporaryBuffer);
                    webGl.prepareFor2D(gl, programInfo);

                    // 1st pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, radialAmount);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D_RADIAL);
                    webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, temporaryBuffer.texture);
                }

                // **********
                // DRAW WATER
                // **********
                if(waterAmount && extraEffectsEnabled){
                    // common
                    webGl.copyBuffer(gl, drawFrameBuffer, temporaryBuffer);
                    webGl.prepareFor2D(gl, programInfo);

                    // 1st pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, waterAmount);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D_WATER);
                    webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, temporaryBuffer.texture);
                }

                // ***********
                // DRAW FILTER
                // ***********
                if(extraEffectsEnabled){
                    // common
                    webGl.copyBuffer(gl, drawFrameBuffer, temporaryBuffer);
                    webGl.prepareFor2D(gl, programInfo);

                    // 1st pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, drawFrameBuffer.frame);
                    gl.uniform1f(programInfo.uniformLocations.effectAmount, filterAmount);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D_FILTER);
                    webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, temporaryBuffer.texture, filterNormalTexture, filterBumpTexture);
                }


                // **********
                // DRAW SHIFT
                // **********
                if(rgbShiftAmount && extraEffectsEnabled){
                    // common
                    webGl.copyBuffer(gl, drawFrameBuffer, temporaryBuffer);
                    webGl.prepareFor2D(gl, programInfo);

                    // 1st pass
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
                    webGl.prepareFor2D(gl, programInfo);

                    // 1st pass
                    gl.bindFramebuffer(gl.FRAMEBUFFER, mainFramebuffer);
                    gl.uniform1i(programInfo.uniformLocations.drawMode, DRAW_MODE_2D);
                    webGl.drawMesh(gl, programInfo, billboardMesh, gl.TRIANGLES, drawFrameBuffer.texture);
                }

                // *****
                // DEBUG
                // *****
                if(DEBUG && billboardMesh){
                    gl.bindFramebuffer(gl.FRAMEBUFFER, mainFramebuffer);
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
    table {
        position: absolute;
        color: white;
        background: rgba(0,0,0,0.75);
        padding: 4px;
    }
    button {
        padding: 10px;
    }
    li {
        font-size: 10px;
    }
    td {
        padding: 0px 4px;
    }
</style>

<style>
    .vue-slider-rail > .vue-slider-dot:nth-child(2) > div:first-child {
        background: red !important;
        text-align: center;
        line-height: 10px;
    }
    .vue-slider-rail > .vue-slider-dot:nth-child(2) > div:first-child:after {
        content: "O" !important;
        font-size: 10px;
    }
    .vue-slider-rail > .vue-slider-dot:nth-child(3) > div:first-child {
        background: green !important;
        text-align: center;
        line-height: 10px;
    }
    .vue-slider-rail > .vue-slider-dot:nth-child(3) > div:first-child:after {
        content: "I" !important;
        font-size: 10px;
    }
</style>