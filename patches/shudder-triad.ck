

49 => int IDX_STOP_ALL;

13 => int SLIDER_HARMONIC_ID;
14 => int SLIDER_LPF_ID;
15 => int SLIDER_HPF_ID;
16 => int SLIDER_ATTACK_ID;
17 => int SLIDER_RELEASE_ID;

0 => int isCapturing;
1 => int midiDeviceIndex;
1 => int enableOsc;
0.85 => float gNormalizeGain;
0.5 => float gHarmonicLevel;

1.0::second => dur attack;
3.5::second => dur release;

class StopEvent extends Event {
    int index;
}
StopEvent evtStop;

OscSend oscTransmitter;

// stereo separator for chuck hits
Gain gSeparator;
Pan2 separator => dac;
Delay gSeparatorDelay;
5::ms => gSeparatorDelay.delay;
gSeparator => separator.left;
gSeparator => gSeparatorDelay => separator.right;

LPF fLpfLeft => HPF fHpfLeft => dac;
20000 => fLpfLeft.freq;
100 => fHpfLeft.freq;
0.985 => fHpfLeft.Q;
0.985 => fLpfLeft.Q;
LPF fLpfRight => HPF fHpfRight => gSeparator;
20000 => fLpfRight.freq;
100 => fHpfRight.freq;
0.985 => fHpfRight.Q;
0.985 => fLpfRight.Q;

gNormalizeGain => fHpfLeft.gain;
gNormalizeGain => fHpfRight.gain;

0 => float globalPitchOffset;
0 => float globalGlitchProb;

// keep unfiltered input in its own shred
adc.left => ADSR unfilteredEnv => dac;
unfilteredEnv.set(attack, 0.1::second, 0.7, release);
0 => unfilteredEnv.gain;

// midi control
fun void midiListen() {
    MidiIn min;
    MidiMsg msg;
    if (!min.open(midiDeviceIndex)) me.exit();
    while (true) {
        min => now;
        while (min.recv(msg)) {
            if (msg.data1 == 176) { // knob twist
                " " => string description;
                if (msg.data2 == 3) {
                    ((msg.data3 $ float / 127.0) * -2.0) => globalPitchOffset;
                    <<< "Pitch offset", globalPitchOffset >>>;
                } else if (msg.data2 == 9) {
                    (msg.data3 $ float / 127.0) => globalGlitchProb;
                    <<< "Glitch probability", globalGlitchProb >>>;
                } else if (msg.data2 == 12) {
                    (msg.data3 $ float / 127.0) => float unfilteredGain;
                    unfilteredGain * 0.8 => unfilteredEnv.gain;
                    <<< "Monitor:", unfilteredGain >>>;
                    unfilteredGain * 100 + "%" => description;
                } else if (msg.data2 == SLIDER_HPF_ID) {
                    msg.data3 $ float / 127.0 => float val;
                    100.0 + Math.pow(2, val * 14.2876) => fHpfLeft.freq;
                    fHpfLeft.freq() => fHpfRight.freq;
                    <<< "HPF Hz:", fHpfLeft.freq() >>>;
                    fHpfLeft.freq() + " Hz" => description;
                } else if (msg.data2 == SLIDER_HARMONIC_ID) {
                    msg.data3 $ float / 127.0 => gHarmonicLevel;
                    <<< "Harmonic level:", gHarmonicLevel >>>;
                } else if (msg.data2 == SLIDER_LPF_ID) {
                    msg.data3 $ float / 127.0 => float val;
                    20.0 + Math.pow(2, val * 14.2876) => fLpfLeft.freq;
                    fLpfLeft.freq() => fLpfRight.freq;
                    <<< "LPF Hz:", fLpfLeft.freq() >>>;
                    fLpfLeft.freq() + " Hz" => description;
                    
                } else if (msg.data2 == SLIDER_ATTACK_ID) {
                    (0.001 + (msg.data3 $ float / 127.0) * 5.0) => float numSeconds;
                    <<< "Attack seconds:", numSeconds >>>;
                    numSeconds::second => attack;
                    "" + numSeconds => description;
                } else if (msg.data2 == SLIDER_RELEASE_ID) {
                    (0.001 + (msg.data3 $ float / 127.0) * 5.0) => float numSeconds;
                    <<< "Release seconds:", numSeconds >>>;
                    numSeconds::second => release;
                    "" + numSeconds => description;
                }
                if (enableOsc) {
                    transmitOscValue(0, msg.data2, msg.data3, description);
                }
            } else if (msg.data1 == 153) { // pad hit
                msg.data2 - 36 => int index;
                if (index == 0 || index == 16 || index == 32) {
                    // first pad - reset state
                    resetAll();
                } else {
                    akaiRange(msg.data3) => float level;
                    magString(level) => string levelStr;
                    <<< "Hit ", levelStr, ">   ", index >>>;
                    // TODO: mapping index to triads
                    // mode 1: major
                    // mode 2: minor
                    // TODO: add shudder
                    spork ~ hit(fLpfRight, -1 + index + 12 + 7, level * 0.5);
                    spork ~ hit(fLpfRight, -1 + index + 12 + 7 + 12 + 7, level * 0.5 * gHarmonicLevel);
                }
            } else if (msg.data1 == 137) { // pad release
                msg.data2 - 36 => int index;
                index => evtStop.index;
                evtStop.broadcast();
            } else {
                // <<< msg.data1, msg.data2, msg.data3 >>>;
            }
        }
    }
}

