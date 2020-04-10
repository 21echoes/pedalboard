ChorusPedal : Pedal {
  *id { ^\chorus; }

  *fxArguments { ^[\rate, \depth]; }

  *fxDef {^{|wet|
    // Adapted from @madskjeldgaard's Sleet
    var numDelays = 4, lfos, rate, depth, maxDelayTime, minDelayTime;
    rate = \rate.kr(0.5);
    rate = Select.kr(rate > 0.5, [
      LinExp.kr(rate, 0.0, 0.5, 0.025, 0.125),
      LinExp.kr(rate, 0.5, 1.0, 0.125, 2)
    ]);
    depth = \depth.kr(0.5);
    maxDelayTime = LinLin.kr(depth, 0.0, 1.0, 0.016, 0.052);
    minDelayTime = LinLin.kr(depth, 0.0, 1.0, 0.012, 0.022);
    wet = wet * numDelays.reciprocal;
    lfos = Array.fill(numDelays, {|i|
      LFPar.kr(
        rate * {rrand(0.95, 1.05)},
        \phasediff.kr(0.9) * i,
        (maxDelayTime - minDelayTime) * 0.5,
        (maxDelayTime + minDelayTime) * 0.5,
      )
    });
    DelayC.ar(wet, (maxDelayTime * 2), lfos).sum;
  }}
}
