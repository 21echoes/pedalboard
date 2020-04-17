FlangerPedal : Pedal {
  *id { ^\flanger; }

  *fxArguments { ^[\rate, \depth, \feedback, \predelay]; }

  *fxDef {^{|wet|
    // Adapted from Thor Magnusson's Scoring Sound
    var numChannels, maxDelay, rate, depth, preDelay, feedback, feedbackSignal, lfo, delayedSignal;
    numChannels = 2;
    maxDelay = 0.0105;
    rate = LinExp.kr(\rate.kr(0.5), 0, 1, 0.1, 8);
    depth = LinExp.kr(\depth.kr(0.5), 0, 1, 0.00025, maxDelay * 0.45);
    preDelay = LinLin.kr(\predelay.kr(0.5), 0, 1, depth, maxDelay - depth);
    // Allow just-beyond-unity feedback
    feedback = LinLin.kr(\feedback.kr(0.5), 0, 1, 0.0, 1.1);
    feedbackSignal = LocalIn.ar(2);
    feedbackSignal = Select.ar(feedback >= 1, [
      (feedbackSignal * feedback),
      (feedbackSignal * feedback).softclip
    ]);
    lfo = LFPar.kr(rate, 0, depth, preDelay);
    delayedSignal = DelayC.ar(wet + feedbackSignal, maxDelay, lfo);
    LocalOut.ar(delayedSignal + wet);
    wet + delayedSignal;
  }}
}
