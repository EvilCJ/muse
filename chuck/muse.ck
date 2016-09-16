//******************************************************************
// Run as: chuck muse.ck:[serialport]
//******************************************************************


// Getting the serial device
SerialIO.list() @=> string list[];
for (int i; i < list.cap(); i++) {
    chout <= i <= ": " <= list[i] <= IO.newline();
}

// parse first argument as device number
0 => int device;
if (me.args())
    me.arg(0) => Std.atoi => device;
if (device >= list.cap()) {
    cherr <= "serial device #" <= device <= " not available\n";
    me.exit();
}

SerialIO cereal;
if (!cereal.open(device, SerialIO.B9600, SerialIO.ASCII)) {
    chout <= "unable to open serial device '" <= list[device] <= "'\n";
    me.exit();
}


// Connecting serial input to chuck controls. Most values are in between 0 and
// 2^12 (4096) because of the 12 bit ADC on the redbear duo, but the pitch level
// coming is discrete and depends on which fingers are being pressed. This value
// ranges from 0 and 15 (2^4 fingers). The data is piped in from the arduino
// based on which pin it was read from, and then applied relevantly.
Muse m;
while (true) {
    cereal.onLine() => now;
    cereal.getLine() => string line;
    if(line$Object != null) {
        StringTokenizer tok; tok.set(line);
        Std.atoi(tok.next()) => int pin;
        Std.atoi(tok.next()) => int val;

        if (pin == 10)
            m.level(val);
        if (pin == 11)
            m.modu(val);
        if (pin == 12)
            m.tempo(val);
        if (pin == 13)
            m.scale(val);
        if (pin == 14)
            m.bend(val);
        if (pin == 15)
            m.pitch(val);
    }
}

/* Controls
- gain
- modu
- width
- bend
- scale, or perhaps background noise
- pitch
*/

class Muse {
    // Setting up the carrier
    PulseOsc pls => dac;
    0.5 => pls.width;
    0.002 => float inc;
    1.0 => float iscale;
    1.0 => float ibend;
    1.0 => float imodu;
    0.0 => float t;

    // change the gain level
    fun void level (int l)
    {
        l/1024.0 => pls.gain; // range from 0, 4
    }

    // change duty cycle
    fun void modu (int m)
    {
        0.5 + (m/8196.0) => pls.width; // range from 0.25, 0.75
    }

    // change inner freq
    fun void tempo (int ti)
    {
        ti/8196.0 => inc; // range from 0, 0.5
        t + inc => t;
    }

    // change note scale
    fun void scale (int s)
    {
        1 + (s/1024.0) => iscale; // range from 1, 5
    }

    // bend the frequency
    fun void bend (int b)
    {
        0.95 + 1.0595 * (b/4096.0) => ibend;
    }

    // use whole notes w/ chuck library
    fun void pitch(int p)
    {
        p * (55 + (Math.sin(t) + 1)
            * Std.mtof(p + 20) * iscale * ibend) => pls.freq;
    }
}

