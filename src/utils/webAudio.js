
export default {

    initializeArray: function(array) {
        for(let i=0; i < array.length; ++i) {
            array[i] = 0;
        }
    },

    createArray: function(len, xFunc, yFunc) {
        const array = new Array(len);
        for(let i=0; i < len; ++i) {
            array[i] = { x: xFunc(i), y: yFunc(i)};
        }
        return array;
    },

    clamp: function(val, min, max){
        return val<min ? min : val> max ? max : val;
    },

    updateDataArray: function(analyser, dataArray) {
        if(analyser) {
            analyser.getByteTimeDomainData(dataArray);
        }
        return this.createArray(
            dataArray.length,
            (i) => (i / dataArray.length),
            (i) => 2.0*dataArray[i]/255.0-1);
    },

    updateFrequencyArray: function(analyser, freqArray, maxFreq) {
        if(analyser) {
            analyser.getFloatFrequencyData(freqArray);
        }
        return this.createArray(
            freqArray.length,
            (i) => (i / freqArray.length)*maxFreq,
            (i) =>  this.clamp(freqArray[i], analyser.minDecibels, analyser.maxDecibels));
    }
}