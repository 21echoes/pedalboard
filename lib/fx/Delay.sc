DelayPedal : Pedal {
  *id { ^\delay; }

  *fxArguments { ^[\time, \feedback, \quality, \mode]; }

  *fxDef {^{|wet|
    // Adapted from @carltesta's Manifold
    // \mode selects: normal, ping-pong. Eventually: multi-tap, varispeed
    var numChannels, minDelay, maxDelay, delayBuffers, feedbackBuses, time, changeDetector, feedback, mode;
    numChannels = 2;
    minDelay = 0.03;
    maxDelay = 5;
    delayBuffers = Array.fill(numChannels, {Buffer.alloc(context.server, pow(2, (maxDelay * 48000).log2.ceil) + 1, 1)});
    feedbackBuses = Array.fill(numChannels, {Bus.audio(context.server, 1)});
    // The feedback loop introduces an additional ControlRate.ir.reciprocal delay,
    // so reduce our delay time by that amount to compensate
    time = LinExp.kr(\time.kr(0.5, 0.1), 0, 1, 0.03, maxDelay) - ControlRate.ir.reciprocal;
    changeDetector = Changed.kr(time);
    // Allow just-beyond-unity feedback
    feedback = LinLin.kr(\feedback.kr(0.5), 0, 1, 0, 1.1);
    mode = \mode.kr(0);
    wet = Array.fill(numChannels, {|cNum|
      var inputSignal, delayBuffer, busIndex, inputFeedbackBus, outputFeedbackBus, liveAndFeedback,
      mainDelay, altDelay, fade, delayedSignal, quality, latchedTime, altLatchedTime;
      inputSignal = Select.ar(mode, [
        wet[cNum],
        wet[(cNum + 1) % numChannels],
      ]);
      delayBuffer = delayBuffers[cNum];
      inputFeedbackBus = feedbackBuses[cNum].index;
      outputFeedbackBus = Select.kr(mode, [
        feedbackBuses[cNum].index,
        feedbackBuses[(cNum + 1) % numChannels].index,
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
      Out.ar(outputFeedbackBus, delayedSignal);
      delayedSignal;
    });
  }}
}
