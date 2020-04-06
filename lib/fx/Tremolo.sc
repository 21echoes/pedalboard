TremoloPedal : Pedal {
  *id { ^\tremolo; }

  *fxArguments { ^[\rate, \depth]; }

  *fxDef {^{|wet|
    var rate, depth, ampMod;
    rate = LinExp.kr(\rate.kr(0.5), 0, 1, 0.5, 10);
    depth = LinLin.kr(\depth.kr(0.5), 0, 1, 0, 0.5);
    // unipolar from 1 down to at most zero (controlled by depth)
    // TODO: Shape controls (wavetable sin->tri->saw->sq)
    ampMod = LFTri.kr(rate, 0, depth, 1 - depth);
    wet = wet * ampMod;
  }}
}
