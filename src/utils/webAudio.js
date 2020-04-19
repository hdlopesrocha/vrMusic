export default {

    initializeArray: function (array) {
        for (let i = 0; i < array.length; ++i) {
            array[i] = 0;
        }
    },

    clamp: function (val, min, max) {
        return val < min ? min : val > max ? max : val;
    },

    myNoise3d: function (noise, x, y, z, l) {
        var v = noise.simplex3(x / l, y / l, z / l);
        return 0.5 * (v + 1);
    },

    myNoise3dx: function (noise, x, y, z, l) {
        var il = l;
        var pe = 0.5;
        var re = 0;
        for (var i = 0; i < 7; ++i) {
            re += pe * this.myNoise3d(noise, x, y, z, il);
            il *= 0.5;
            pe *= 0.5;
        }
        return re;
    },


    // eslint-disable-next-line no-unused-vars
    updateAudioArray: function (analyser, len, dataArray, freqArray, noise, time) {
        // eslint-disable-next-line no-unused-vars
        const array = new Uint8Array(len);

        if (analyser) {
            analyser.getByteTimeDomainData(dataArray);
         //   analyser.getByteFrequencyData(freqArray);
        }
       /* let ratio = 1.0 /len;
        for (let i = 0; i < len; ++i) {
            array[i * 3 + 0] = dataArray[i];
            array[i * 3 + 1] = freqArray[i];
            array[i * 3 + 2] = this.myNoise3dx(noise, time, i*ratio , 0.0, 0.1) * 255;
        }*/
        //console.log(array);
        return dataArray;
    },

}