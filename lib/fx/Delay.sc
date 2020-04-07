DelayPedal : Pedal {
  *id { ^\delay; }

  *fxArguments { ^[\time, \feedback, \mode]; }

  *fxDef {^{|wet|
    // Adapted from @carltesta's Manifold
    // \mode selects: normal, ping-pong. Eventually: multi-tap, tape/lo-fi
    var numChannels, maxDelay, feedbackBuses, time, changeDetector, feedback, mode;
    numChannels = 2;
    maxDelay = 5;
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
      mainDelay, altDelay, fade, combinedDelay;
      inputSignal = Select.ar(mode, [
        wet[cNum],
        wet[(cNum + 1) % numChannels],
      ]);
      delayBuffer = Buffer.alloc(context.server, pow(2, (maxDelay * 48000).log2.ceil) + 1, 1);
      inputFeedbackBus = feedbackBuses[cNum].index;
      outputFeedbackBus = Select.kr(mode, [
        feedbackBuses[cNum].index,
        feedbackBuses[(cNum + 1) % numChannels].index,
      ]);
      liveAndFeedback = inputSignal + InFeedback.ar(inputFeedbackBus);
      // Maintain two delays so we can use the prior one at the prior delay time whenever we change the delay time.
      // This avoids pitch shifts or other artifacts during delaytime changes
      mainDelay = BufDelayL.ar(delayBuffer, liveAndFeedback, Latch.kr(time, 1 - changeDetector));
      altDelay = BufDelayL.ar(delayBuffer, liveAndFeedback, Latch.kr(time, changeDetector));
      fade = MulAdd.new(Lag2.kr(changeDetector, 0.1), 2, 1.neg);
      combinedDelay = XFade2.ar(mainDelay, altDelay, fade);
      Out.ar(outputFeedbackBus, Select.ar(feedback >= 1, [
        (combinedDelay * feedback),
        (combinedDelay * feedback).softclip
      ]));
      combinedDelay;
    });
  }}
}
