LoFiPedal : Pedal {
  *id { ^\lofi; }

  *fxArguments { ^[\drive, \tone, \wow, \noise]; }

  *fxDef {^{|wet|
    var drive, ratio, threshold, gain,
    wow, minWowRate, wowRate, maxDepth, maxLfoDepth, depth, depthLfoAmount, wowMul, maxDelay,
    tone, bitRate, noise, noiseSignal;

    // First we feed into a HPF to filter out sub-20Hz
    wet = HPF.ar(wet, 25);
    drive = \drive.kr(0.5);
    // Shitty compression (slow attack and release, really aggressive ratio)
    ratio = LinExp.kr(drive, 0, 1, 0.15, 0.01);
    threshold = LinLin.kr(drive, 0, 1, 0.8, 0.33);
    // We bump the gain to keep up with the threshold and ratio, then compress it
    gain = 1/(((1.0-threshold) * ratio) + threshold);
    wet = Limiter.ar(Compander.ar(wet, wet, threshold, 1.0, ratio, 0.1, 1, gain), dur: 0.0008);

    // Wow aka flutter aka warble
    wow = \wow.kr(0.5);
    minWowRate = 0.5;
    wowRate = LinExp.kr(wow, 0, 1, minWowRate, 4);
    maxDepth = 35;
    maxLfoDepth = 5;
    depth = LinExp.kr(wow, 0, 1, 1, maxDepth - maxLfoDepth);
    depthLfoAmount = LinLin.kr(wow, 0, 1, 1, maxLfoDepth).floor;
    depth = LFPar.kr(depthLfoAmount * 0.1, mul: depthLfoAmount, add: depth);
    // wowMul calculates the amplitude of the LFO for our delay to achieve the given rate and depth
    wowMul = ((2 ** (depth * 1200.reciprocal)) - 1)/(4 * wowRate);
    maxDelay = (((2 ** (maxDepth * 1200.reciprocal)) - 1)/(4 * minWowRate)) * 2.5;
    wet = DelayC.ar(wet, maxDelay, SinOsc.ar(wowRate, 2, wowMul, wowMul + ControlRate.ir.reciprocal));

    // Tape/Vinyl-esque noise
    noise = \noise.kr(0.5);
    noiseSignal = (Dust2.ar(LinLin.kr(noise, 0, 1, 1, 5), 1) + Crackle.ar(1.95, 0.1) + SinOsc.ar((PinkNoise.ar(0.5) * 7500) + 40, 0, 0.006));
    noiseSignal = noiseSignal * LinExp.kr(noise, 0, 1, 0.01, 1);

    // Saturation
    wet = ((wet * LinExp.kr(drive, 0, 1, 1, 2.5)) + noiseSignal).tanh;

    // Lots of LPFs and HPFs and a little bitcrushing
    tone = \tone.kr(0.5);
    wet = LPF.ar(wet, LinExp.kr(tone, 0, 1, 2500, 10000));
    bitRate = 48000 * LinLin.kr(noise, 0, 1, 0, 3).ceil.reciprocal;
    wet = (Decimator.ar(wet, bitRate, LinExp.kr(noise, 0, 1, 24, 6)) * 0.3) + (wet * 0.7);
    wet = HPF.ar(wet, LinExp.kr(tone, 0, 1, 40, 1690));
    wet = MoogFF.ar(wet, LinExp.kr(tone, 0, 1, 1000, 10000), 0);
    wet = wet * LinLin.kr(drive, 0, 1, 1, 0.66);
  }}
}
