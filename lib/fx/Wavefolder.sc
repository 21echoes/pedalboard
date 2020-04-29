WavefolderPedal : Pedal {
  *id { ^\wavefolder; }

  *fxArguments { ^[\amount, \symmetry, \smoothing, \expression]; }

  *fxDef {^{|wet|
    var gain, compensationGain, envFollower, expression, amp, symmetry;
    gain = LinLin.kr(\amount.kr(0.5), 0, 1, 1, 20);

    // The gain needed to have the folding kick in is so huge that we wanna knock it back down after folding
    compensationGain = max(gain * 0.75, 1).reciprocal;
    // We mix this with an envelope follower so that the output envelope follows the input envelope
    envFollower = EnvFollow.ar((wet * 2).softclip, 0.9999);
    expression = \expression.kr(0.5);
    amp = (compensationGain * (1 - expression)) + (envFollower * expression);

    symmetry = LinLin.kr(\symmetry.kr(1), 0, 1, 1, 0);
    wet = SmoothFoldS.ar((wet + symmetry) * gain, smoothAmount: \smoothing.kr(0.5));
    // LeakDC is essential after folding due to how symmetry adds DC offset.
    // Luckily, the base pedal does that for us
    wet = wet * amp;
  }}
}
