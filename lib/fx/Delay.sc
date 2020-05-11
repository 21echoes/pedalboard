DelayPedal : Pedal {
  *id { ^\delay; }

  *fxArguments { ^[\time, \feedback, \quality, \mode]; }

  *fxDef {^{|wet|
    // Adapted from @carltesta's Manifold
    // \mode selects: normal, ping-pong, or slapback. Eventually: multi-tap, varispeed
    var numChannels, minDelay, maxDelay, delayBuffers, feedbackBuses, time, changeDetector, feedback, mode;
    numChannels = 2;
    minDelay = 0.03;
    maxDelay = 5;
    delayBuffers = Array.fill(numChannels, {Buffer.alloc(context.server, pow(2, (maxDelay * 48000).log2.ceil) + 1, 1)});
    feedbackBuses = Array.fill(numChannels, {Bus.audio(context.server, 1)});
    // The feedback loop introduces an additional ControlRate.ir.reciprocal delay,
    // so reduce our delay time by that amount to compensate
    time = \time.kr(0.5) - ControlRate.ir.reciprocal;
    changeDetector = Changed.kr(Lag.kr(time, 0.2));
    // Allow just-beyond-unity feedback
    feedback = LinLin.kr(\feedback.kr(0.5), 0, 1, 0, 1.1);
    mode = \mode.kr(0);
    wet = Array.fill(numChannels, {|cNum|
      var inputSignal, delayBuffer, busIndex, inputFeedbackBus, outputFeedbackBus, liveAndFeedback,
      mainDelay, altDelay, fade, delayedSignal, quality, latchedTime, altLatchedTime, feedbackOutputMul;
      inputSignal = Select.ar(mode, [
        wet[cNum],
        wet[(cNum + 1) % numChannels],
        wet[cNum],
      ]);
      delayBuffer = delayBuffers[cNum];
      inputFeedbackBus = feedbackBuses[cNum].index;
      outputFeedbackBus = Select.kr(mode, [
        feedbackBuses[cNum].index,
        feedbackBuses[(cNum + 1) % numChannels].index,
        feedbackBuses[cNum].index,
      ]);
      liveAndFeedback = inputSignal + InFeedback.ar(inputFeedbackBus);

      // Apply any Quality effects to the signal [digital, analog, tape, lo-fi]
      quality = \quality.kr(0);
      liveAndFeedback = Select.ar(quality, [
        liveAndFeedback,
        LPF.ar(
          (HPF.ar(liveAndFeedback, 25) * 1.4).softclip,
          4500,
        ) * 0.73,
        MoogFF.ar(
          MoogFF.ar(
            ((liveAndFeedback * 1.33) + PinkNoise.ar(0.005)).tanh,
            10000, 0
          ),
          5000, 0
        ) * 0.8,
        MoogFF.ar(
          HPF.ar(
            Decimator.ar(
              LPF.ar(
                ((liveAndFeedback * 1.1) + PinkNoise.ar(0.003)).softclip,
                3500,
              ),
              16000, 12
            ),
            260
          ),
          5000, 0
        )
      ]);
      liveAndFeedback = Select.ar(feedback >= 1, [
        (liveAndFeedback * feedback),
        (liveAndFeedback * feedback).softclip
      ]);
      latchedTime = Latch.kr(time, 1 - changeDetector);
      altLatchedTime = Latch.kr(time, changeDetector);
      latchedTime = Select.kr(quality >= 2, [
        latchedTime,
        SinOsc.ar(1, 0, LinExp.kr(latchedTime, minDelay, maxDelay, 0.00004, 0.0006), latchedTime) // warble
      ]);
      altLatchedTime = Select.kr(quality >= 2, [
        altLatchedTime,
        SinOsc.ar(1, 0, LinExp.kr(altLatchedTime, minDelay, maxDelay, 0.00004, 0.0006), altLatchedTime) // warble
      ]);
      delayedSignal = XFade2.ar(
        BufDelayL.ar(delayBuffer, liveAndFeedback, latchedTime),
        BufDelayL.ar(delayBuffer, liveAndFeedback, altLatchedTime),
        MulAdd.new(Lag2.kr(changeDetector, 0.1), 2, 1.neg)
      );
      feedbackOutputMul = Select.kr(mode, [1, 1, 0]);
      Out.ar(outputFeedbackBus, delayedSignal * feedbackOutputMul);
      delayedSignal;
    });
  }}

  *addDef {|contextArg|
    // Adapted from superclass for alternate wet/dry mix behavior
    context = contextArg;
    SynthDef(this.id, {
      var inL = \inL.kr(0),
      inR = \inR.kr(1),
      out = \out.kr(0),
      bypass = \bypass.kr(0),
      mix = \mix.kr(0.5),
      inGain = \in_gain.kr(1.0),
      outGain = \out_gain.kr(1.0),
      dry, wet, mixdown, effectiveMixRate, centerMix, dryMix, wetMix;
      dry = [In.ar(inL), In.ar(inR)];
      wet = dry * inGain;
      wet = SynthDef.wrap(this.fxDef, prependArgs: [wet]);
      wet = LeakDC.ar(wet * outGain);
      // If bypass is on, act as if the mix is 0% no matter what
      effectiveMixRate = min(mix, 1 - bypass);

      // Begin custom behavior:
      centerMix = 0.707;
      // For dry, from 0->0.5->1 should do 1->centerMix->0
      dryMix = Select.kr(effectiveMixRate > 0.5, [
        LinLin.kr(effectiveMixRate, 0, 0.5, 1, centerMix),
        LinLin.kr(effectiveMixRate, 0.5, 1, centerMix, 0),
      ]);
      // For wet, from 0->0.5->1 should do 0->centerMix->1
      wetMix = Select.kr(effectiveMixRate > 0.5, [
        LinLin.kr(effectiveMixRate, 0, 0.5, 0, centerMix),
        LinLin.kr(effectiveMixRate, 0.5, 1, centerMix, 1),
      ]);
      mixdown = Mix.new([dry * dryMix, wet * wetMix]);
      // End custom behavior

      Out.ar(out, mixdown);
    }).add;
  }
}
