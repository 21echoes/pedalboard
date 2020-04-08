SustainPedal : Pedal {
  *id { ^\sustain; }

  *fxArguments { ^[\drive, \gate, \tone]; }

  *fxDef {^{|wet|
    // Adapted from Thor Magnusson's Scoring Sound
    var drive, gate, ratio, threshold, gain, tone, freq, filterType;

    // First we feed into a HPF to filter out sub-20Hz
    wet = HPF.ar(wet, 25);

    // Then into a noise gate
    gate = LinExp.kr(\gate.kr(0.5), 0, 1, 0.001, 0.05);
    wet = Compander.ar(wet, wet, gate, 10, 1, 0.01, 0.01);

    // Then we feed into a sustainer
    drive = \drive.kr(0.5);
    ratio = LinExp.kr(drive, 0, 1, 0.8, 0.1);
    threshold = LinLin.kr(drive, 0, 1, 0, 1);
    wet = Compander.ar(wet, wet, threshold, ratio, 1, \attack.kr(0.01), \release.kr(0.01));

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
