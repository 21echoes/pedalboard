PitchShifterPedal : Pedal {
  *id { ^\pitchshifter; }

  *fxArguments { ^[\freq_mul, \drift]; }

  *fxDef {^{|wet|
    var drift, pitchDisp, timeDisp, windowSize = 0.25;
    drift = \drift.kr(0.5);
    pitchDisp = Select.kr(drift > 0, [drift, LinExp.kr(drift, 0, 1, 0.0001, 0.1)]);
    timeDisp = Select.kr(drift > 0, [drift, LinExp.kr(drift, 0, 1, 0.0001, windowSize)]);
    wet = PitchShift.ar(wet, windowSize, \freq_mul.kr(1), pitchDisp, timeDisp);
  }}
}
