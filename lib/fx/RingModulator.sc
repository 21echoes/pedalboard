RingModulatorPedal : Pedal {
  *id { ^\ringmod; }

  *fxArguments { ^[\freq, \follow, \freq_mul, \shape, \tone]; }

  *fxDef {^{|wet|
    var freq, followFreq, freqClarity, modulator, tone, filterFreq,
    shape, sinMix, triMix, sawMix, sqrMix;

    // Specific frequency mode:
    freq = \freq.kr(220);
    // Follow mode:
    # followFreq, freqClarity = Pitch.kr(wet[0], initFreq: 0, minFreq: 30, maxFreq: 4200, execFreq: 300, ampThreshold: 0.02, median: 1, clar: 1);
    followFreq = Select.kr(followFreq, [220, followFreq * \freq_mul.kr(0)]);
    freq = Select.kr(\follow.kr(0), [freq, followFreq]);

    // Shape controls a (hacky) wavetable (sin->tri->saw->sqr)
    // TODO: proper wavetable with interpolation
    shape = \shape.kr(0.33);
    sinMix = Select.kr(shape < 0.33, [0, LinLin.kr(shape, 0, 0.33, 1, 0)]);
    triMix = Select.kr(shape < 0.33, [
      Select.kr(shape < 0.67, [0, LinLin.kr(shape, 0.33, 0.67, 1, 0)]),
      LinLin.kr(shape, 0, 0.33, 0, 1)
    ]);
    sawMix = Select.kr(shape < 0.33, [
      Select.kr(shape < 0.67, [
        LinLin.kr(shape, 0.67, 1.0, 1, 0),
        LinLin.kr(shape, 0.33, 0.67, 0, 1)
      ]),
      0
    ]);
    sqrMix = Select.kr(shape < 0.67, [LinLin.kr(shape, 0.67, 1.0, 0, 1), 0]);
    modulator = Mix.new([
      SinOsc.ar(freq, mul: sinMix),
      LFTri.ar(freq, mul: triMix),
      LFSaw.ar(freq, mul: sawMix),
      // LFPulse is unipolar
      LFPulse.ar(freq, width: 0.5, mul: (2 * sqrMix), add: (-1 * sqrMix)),
    ]);
    wet = wet * modulator;

    // Then we feed into the Tone section
    // Tone controls a MMF, exponentially ranging from 10 Hz - 21 kHz
    // Tone above 0.75 switches to a HPF
    tone = \tone.kr(0.5);
    filterFreq = Select.kr(tone > 0.75, [
      Select.kr(tone > 0.2, [
        LinExp.kr(tone, 0, 0.2, 10, 400),
        LinExp.kr(tone, 0.2, 0.75, 400, 20000),
      ]),
      LinExp.kr(tone, 0.75, 1, 20, 21000),
    ]);
    wet = Select.ar(tone > 0.75, [
      MoogFF.ar(wet, freq: filterFreq, gain: 0.1),
      HPF.ar(wet, freq: filterFreq),
    ]).softclip;
  }}
}
