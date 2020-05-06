RingsPedal : Pedal {
  *id { ^\rings; }

  *fxArguments { ^[\pit, \structure, \bright, \damp, \pos, \model, \easteregg]; }

  *fxDef {^{|wet|
    var trig, pit, structure, bright, damp, pos, model, poly, intern_exciter, easteregg, bypass;
    trig=\trig.kr(0);
    pit = \pit.kr(1);
    structure = \structure.kr(0.5);
    bright = \bright.kr(0.5);
    damp = \damp.kr(0.2);
    pos = \pos.kr(0.3);
    model = \model.kr(0);
    poly=\poly.kr(4);
    intern_exciter= \intern_exciter.kr(0);
    easteregg = \easteregg.kr(0);
    bypass=\bypass.kr(0);
    wet = MiRings.ar(wet, trig, pit, structure, bright, damp, pos, model, poly, intern_exciter, easteregg, bypass);
  }}
}

