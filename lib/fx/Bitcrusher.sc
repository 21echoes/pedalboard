BitcrusherPedal : Pedal {
  *id { ^\bitcrusher; }

  *fxArguments { ^[\bitrate, \tone]; }

  *fxDef {^{|wet|
    var tone, freq, filterType;

    // First we feed into a HPF to filter out sub-20Hz
    wet = HPF.ar(wet, 25);
    // Then into a noise gate
    wet = Compander.ar(wet, wet, 0.005, 7.5, 1, 0.1, 0.01);
    // Then into a bit reducer
    wet = Decimator.ar(wet, 48000, \bitrate.kr(12));

    // Then we feed into the Tone section
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
  }}
}
