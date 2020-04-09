FlangerPedal : Pedal {
  *id { ^\flanger; }

  *fxArguments { ^[\rate, \depth, \feedback, \predelay]; }

  *fxDef {^{|wet|
    // Adapted from Thor Magnusson's Scoring Sound
    var numChannels, maxDelay, feedback, feedbackBuses, rate, depth, preDelay;
    numChannels = 2;
    maxDelay = 0.013;
    rate = LinExp.kr(\rate.kr(0.5), 0, 1, 0.004, 10);
    depth = LinExp.kr(\depth.kr(0.5), 0, 1, 0.0001, maxDelay * 0.3);
    preDelay = LinLin.kr(\predelay.kr(0.5), 0, 1, 0 + depth, maxDelay - depth);
    // Allow just-beyond-unity feedback
    feedback = LinExp.kr(\feedback.kr(0.5), 0, 1, 0.0001, 1.1);
    feedbackBuses = Array.fill(numChannels, {Bus.audio(context.server, 1)});
    wet = Array.fill(numChannels, {|cNum|
      var liveChannel, feedbackSignal, liveAndFeedback, delayedSignal, mixed;
      liveChannel = wet[cNum];
      feedbackSignal = InFeedback.ar(feedbackBuses[cNum].index);
      liveAndFeedback = liveChannel + Select.ar(feedback >= 1, [
        (feedbackSignal * feedback),
        (feedbackSignal * feedback).softclip
      ]);
      delayedSignal = AllpassC.ar(
        liveAndFeedback,
        maxDelay + 0.01,
        LFPar.kr(rate, 0, depth, preDelay),
        0
      );
      Out.ar(feedbackBuses[cNum].index, delayedSignal);
      delayedSignal;
    });
  }}
}
