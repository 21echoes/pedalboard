RingsPedal : Pedal {
  *id { ^\rings; }

  *fxArguments { ^[\pit, \struct, \bright, \damp, \pos, \model, \easteregg ]; }

  *fxDef {^{|wet|
    var trig=0, pit, struct, bright, damp, pos, model, poly=4, intern_exciter=0, easteregg;    
	pit = \pit.kr(1);
	struct = \struct.kr(0.5);
	bright = \bright.kr(0.5);
	damp = \damp.kr(0.2);
	pos = \pos.kr(0.3);
	model = \model.kr(0);
	easteregg = \easteregg.kr(0);
    wet = MiRings.ar(wet, trig, pit, struct, bright, damp, pos, model, poly, intern_exciter, easteregg);
  }}
}

