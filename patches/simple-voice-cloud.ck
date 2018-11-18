
class VoiceCloud {
    fun void run(UGen in, UGen out) {
        0::ms => dur maxLifespan;
        for (0 => int ii; ii < 14; ii++) {
            Voice v;
            spork ~ v.run(in, out, ii);
            // await spork
            1::ms => now;
            v.getLifespan() => dur lifespan;
            if (lifespan > maxLifespan) {
                lifespan => maxLifespan;
            }
        }
        maxLifespan => now;
    }
}

class Voice {
    PitShift _p;
    ADSR _env;
    int _index;
    fun void run(UGen in, UGen out, int index) {
        index => _index;
        in => _p => _env => out;
        _env.set((1 + index)::second, 1::ms, 0.99, (1 + index)::second);
        1 => _p.mix;
        this._getShift(index) => _p.shift;
        1 => _env.keyOn;
        _env.attackTime() => now;
        1 => _env.keyOff;
        _env.releaseTime() => now;
        in =< _p;
        _env =< out;
    }

    fun dur getLifespan() {
        // align with intervals in run()
        return (
            (1 + _index)::second +
            (1 + _index)::second
            );
    }

    fun float _getShift(int index) {
        [ 0, 2, 3, 5, 7, 9, 10, 12 ] @=> int intervals[];
        intervals[index % intervals.cap()] => int scaleIndex;
        return Math.pow(2.0, (scaleIndex $ float) / 12.0);
    }
}

VoiceCloud test;
spork ~ test.run(adc.left, dac);

while (1::day => now);
