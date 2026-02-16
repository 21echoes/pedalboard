FrequencyShifterPedal : Pedal {
  *id { ^\frequencyshifter; }

  *fxArguments { ^[\freq, \phase]; }

  *fxDef {^{|wet|
    var freq, phase;
    wet = FreqShift.ar(wet, \freq.kr(1), \phase.kr(1));
  }}
}
