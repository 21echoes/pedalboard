CloudsPedal : Pedal {
  *id { ^\clouds; }

  *fxArguments { ^[\pit, \pos, \size, \dens, \tex, \spread, \mode, \fb ]; }

  *fxDef {^{|wet|
    var pit=0, pos=0.5, size=0.5, dens=0.5, tex=0, drywet=1, in_gain=1, spread=0.5, rvb=0.5, fb=0, freeze=0, mode=0, lofi=0, trig=0;
	pit = \pit.kr(0.7);
	pos = \pos.kr(0.5);
	size = \size.kr(0.5);
	dens = \dens.kr(0.5);
	tex = \tex.kr(0);
	spread = \spread.kr(0.5);
	mode = \mode.kr(0);
	fb = \fb.kr(0);
    wet = MiClouds.ar(wet, pit, pos, size, dens, tex, drywet, in_gain, spread, rvb, fb, freeze, mode, lofi, trig);
  }}
}

