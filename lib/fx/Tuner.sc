TunerPedal : Pedal {
  *id { ^\tuner; }

  *fxArguments { ^[\hz]; }

  *fxDef {^{|wet|
    // Pure sine waves can be rather grating. Keep it at an amplitude of 0.3
    SinOsc.ar(\hz.kr(440), mul: 0.3) ;
  }}
}