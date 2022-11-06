TremoloPedal : Pedal {
  *id { ^\tremolo; }

  *fxArguments { ^[\time, \depth, \shape, \stereo_phase]; }

  *fxDef {^{|wet|
    var rate, depth, ampModL, ampModR, shape,
    sinMod, triMod, sawMod, sqrMod,
    phase, phaseDelay, maxDelay,
    sinMix, triMix, sawMix, sqrMix, wavetableGainOffset;

    rate = (\time.kr(0.5) - ControlRate.ir.reciprocal).reciprocal;
    // Unipolar from 1 down to at most zero (controlled by depth)
    depth = LinLin.kr(\depth.kr(0.5), 0, 1, 0, 0.5);

    sinMod = SinOsc.kr(rate, 0, depth, 1 - depth);
    triMod = LFTri.kr(rate, 0, depth, 1 - depth);
    sawMod = LFSaw.kr(rate, 0, depth, 1 - depth);
    // LFPulse already is unipolar
    sqrMod = LFPulse.kr(rate, 0, 0.5, (depth * 2), 1 - (depth * 2));

    // Shape controls a (hacky) wavetable (sin->tri->saw->sqr)
    // TODO: proper wavetable with interpolation?
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
    ampModL = Mix.new([
      sinMod * sinMix,
      triMod * triMix,
      sawMod * sawMix,
      sqrMod * sqrMix
    ]);

    // Use a delay line to shift stereo phase, as LF* UGens don't allow phase modulation
    phase = \stereo_phase.kr(0);
    phaseDelay = LinLin.kr(phase, 0, 360, 0, rate.reciprocal);
    // 40 bpm whole note = 6 seconds
    maxDelay = 6;
    ampModR = Mix.new([
      DelayL.kr(sinMod, maxDelay, phaseDelay) * sinMix,
      DelayL.kr(triMod, maxDelay, phaseDelay) * triMix,
      DelayL.kr(sawMod, maxDelay, phaseDelay) * sawMix,
      DelayL.kr(sqrMod, maxDelay, phaseDelay) * sqrMix
    ]);

    // The space between tri and saw doesn't reach 0 and 1, so we hackily apply some gain and offset to fix this
    wavetableGainOffset = Select.kr(shape < 0.33, [
      Select.kr(shape > 0.67, [
        Select.kr(shape > 0.55, [
          [LinLin.kr(shape, 0.33, 0.55, 1, 1.44), LinLin.kr(shape, 0.33, 0.55, 0, -0.22)],
          [LinLin.kr(shape, 0.55, 0.67, 1.44, 1), LinLin.kr(shape, 0.55, 0.67, -0.22, 0)]
        ]), [1, 0]
      ]), [1, 0]
    ]);
    ampModL = Clip.kr(((ampModL * wavetableGainOffset[0]) + wavetableGainOffset[1]), 0, 1);
    ampModR = Clip.kr(((ampModR * wavetableGainOffset[0]) + wavetableGainOffset[1]), 0, 1);

    wet = [wet[0] * ampModL, wet[1] * ampModR];
  }}
}
