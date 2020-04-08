ReverbPedal : Pedal {
  *id { ^\reverb; }

  *fxArguments { ^[\size, \decay, \tone]; }

  *fxDef {^{|wet|
    // Adapted from @justmat's Pools
    // TODO: in fact, maybe add shimmer?
    var size, decay, tone, t60, reverbSize, decayBySize, damp, earlyDiff, freq, filterType;

    // Tone controls a MMF, exponentially ranging from 10 Hz - 21 kHz
    // Tone above 0.75 switches to a HPF
    tone = \tone.kr(0.5);
    freq = Select.kr(tone > 0.75, [
      Select.kr(tone > 0.2, [
        LinExp.kr(tone, 0, 0.2, 10, 400),
        LinExp.kr(tone, 0.2, 0.75, 400, 20000),
      ]),
      LinExp.kr(tone, 0.75, 1, 20, 21000),
    ]);
    filterType = Select.kr(tone > 0.75, [0, 1]);
    wet = DFM1.ar(
      wet,
      freq,
      \res.kr(0.1),
      1.0,
      filterType,
      \noise.kr(0.0003)
    ).softclip;

    // Then we feed into the reverb section
    size = \size.kr(0.5);
      reverbSize = Select.kr(size > 0.75, [
        LinLin.kr(size, 0, 0.75, 0.5, 2),
        LinExp.kr(size, 0.75, 1, 2, 5),
      ]);
    decay = \decay.kr(0.5);
    // The smaller the size, the smaller the natural range of decays should be
    decayBySize = decay * LinLin.kr(size, 0, 1, 0.5, 1);
    t60 = Select.kr(decay > 0.75, [
      LinLin.kr(decay, 0, 0.75, 0.1, 2 * decayBySize),
      LinExp.kr(decay, 0.75, 1, 2 * decayBySize, 45),
    ]);
    earlyDiff = Select.kr(decay > 0.75, [
      LinLin.kr(decay, 0, 0.75, 1, 0.8),
      LinLin.kr(decay, 0.75, 1, 0.8, 0),
    ]);
    damp = LinLin.kr(tone, 0, 1, 1, 0);
    wet = JPverb.ar(
        wet,
        t60,
        damp,
        reverbSize,
        earlyDiff,
        \mdepth.kr(0.1),
        \mfreq.kr(2),
        \lowx.kr(1),
        \midx.kr(1),
        \highx.kr(1),
        \lowband.kr(500),
        \highband.kr(2000)
    );
  }}
}
