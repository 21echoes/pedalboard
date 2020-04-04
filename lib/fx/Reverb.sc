ReverbPedal {
  *id { ^\reverb; }

  *arguments { ^[\bypass, \mix, \in_gain, \out_gain, \damp, \size]; }

  *addDef {
    SynthDef(this.id, {
      // Stock defn (TODO: extract to shared UGen)
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

      // FX work starts here
      wet = JPverb.ar(
          wet,
          \t60.kr(1,           0.05),
          \damp.kr(0,          0.05),
          \size.kr(1,          0.05),
          \earlydiff.kr(0.707, 0.05),
          \mdepth.kr(5,        0.05),
          \mfreq.kr(2,         0.05),
          \lowx.kr(1,          0.05),
          \midx.kr(1,          0.05),
          \highx.kr(1,         0.05),
          \lowband.kr(500,     0.05),
          \highband.kr(2000,   0.05)
      );

      // Stock defn (TODO: extract to shared UGen)
      wet = LeakDC.ar(wet * outGain);
      // If bypass is on, act as if the mix is 0% no matter what
      effectiveMixRate = min(mix, 1 - bypass);
      mixdown = Mix.new([dry * (1 - effectiveMixRate), wet * effectiveMixRate]);
      Out.ar(out, mixdown);
    }).add;
  }
}
