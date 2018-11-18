
// arturia beatstep sequencer 2 channel
8 => int channel;

0 => int isMidiStopped;

class MidiOutFormatter {
    MidiOut mOut;
    MidiMsg midiMessage;

    fun int open(int id) {
        return mOut.open(id);
    }

    fun void noteOn(int notenum, int velocity, int channel) {
        send_3bytes(0x9, channel, notenum, velocity);
    }

    fun void noteOff(int notenum, int channel) {
        noteOn(notenum, 0, channel);
    }

    fun void controller(int controllernum, int value, int channel) {
        send_3bytes(0xb, channel, controllernum, value);
    }

    fun void panic(int channel) {
        // all notes off
        controller(123, 0, channel);
        5::ms => now;
        // all sound off
        controller(120, 0, channel);
    }

    // from http://www.rattus.net/~packrat/audio/ChucK/files/midisender.ck
    fun void send_3bytes(int command, int channel, int byte1, int byte2) {
        ((command & 0xf) << 4) | ((channel - 1) & 0xf) => midiMessage.data1;
        command | channel => command;
        byte1 & 0x7f  => midiMessage.data2;
        byte2 & 0x7f => midiMessage.data3;
        mOut.send(midiMessage);
    }
}

fun void listenForKeyboardStop() {
    Hid hi;
    HidMsg msg;
    // open keyboard (get device number from command line)
    if(!hi.openKeyboard(0)) me.exit();
    <<< "keyboard '" + hi.name() + "' ready", "" >>>;
    while (true) {
        hi => now;
        while (hi.recv(msg)) {
            if (msg.isButtonDown()) {
                if (msg.ascii == 32) {
                1 => isMidiStopped;
                break;
                }
            }
        }
    }
}

fun void doMidiThings() {
    MidiOutFormatter m;
    if (!m.open(0)) {
        <<< "failed to open midi" >>>;
        me.exit();
    }

    33 => int base; // A2
    [ base, base + 5, base + 7, base + 10 ] @=> int seq[];

    while (!isMidiStopped) {
        seq[Math.random2(0, seq.cap() - 2)] => int note;
        for (0 => int ii; ii < 3; ii++) {
            if (Math.randomf() < 0.3) {
                12 +=> note;
            }
        }
        <<< note - base >>>;
        m.noteOn(note, 127, channel);
        50::ms => now;
        m.noteOff(note, channel);
        25::ms => now;
    }

    <<< "ending all midi" >>>;
    m.panic(channel);
}

spork ~ listenForKeyboardStop();
doMidiThings();

