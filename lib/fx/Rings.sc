RingsPedal : Pedal {
  *id { ^\rings; }
  *addOnBoot { ^false; }

  *fxArguments { ^[\pit, \follow, \interval, \struct, \bright, \damp, \pos, \poly, \model, \easteregg]; }

  *fxDef {^{|wet|
    var trig=0, pit, struct, bright, damp, pos, model, poly, intern_exciter=0, easteregg, followFreq, freqClarity, followNote;
    # followFreq, freqClarity = Pitch.kr(wet[0], initFreq: 0, minFreq: 30, maxFreq: 4200, ampThreshold: 0.02, median: 7, clar: 1);
    followFreq = Select.kr(followFreq, [220, followFreq]);
    // Convert to pitch number
    followNote = max(0, min(127, floor((12 * log(followFreq / 440.0) / log(2)) + 57.5)));
    followNote = followNote + \interval.kr(0);
    pit = Select.kr(\follow.kr(1), [\pit.kr(60), followNote]);

    struct = \struct.kr(0.36);
    bright = \bright.kr(0.5);
    damp = \damp.kr(0.5);
    pos = \pos.kr(0.33);
    poly = \poly.kr(4);
    model = \model.kr(0);
    easteregg = \easteregg.kr(0);
    wet = MiRings.ar(wet, trig, pit, struct, bright, damp, pos, model, poly, intern_exciter, easteregg);
  }}
}

