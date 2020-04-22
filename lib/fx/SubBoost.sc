SubBoostPedal : Pedal {
  *id { ^\subboost; }

  *fxArguments { ^[\shape, \num_octaves_down, \amp, \sensitivity]; }

  *fxDef {^{|wet|
    var freq, freqClarity, freqDivider, minEmittedFreq = 20, overshoot, maxOvershoot,
    threshold, envFollower, amp,
    shape, sinMix, triMix, sawMix, sqrMix, shapeCompensate;

    # freq, freqClarity = Pitch.kr(wet[0], initFreq: 0, minFreq: 30, maxFreq: 4200, ampThreshold: 0.02, median: 7, clar: 1);
    // Reduce the frequency by the requested number of octaves
    freq = freq * (0.5 ** \num_octaves_down.kr(3));
    // If we're below our lowest allowed frequency, bump it back up by enough octaves to be above our minimum
    overshoot = Select.kr(freq > 0, [0, (minEmittedFreq.log/2.log) - (freq.log/2.log)]);
    freq = freq * (2 ** max(0, overshoot).ceil);

    // Sensitivity controls how clear the pitch must be to trigger the sub kicking in
    threshold = LinLin.kr(\sensitivity.kr(0.5), 0, 1, 0.05, 0.75);
    // Amp controls the baseline amplitude, factoring in pitch certainty and envelope following
    envFollower = EnvFollow.ar((wet * 2).softclip, 0.999);
    amp = \amp.kr(0.5) * Select.kr(freqClarity > threshold, [
      0,
      (0.75 * envFollower) + (0.25 * ((freqClarity - threshold)/(1 - threshold))),
    ]);

    // Shape controls a (hacky) wavetable (sin->tri->saw->sqr)
    // TODO: proper wavetable with interpolation
    shape = \shape.kr(0.33);
    sinMix = Select.kr(shape < 0.33, [0, LinLin.kr(shape, 0, 0.33, 1, 0)]);
    triMix = Select.kr(shape < 0.33, [
      Select.kr(shape < 0.67, [0, LinLin.kr(shape, 0.33, 0.67, 1, 0)]),
      LinLin.kr(shape, 0, 0.33, 0, 1)
    ]);
    sawMix = Select.kr(shape < 0.33, [
      Select.kr(shape < 0.67, [
        LinLin.kr(shape, 0.67, 1.0, 1, 0),
        LinLin.kr(shape, 0.33, 0.67, 0, 1)
      ]),
      0
    ]);
    sqrMix = Select.kr(shape < 0.67, [LinLin.kr(shape, 0.67, 1.0, 0, 1), 0]);
    // Turn down the saw and square
    shapeCompensate = LinLin.kr(shape, 0, 1, 1, 0.66);
    wet = MoogFF.ar(Mix.new([
      SinOsc.ar(freq, mul: sinMix),
      LFTri.ar(freq, mul: triMix),
      LFSaw.ar(freq, mul: sawMix),
      // LFPulse is unipolar
      LFPulse.ar(freq, width: 0.5, mul: (2 * sqrMix), add: (-1 * sqrMix)),
    ]), freq: 300, gain: 0, reset: 0, mul: 2.5 * amp * shapeCompensate);
  }}
}
