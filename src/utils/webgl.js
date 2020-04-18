// eslint-disable-next-line no-unused-vars
import WebXRPolyfill from "webxr-polyfill";
import * as glm from "gl-matrix";

export default {

    initShaderProgram: function(gl, vsSource, fsSource) {
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
    loadShader: function(gl, type, source) {
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
    createState: function(cleanDrawback, drawCallback, updateCallback) {
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
            width: 0,
            height: 0,
            vrSupported: false,
            tick: function(now){
                now *= 0.001;  // convert to seconds
                this.delta = now - this.time;
                this.time = now;
            },
            log: '',
        };
    },
    loopVr: function(gl, state) {
        function render(now, frame) {
            let session = frame.session;
            if(state.vrInitialized) {
                state.animation = session.requestAnimationFrame(render);
            }

            let pose = null;
            if (state.vrSpace && frame) {
                pose = frame.getViewerPose(state.vrSpace);
            }

            state.tick(now);
            state.updateCallback(gl, state);

            if (pose) {
                let layer = session ? session.renderState.baseLayer : null;
                state.cleanDrawback(gl, state, layer.framebuffer);

                for (let view of pose.views) {
                    let viewport = layer.getViewport(view);
                    state.width = viewport.width;
                    state.height = viewport.height;
                    gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height);
                    state.drawCallback(gl, state, view.transform.inverse.matrix, view.projectionMatrix, layer.framebuffer);
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
                console.log(space);
                // state.vrSpace =  space.getOffsetReferenceSpace(new XRRigidTransform(glm.vec3.fromValues(0,-1.60,0), glm.quat.create()) );
                state.vrSpace =  space;
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
    loop: function(gl, state) {

        function render(now) {
            if(!state.vrInitialized) {
                state.animation = requestAnimationFrame(render);
            }

            state.tick(now);
            state.updateCallback(gl, state);

            state.cleanDrawback(gl, state, null);
            state.width = gl.canvas.width;
            state.height = gl.canvas.height;
            gl.viewport(0, 0, gl.canvas.width, gl.canvas.height);
            state.drawCallback(gl, state, null, null);

        }
        state.animation = requestAnimationFrame(render);
    },
    getProgramInfo: function(gl, shaderProgram){
        return {
            program: shaderProgram,
                time: 0,
            attribLocations: {
                vertexPosition: gl.getAttribLocation(shaderProgram, 'aVertexPosition'),
                vertexNormal: gl.getAttribLocation(shaderProgram, 'aVertexNormal'),
                textureCoordinates: gl.getAttribLocation(shaderProgram, 'aTextureCoordinates'),
            },
            uniformLocations: {
                projectionMatrix: gl.getUniformLocation(shaderProgram, 'uProjectionMatrix'),
                viewMatrix: gl.getUniformLocation(shaderProgram, 'uViewMatrix'),
                modelMatrix: gl.getUniformLocation(shaderProgram, 'uModelMatrix'),
                sampler0: gl.getUniformLocation(shaderProgram, 'uSampler0'),
                sampler1: gl.getUniformLocation(shaderProgram, 'uSampler1'),
                enableLight: gl.getUniformLocation(shaderProgram, 'uEnableLight'),
                drawMode: gl.getUniformLocation(shaderProgram, 'uDrawMode'),
                drawVariant: gl.getUniformLocation(shaderProgram, 'uDrawVariant'),
                time: gl.getUniformLocation(shaderProgram, 'uTime'),
                lightDirection: gl.getUniformLocation(shaderProgram, 'uLightDirection'),
                cameraPosition: gl.getUniformLocation(shaderProgram, 'uCameraPosition'),
            },
        };
    },
    createArrayBuffers: function(gl, vertices, normals, texture_coordinates, indices, image){
        let indices_count = indices.length;

        let vertex_buffer = gl.createBuffer();
        let normal_buffer = gl.createBuffer();
        let index_buffer = gl.createBuffer();
        let texture_coordinates_buffer = gl.createBuffer();

        gl.bindBuffer(gl.ARRAY_BUFFER, vertex_buffer);
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
        gl.bindBuffer(gl.ARRAY_BUFFER, normal_buffer);
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(normals), gl.STATIC_DRAW);
        gl.bindBuffer(gl.ARRAY_BUFFER, texture_coordinates_buffer);
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(texture_coordinates), gl.STATIC_DRAW);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, index_buffer);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(indices), gl.STATIC_DRAW);
        return  {
            ic: indices_count,
            vb: vertex_buffer,
            nb: normal_buffer,
            tb: texture_coordinates_buffer,
            ib: index_buffer,
            im: image
        };
    },
    createBillboard: function(gl) {
        let vertices = [1, -1, 0, 1, 1, 0, -1, 1, 0, -1, -1, 0];
        let normals = [0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1];
        let texture_coordinates = [1, 1, 1, 0, 0, 0, 0, 1];
        let indices = [0, 1, 2, 0, 2, 3];
        return this.createArrayBuffers(gl, vertices, normals, texture_coordinates, indices, null);
    },
    getCylinderMesh: function(gl, image) {
        let vertices = [];
        let normals = [];
        let texture_coordinates = [];
        let indices = [];

        const height = 128;
        const definitionA = 16;

        // eslint-disable-next-line no-unused-vars
        const definitionH = 0.5;

        for(let h=0; h <= height; ++h){
            for(let a=0; a <= definitionA; ++a){
                let x = Math.sin((2*Math.PI*a/definitionA) );
                let y = h*definitionH;
                let z = Math.cos((2*Math.PI*a/definitionA) );
                vertices.push(x);
                vertices.push(y);
                vertices.push(z);
                normals.push(x);
                normals.push(0);
                normals.push(z);
                texture_coordinates.push(y);
                texture_coordinates.push(2.0*a/definitionA);
            }
        }
        for(let h=0; h < height; ++h){
            for(let a=0; a < definitionA; ++a){
                indices.push((h+0)*(definitionA+1)+(a+0));
                indices.push((h+0)*(definitionA+1)+(a+1));
                indices.push((h+1)*(definitionA+1)+(a+1));

                indices.push((h+0)*(definitionA+1)+(a+0));
                indices.push((h+1)*(definitionA+1)+(a+1));
                indices.push((h+1)*(definitionA+1)+(a+0));
            }
        }
        return this.createArrayBuffers(gl, vertices, normals, texture_coordinates, indices, image);
    },
    getMesh: function(gl, mesh) {
        let geometry = mesh.geometry;
        if(!geometry || !geometry.attributes) {
            return null;
        }

        let vertices = geometry.attributes.position.array;
        let normals =  geometry.attributes.normal.array;
        let texture_coordinates =  geometry.attributes.uv.array;
        let indices = geometry.index.array;
        let image = mesh.material.map.image;

        return this.createArrayBuffers(gl, vertices, normals, texture_coordinates, indices, this.loadImage(gl, image) );
    },
    enableAttribs: function(gl, programInfo){
        gl.enableVertexAttribArray(programInfo.attribLocations.vertexPosition);
        gl.enableVertexAttribArray(programInfo.attribLocations.vertexNormal);
        gl.enableVertexAttribArray(programInfo.attribLocations.textureCoordinates);
    },
    disableAttribs: function(gl, programInfo){
        gl.disableVertexAttribArray(programInfo.attribLocations.vertexPosition);
        gl.disableVertexAttribArray(programInfo.attribLocations.vertexNormal);
        gl.disableVertexAttribArray(programInfo.attribLocations.textureCoordinates);
    },
    drawMesh: function(gl, programInfo, mesh, image0, image1) {

        gl.bindBuffer(gl.ARRAY_BUFFER, mesh.vb);
        gl.vertexAttribPointer(programInfo.attribLocations.vertexPosition, 3, gl.FLOAT, false, 0, 0);

        gl.bindBuffer(gl.ARRAY_BUFFER, mesh.nb);
        gl.vertexAttribPointer(programInfo.attribLocations.vertexNormal, 3, gl.FLOAT, false, 0, 0);

        gl.bindBuffer(gl.ARRAY_BUFFER, mesh.tb);
        gl.vertexAttribPointer(programInfo.attribLocations.textureCoordinates, 2, gl.FLOAT, false, 0, 0);

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ib);

        if(!image0) {
            image0 = mesh.im;
        }
        if(!image1) {
            image1 = image0;
        }

        if(image0) {
            gl.uniform1i(programInfo.uniformLocations.sampler0, 0);
            gl.activeTexture(gl.TEXTURE0);
            gl.bindTexture(gl.TEXTURE_2D, image0);
        }
        if(image1) {
            gl.uniform1i(programInfo.uniformLocations.sampler1, 1);
            gl.activeTexture(gl.TEXTURE1);
            gl.bindTexture(gl.TEXTURE_2D, image1);
        }

        gl.drawElements(gl.TRIANGLES, mesh.ic, gl.UNSIGNED_SHORT, 0);
    },
    enableVr: function(state) {
        state.vrInit = true;
    },
    isPowerOf2: function(value) {
        return (value & (value - 1)) === 0;
    },
    generateMipmap: function(gl, image) {
        if (this.isPowerOf2(image.width) && this.isPowerOf2(image.height)) {
            gl.generateMipmap(gl.TEXTURE_2D);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
        } else {
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
        }
    },
    loadImage: function(gl, image){
        const texture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, texture);
        const level = 0;
        const internalFormat = gl.RGBA;
        const width = 1;
        const height = 1;
        const border = 0;
        const srcFormat = gl.RGBA;
        const srcType = gl.UNSIGNED_BYTE;
        const pixel = new Uint8Array([0, 0, 255, 255]);  // opaque blue
        gl.texImage2D(gl.TEXTURE_2D, level, internalFormat, width, height, border, srcFormat, srcType, pixel);

        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texImage2D(gl.TEXTURE_2D, level, internalFormat, srcFormat, srcType, image);
        this.generateMipmap(gl, image);
        return texture;
    },
    loadTexture: function(gl, url) {
        const texture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, texture);

        const level = 0;
        const internalFormat = gl.RGBA;
        const width = 1;
        const height = 1;
        const border = 0;
        const srcFormat = gl.RGBA;
        const srcType = gl.UNSIGNED_BYTE;
        const pixel = new Uint8Array([0, 0, 255, 255]);  // opaque blue
        gl.texImage2D(gl.TEXTURE_2D, level, internalFormat, width, height, border, srcFormat, srcType, pixel);

        const image = new Image();
        let that = this;

        image.onload = function() {
            gl.bindTexture(gl.TEXTURE_2D, texture);
            gl.texImage2D(gl.TEXTURE_2D, level, internalFormat, srcFormat, srcType, image);
            that.generateMipmap(gl, image);
        };
        image.src = url;

        return texture;
    },

    getBillboardMatrix: function(position, cameraPos, cameraUp) {
        let to = glm.vec3.subtract(glm.vec3.create(), cameraPos, position);
        let look = glm.vec3.normalize(to, to);
        let right = glm.vec3.cross(glm.vec3.create(), cameraUp, look);
        let up2 = glm.vec3.cross(glm.vec3.create(), look, right);

        return glm.mat4.fromValues(
            right[0],right[1],right[2],0,
            up2[0],up2[1],up2[2],0,
            look[0],look[1],look[2],0,
            position[0],position[1],position[2],1
        );
    },
    createFramebuffer: function (gl, width, height) {
        // texture
        let maskTexture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, maskTexture);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);

        // render
        let maskRenderBuffer = gl.createRenderbuffer();
        gl.bindRenderbuffer(gl.RENDERBUFFER, maskRenderBuffer);
        gl.renderbufferStorage(gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, width, height);

        // frame
        let maskFramebuffer = gl.createFramebuffer();
        gl.bindFramebuffer(gl.FRAMEBUFFER, maskFramebuffer);
        gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, maskTexture, 0);
        gl.framebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, maskRenderBuffer);

        let e = gl.checkFramebufferStatus(gl.FRAMEBUFFER);
        if(gl.FRAMEBUFFER_COMPLETE !== e) {
            console.error("ERROR", e.toString());
        }
        // Unbind the buffer object
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
        gl.bindTexture(gl.TEXTURE_2D, null);
        gl.bindRenderbuffer(gl.RENDERBUFFER, null);
        return {
            texture: maskTexture,
            render: maskRenderBuffer,
            frame: maskFramebuffer,
            width: width,
            height: height
        };
    },
    deleteFramebuffer: function (gl, obj) {
        if (obj.frame) gl.deleteFramebuffer(obj.frame);
        if (obj.texture) gl.deleteTexture(obj.texture);
        if (obj.render) gl.deleteRenderbuffer(obj.render);
    },
    getFramebufferTexture: function(gl) {
        return gl.getFramebufferAttachmentParameter(gl.READ_FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.FRAMEBUFFER_ATTACHMENT_OBJECT_NAME);
    },
}