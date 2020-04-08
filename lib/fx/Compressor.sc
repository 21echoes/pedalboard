CompressorPedal : Pedal {
  *id { ^\compressor; }

  *fxArguments { ^[\drive, \tone]; }

  *fxDef {^{|wet|
    var drive, ratio, threshold, gain, tone, freq, filterType;

    // First we feed into a HPF to filter out sub-20Hz
    wet = HPF.ar(wet, 25);

    // TODO: noise gate?
    // Then we feed into a compressor
    drive = \drive.kr(0.5);
    ratio = LinExp.kr(drive, 0, 1, 0.25, 0.05);
    threshold = LinLin.kr(drive, 0, 1, 0.9, 0.5);
    // We bump the gain such that 1.0 stays 1.0, no matter the ratio and threshold,
    // plus a little sauce at the extremes
    gain = 1/(((1.0-threshold) * ratio) + threshold);
    gain = Select.kr(drive > 0.9, [
      gain,
      gain * LinExp.kr(drive, 0.9, 1, 1, 1.2);
    ]);
    // wet = wet * gain;
    wet = Compander.ar(
      wet, wet,
      threshold, 1.0, ratio,
      \attack.kr(0.005), \release.kr(0.1),
      gain
    );

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
    );
  }}
}