fun string magString(float val) {
    0 => float comparator;
    "-" => string result;
    while (comparator < val && comparator < 1.0) {
        "-" +=> result;
        0.1 +=> comparator;
    }
    return result;
}

fun float akaiRange(int midiVal) {
    37 + (Math.max(37, midiVal) - 37) $ int => int clampedVal;
    return clampedVal $ float / 128.0;
}

fun void hit(UGen out, int index, float level) {
    PitShift shift;
    adc.left => shift => ADSR env => out;
    1 => shift.mix;
    // SqrOsc sOsc => ADSR env => out;
    env.set(attack, 0.1::second, 0.7, release);
    level => env.gain;
    
    // 440.0 * Math.pow(2, index / 12.0) => sOsc.freq;
    Math.pow(2, (index + globalPitchOffset) / 12.0) => shift.shift;
    spork ~ watchPitch(shift, index);
    1 => env.keyOn;
    while (evtStop => now) {
        if (evtStop.index == index || evtStop.index + 12 + 7 == index || evtStop.index == IDX_STOP_ALL) break;
    }
    1 => env.keyOff;
    env.releaseTime() => now;
    env =< out;
    return;
}

fun void watchPitch(PitShift shift, int index) {
    index => int offsetIndex;
    0 => int isOffset;
    while (1::ms => now) {
        if (globalGlitchProb > 0) {
            if (!isOffset && Math.randomf() < 0.01 * globalGlitchProb) {
                12 +=> offsetIndex;
                1 => isOffset;
                if (fHpfLeft.freq() > 3500.0) {
                    Math.random2f(-0.5, 0.5) => separator.pan;
                } else {
                    // this sounds funny when run thru a low lpf, so disable it
                    0 => separator.pan;
                }
            } else if (isOffset && Math.randomf() < 0.005) {
                0 => isOffset;
                index => offsetIndex;
            }
        } else {
            0 => isOffset;
            index => offsetIndex;
        }
        Math.pow(2, (offsetIndex + globalPitchOffset) / 12.0) => shift.shift;
    }
}

fun void resetAll() {
    IDX_STOP_ALL => evtStop.index;
    <<< "Stop" >>>;
    evtStop.broadcast();
}

fun void transmitOscValue(int type, int param, int value, string description) {
    oscTransmitter.startMsg("/param", "i i i s");
    type => oscTransmitter.addInt;
    param => oscTransmitter.addInt;
    value => oscTransmitter.addInt;
    description => oscTransmitter.addString;
    return;
}

if (enableOsc) {
    oscTransmitter.setHost("localhost", 4242);
}
spork ~ midiListen();
1 => unfilteredEnv.keyOn;

while (1::day => now);

