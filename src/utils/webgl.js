import WebVRPolyfill from 'webvr-polyfill';

export default {

    initShaderProgram(gl, vsSource, fsSource) {
        const vertexShader = this.loadShader(gl, gl.VERTEX_SHADER, vsSource);
        const fragmentShader = this.loadShader(gl, gl.FRAGMENT_SHADER, fsSource);

        const shaderProgram = gl.createProgram();
        gl.attachShader(shaderProgram, vertexShader);
        gl.attachShader(shaderProgram, fragmentShader);
        gl.linkProgram(shaderProgram);

        if (!gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)) {
            alert('Unable to initialize the shader program: ' + gl.getProgramInfoLog(shaderProgram));
            return null;
        }

        return shaderProgram;
    },
    loadShader(gl, type, source) {
        const shader = gl.createShader(type);

        gl.shaderSource(shader, source);
        gl.compileShader(shader);

        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
            alert('An error occurred compiling the shaders: ' + gl.getShaderInfoLog(shader));
            gl.deleteShader(shader);
            return null;
        }

        return shader;
    },
    createState() {
        return {
            time: 0,
            delta: 0,
            vrDisplay: null,
            vrInitialized: false,
            vrInit: false
        };
    },
    loop(gl, state, canvas, cleanDrawback, drawCallback, updateCallback) {

        function render(now) {
            if(!state.vrInitialized && state.vrInit) {
                new WebVRPolyfill();
                if (navigator.getVRDisplays) {
                    navigator.getVRDisplays().then(displays => {
                        console.log(displays);
                        if (displays.length) {
                            let display = displays[0];
                            display = displays[0];
                            display.depthNear = 0.1;
                            display.depthFar = 100;
                            state.vrDisplay = display;
                            state.vrInitialized = true;
                            display.requestPresent([{ source: canvas }]);
                        }
                    });
                }
            }
            if (state.vrDisplay && state.vrDisplay.isPresenting) {
                const eye = state.vrDisplay.getEyeParameters("left");
                canvas.width = eye.renderWidth * 2;
                canvas.height = eye.renderHeight;
            }


            now *= 0.001;  // convert to seconds
            state.delta = now - state.time;
            state.time = now;
            updateCallback(gl, state);
            cleanDrawback(gl);
            if(state.vrDisplay && state.vrDisplay.isPresenting) {
                // eslint-disable-next-line no-undef
                let frameData = new VRFrameData();
                state.vrDisplay.getFrameData(frameData);

                gl.viewport(0, 0, canvas.width / 2, canvas.height);

                drawCallback(gl, state, frameData.leftViewMatrix, frameData.leftProjectionMatrix);

                gl.viewport(canvas.width / 2, 0, canvas.width / 2, canvas.height);
                drawCallback(gl, state, frameData.rightViewMatrix, frameData.rightProjectionMatrix);

                state.vrDisplay.submitFrame();
            } else {
                gl.viewport(0, 0, canvas.width, canvas.height);
                drawCallback(gl, state, null, null);
            }

            if(state.vrDisplay) {
                state.vrDisplay.requestAnimationFrame(render);
            } else {
                requestAnimationFrame(render);
            }
        }

        requestAnimationFrame(render);
    },
    getProgramInfo(gl, shaderProgram){
        return {
            program: shaderProgram,
                time: 0,
            attribLocations: {
            vertexPosition: gl.getAttribLocation(shaderProgram, 'aVertexPosition'),
                vertexNormal: gl.getAttribLocation(shaderProgram, 'aVertexNormal'),

            },
            uniformLocations: {
                projectionMatrix: gl.getUniformLocation(shaderProgram, 'uProjectionMatrix'),
                viewMatrix: gl.getUniformLocation(shaderProgram, 'uViewMatrix'),
                modelMatrix: gl.getUniformLocation(shaderProgram, 'uModelMatrix'),
            },
        };
    },
    getMesh(gl, geometry){
        let vertices = geometry.attributes.position.array;
        let normals =  geometry.attributes.normal.array;
        let indices = geometry.index.array;
        let indices_count = indices.length;

        let vertex_buffer = gl.createBuffer();
        let normal_buffer = gl.createBuffer();
        let index_buffer = gl.createBuffer();

        gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
        gl.bindBuffer(gl.ARRAY_BUFFER, normal_buffer);
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(normals), gl.STATIC_DRAW);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, index_buffer);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(indices), gl.STATIC_DRAW);
        return  {
            ic: indices_count,
            vb: vertex_buffer,
            nb: normal_buffer,
            ib: index_buffer
        };
    },
    drawMesh(gl, programInfo, mesh) {
        gl.bindBuffer(gl.ARRAY_BUFFER, mesh.vb);
        gl.vertexAttribPointer(programInfo.attribLocations.vertexPosition, 3, gl.FLOAT, false, 0, 0);
        gl.enableVertexAttribArray(programInfo.attribLocations.vertexPosition);

        gl.bindBuffer(gl.ARRAY_BUFFER, mesh.nb);
        gl.vertexAttribPointer(programInfo.attribLocations.vertexNormal, 3, gl.FLOAT, false, 0, 0);
        gl.enableVertexAttribArray(programInfo.attribLocations.vertexNormal);

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ib);

        gl.drawElements(gl.TRIANGLES, mesh.ic, gl.UNSIGNED_SHORT, 0);
    },
    enableVr(state) {
        state.vrInit = true;
    }
}