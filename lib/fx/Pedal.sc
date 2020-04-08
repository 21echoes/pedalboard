Pedal {
  classvar context;

  *id {
    // Override this function to define the pedal's unique ID.
    // It must match the pedal's corresponding Lua pedal class ID.
    ^this.subclassResponsibility(thisMethod);
  }

  *fxArguments {
    // Override this function to define your pedal's specific arguments (e.g., [\tone]);
    // These should match the custom parameters defined and managed in your Lua pedal file.
    ^this.subclassResponsibility(thisMethod);
  }

  *fxDef {
    // Override this function and do your FX work!
    // You will need to return a *function* which receives an argument \wet.ar with the signal to be modified,
    // and return it once you're done effecting it.
    // E.g.: *fxDef{ ^{|wet| ^wet;}; }
    ^this.subclassResponsibility(thisMethod);
  }

  *arguments { ^[\bypass, \mix, \in_gain, \out_gain] ++ this.fxArguments; }

  *addDef {|contextArg|
    context = contextArg;
    SynthDef(this.id, {
      var inL = \inL.kr(0),
      inR = \inR.kr(1),
      out = \out.kr(0),
      bypass = \bypass.kr(0),
      mix = \mix.kr(0.5),
      inGain = \in_gain.kr(1.0),
      outGain = \out_gain.kr(1.0),
      dry, wet, mixdown, effectiveMixRate;

      dry = [In.ar(inL), In.ar(inR)];
      wet = dry * inGain;

      // Call out to our subclass for the actual FX work
      wet = SynthDef.wrap(this.fxDef, prependArgs: [wet]);

      wet = LeakDC.ar(wet * outGain);
      // If bypass is on, act as if the mix is 0% no matter what
      effectiveMixRate = min(mix, 1 - bypass);
      mixdown = Mix.new([dry * (1 - effectiveMixRate), wet * effectiveMixRate]);
      // TODO: consider adding a limiter here
      Out.ar(out, mixdown);
    }).add;
  }
}
