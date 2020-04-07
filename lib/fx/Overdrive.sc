OverdrivePedal : Pedal {
  *id { ^\overdrive; }

  *fxArguments { ^[\drive, \tone]; }

  *fxDef {^{|wet|
    var drive, tone, freq, filterType;

    // First we feed into the overdrive
    // Drive controls 1 to 3x the volume with soft-clipping
    wet = (wet * LinLin.kr(\drive.kr(0.5), 0, 1, 1, 3)).softclip;

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
