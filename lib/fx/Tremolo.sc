// /* This can be used as a general wrapper to be composed with any other pedal synthdef with a little bit of effort
//  * (convert it into two ugens, one for pre-effect, one for post)
//  * then use like
//   SynthDef(\myPedal, {|args, incl standard args|
//     // TODO: is this the best way to return two stereo signals?
//     dry_and_wet = PedalPhaseOne.ar(inL, etc);
//     dry = dry_and_wet[0];
//     wet = dry_and_wet[1];
//     // do fx work on wet
//     Out.ar(out, PedalPhaseTwo.ar(dry, wet, mix, bypass, etc));
//   })
// */

TremoloPedal {
  *id { ^\tremolo; }

  *arguments { ^[\bypass, \mix, \in_gain, \out_gain, \rate, \depth]; }

  *addDef {
    SynthDef(this.id, {
      var inL = \inL.kr(0),
      inR = \inR.kr(1),
      out = \out.kr(0),
      bypass = \bypass.kr(0),
      mix = \mix.kr(0.5),
      inGain = \in_gain.kr(1.0),
      outGain = \out_gain.kr(1.0),
      dry, wet, mixdown, effectiveMixRate,
      rate, depth, ampMod; // this line is custom;
      dry = [In.ar(inL), In.ar(inR)];
      wet = dry * inGain;

      // FX work starts here
      rate = LinExp.kr(\rate.kr(0.5), 0, 1, 0.5, 10);
      depth = LinLin.kr(\depth.kr(0.5), 0, 1, 0, 0.5);
      // unipolar from 1 down to at most zero (controlled by depth)
      // TODO: Shape controls (wavetable sin->tri->saw->sq)
      ampMod = LFTri.kr(rate, 0, depth, 1 - depth);
      wet = wet * ampMod;

      wet = LeakDC.ar(wet * outGain);
      // If bypass is on, act as if the mix is 0% no matter what
      effectiveMixRate = min(mix, 1 - bypass);
      mixdown = Mix.new([dry * (1 - effectiveMixRate), wet * effectiveMixRate]);
      Out.ar(out, mixdown);
    }).add;
  }
}
