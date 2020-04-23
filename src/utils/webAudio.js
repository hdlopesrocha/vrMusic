export default {

    initializeArray: function (array) {
        for (let i = 0; i < array.length; ++i) {
            array[i] = 0;
        }
    },

    myNoise3d: function (noise, x, y, z, l) {
        var v = noise.simplex3(x / l, y / l, z / l);
        return 0.5 * (v + 1);
    },

    myNoise3dx: function (noise, x, y, z, l) {
        var il = l;
        var pe = 1.0;
        var re = 0;
        for (var i = 0; i < 7; ++i) {
            pe *= 0.5;
            re += pe * this.myNoise3d(noise, x, y, z, il);
            il *= 0.5;
        }
        re += pe * this.myNoise3d(noise, x, y, z, il);

        return re;
    },
    max(array) {
        let m = 0;
        for (let i = 0; i < array.length; ++i) {
            m = Math.max(m, array[i]);
        }
        return m;
    }
}