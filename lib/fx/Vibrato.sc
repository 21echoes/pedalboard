VibratoPedal : Pedal {
  *id { ^\vibrato; }

  *fxArguments { ^[\rate, \depth, \expression]; }

  *fxDef {^{|wet|
    var expression, envelopeFollower, envMultiplier, rate, depth, mul, minRate, maxDepth, maxDelay;
    // Track the amplitude, so we vibrato more and faster when the signal is louder
    envelopeFollower = Lag.ar(EnvFollow.ar((wet * 6).clip(-1, 1), 0.999), 0.14);
    // Expression scales how much the envelope influences our vibrato
    expression = \expression.kr(0.5);
    envMultiplier = (1 - expression) + (envelopeFollower * expression);
    // Delay the vibrato until after the attack  portion of a typical envelope
    envMultiplier = DelayN.ar(envMultiplier, 0.1, 0.07);
    // Rate is how many vibratos per second
    minRate = 0.75;
    rate = LinExp.ar(\rate.kr(0.5) * envMultiplier, 0, 1, minRate, 60);
    // Depth is pitch bend range in cents
    maxDepth = 30;
    depth = LinExp.ar(\depth.kr(0.5) * envMultiplier, 0, 1, 3.3, maxDepth);
    // Mul calculates the amplitude of the LFO for our delay to achieve the given rate and depth
    mul = ((2 ** (depth * 1200.reciprocal)) - 1)/(4 * rate);
    maxDelay = (((2 ** (maxDepth * 1200.reciprocal)) - 1)/(4 * minRate)) * 2.5;
    wet = DelayC.ar(wet, maxDelay, SinOsc.ar(rate, 2, mul, mul + ControlRate.ir.reciprocal));
  }}
}
