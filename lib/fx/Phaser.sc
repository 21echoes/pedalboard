PhaserPedal : Pedal {
  *id { ^\phaser; }

  *fxArguments { ^[\rate, \depth]; }

  *fxDef {^{|wet|
    // Adapted from Thor Magnusson's Scoring Sound
    var numChannels, maxDelay, rate, depth, preDelay, numAllPasses, delayedSignal;
    numChannels = 2;
    maxDelay = 0.01;
    rate = LinExp.kr(\rate.kr(0.5), 0, 1, 0.275, 16);
    depth = LinExp.kr(\depth.kr(0.5), 0, 1, 0.0005, maxDelay * 0.5);
    // multi-stage Allpass
    numAllPasses = 4;
    depth = depth * numAllPasses.reciprocal;
    delayedSignal = wet;
    for(1, numAllPasses, {|i|
      delayedSignal = AllpassL.ar(delayedSignal, maxDelay * numAllPasses.reciprocal, LFPar.kr(rate, i + 0.5.rand, depth, depth), 0);
    });
    wet + delayedSignal;
  }}
}
