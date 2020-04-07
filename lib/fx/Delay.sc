DelayPedal : Pedal {
  *id { ^\delay; }

  *fxArguments { ^[\time, \feedback]; }

  *fxDef {^{|wet|
    // Adapted from @carltesta's Manifold
    // TODO: \mode to select: normal, ping-pong, multi-tap, tape/lo-fi
    var numChannels, maxDelay, time, feedback, changeDetector;
    numChannels = 2;
    maxDelay = 5;
    // The feedback loop introduces an additional ControlRate.ir.reciprocal delay,
    // so reduce our delay time by that amount to compensate
    time = LinExp.kr(\time.kr(0.5, 0.1), 0, 1, 0.03, maxDelay) - ControlRate.ir.reciprocal;
    feedback = \feedback.kr(0.5);
    changeDetector = Changed.kr(time);
    wet = Array.fill(numChannels, {|cNum|
      var delayBuffer, feedbackBus, liveAndFeedback, mainDelay, altDelay, fade, combinedDelay;
      delayBuffer = Buffer.alloc(context.server, pow(2, (maxDelay * 48000).log2.ceil) + 1, 1);
      feedbackBus = Bus.audio(context.server, 1);
      liveAndFeedback = wet[cNum] + InFeedback.ar(feedbackBus);
      // Maintain two delays so we can use the prior one at the prior delay time whenever we change the delay time.
      // This avoids pitch shifts or other artifacts during delaytime changes
      mainDelay = BufDelayL.ar(delayBuffer, liveAndFeedback, Latch.kr(time, 1 - changeDetector));
      altDelay = BufDelayL.ar(delayBuffer, liveAndFeedback, Latch.kr(time, changeDetector));
      fade = MulAdd.new(Lag2.kr(changeDetector, 0.1), 2, 1.neg);
      combinedDelay = XFade2.ar(mainDelay, altDelay, fade);
      Out.ar(feedbackBus, combinedDelay * feedback);
      combinedDelay;
    });
  }}
}
