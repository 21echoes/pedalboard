ChorusPedal : Pedal {
  *id { ^\chorus; }

  *fxArguments { ^[\rate, \depth]; }

  *fxDef {^{|wet|
    // Adapted from @madskjeldgaard's Sleet
    var numDelays = 4, numChannels = 2, lfos, depth, maxDelayTime, minDelayTime;
    depth = \depth.kr(0.5);
    maxDelayTime = LinLin.kr(depth, 0.0, 1.0, 0.015, 0.06) - ControlRate.ir.reciprocal;
    minDelayTime = LinLin.kr(depth, 0.0, 1.0, 0.005, 0.025) - ControlRate.ir.reciprocal;
    wet = Array.fill(numChannels, {|cNum|
      var singleChannel = wet[cNum] * numDelays.reciprocal;
      lfos = Array.fill(numDelays, {|i|
        LFPar.kr(
          LinExp.kr(\rate.kr(0.5), 0.0, 1.0, 0.001, 1.0) * {rrand(0.95, 1.05)},
          \phasediff.kr(2) * i,
          (maxDelayTime * 0.5) - (minDelayTime * 0.5),
          (maxDelayTime * 0.5) + (minDelayTime * 0.5),
        )
      });
      DelayC.ar(singleChannel, maxDelayTime, lfos).sum;
    });
  }}
}
