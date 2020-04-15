// eslint-disable-next-line no-unused-vars
import WebXRPolyfill from "webxr-polyfill";

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
    createState(cleanDrawback, drawCallback, updateCallback) {
        return  {
            time: 0,
            delta: 0,
            vrInitialized: false,
            vrSession: null,
            vrSpace: null,
            animation: null,
            cleanDrawback: cleanDrawback,
            drawCallback: drawCallback,
            updateCallback: updateCallback,
            vrSupported: false,
            tick: function(now){
                now *= 0.001;  // convert to seconds
                this.delta = now - this.time;
                this.time = now;
            },
            log: '',
        };
    },
    loopVr(gl, state) {
        function render(now, frame) {

            let session = frame.session;
            state.animation = session.requestAnimationFrame(render);


            let pose = null;
            if (state.vrSpace && frame) {
                pose = frame.getViewerPose(state.vrSpace);
            }

            state.tick(now);
            state.cleanDrawback(gl, state);
            state.updateCallback(gl, state);


            if (pose) {
                let layer = session ? session.renderState.baseLayer : null;
                gl.bindFramebuffer(gl.FRAMEBUFFER, layer.framebuffer);

                for (let view of pose.views) {
                    let viewport = layer.getViewport(view);
                    gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height);
                    state.drawCallback(gl, state, view.transform.inverse.matrix, view.projectionMatrix);
                    state.log = JSON.stringify(view.transform.matrix) + ":" + now;

                }
            }
        }

        // eslint-disable-next-line no-unused-vars
        function onSessionEnded(event) {

        }

        function onSessionStarted(session) {
            session.addEventListener('end', onSessionEnded);
            session.updateRenderState({
                // eslint-disable-next-line no-undef
                baseLayer: new XRWebGLLayer(session, gl)
            });
            session.requestReferenceSpace('local').then(space => {
                state.vrSession = session;
                state.vrSpace = space;
                state.animation = session.requestAnimationFrame(render);
            });
            console.log(session);
            return session;
        }

        if(!state.vrInitialized) {
            state.vrInitialized = true;
            new WebXRPolyfill();
            if (navigator.xr) {
                navigator.xr.isSessionSupported('immersive-vr').then((supported) => {

                    state.vrSupported = supported;
                    navigator.xr.requestSession('immersive-vr').then(onSessionStarted);

                });
            }
        }
    },


    loop(gl, state) {

        function render(now) {
            state.tick(now);
            state.cleanDrawback(gl, state);
            state.updateCallback(gl, state);

            gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
            state.drawCallback(gl, state, null, null);
            state.animation = requestAnimationFrame(render);
        }

        state.animation = requestAnimationFrame(render);
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