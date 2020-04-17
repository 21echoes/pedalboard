AutoWahPedal : Pedal {
  *id { ^\autowah; }

  *fxArguments { ^[\rate, \depth, \sensitivity, \mode, \res]; }

  *fxDef {^{|wet|
    var sensitivityMultiplier, envelopeFollower, depth, res, rq, bpMultiplier, formantRatio,
    minCutoffFreq1, maxCutoffFreq1, cutoffFreq1, minCutoffFreq2, maxCutoffFreq2, cutoffFreq2;
    sensitivityMultiplier = LinLin.kr(\sensitivity.kr(0.5), 0, 1, 3, 9);
    envelopeFollower = Lag.ar(EnvFollow.ar(
      (wet * sensitivityMultiplier).clip(-1, 1), 0.999
    ),
    // 0.1225
    LinExp.kr(\rate.kr(0.5), 0, 1, 0.4, 0.0375));

    depth = \depth.kr(0.5);
    // 194
    minCutoffFreq1 = LinExp.kr(depth, 0, 1, 440, 85);
    // 1386
    maxCutoffFreq1 = LinExp.kr(depth, 0, 1, 1100, 1750);
    cutoffFreq1 = LinExp.ar(envelopeFollower, 0, 1, minCutoffFreq1, maxCutoffFreq1);
    // 1140
    minCutoffFreq2 = LinExp.kr(depth, 0, 1, 1450, 900);
    // 2445
    maxCutoffFreq2 = LinExp.kr(depth, 0, 1, 2175, 2750);
    cutoffFreq2 = LinExp.ar(envelopeFollower, 0, 1, minCutoffFreq2, maxCutoffFreq2);
    res = \res.kr(0.5);
    rq = LinExp.kr(res, 0, 1, 0.325, 0.01925);
    bpMultiplier = LinLin.kr(res, 0, 1, 2.5, 7.5);
    formantRatio = 0.75;
    wet = Select.ar(\mode.kr(0), [
      (RLPF.ar(wet, cutoffFreq1, rq, formantRatio) + RLPF.ar(wet, cutoffFreq2, rq, (1-formantRatio))) * 0.67,
      ((BPF.ar(wet, cutoffFreq1, rq * 2, formantRatio) + BPF.ar(wet, cutoffFreq2, rq * 2, (1-formantRatio))) * bpMultiplier).softclip,
      (RHPF.ar(wet, cutoffFreq1, rq, formantRatio) + RHPF.ar(wet, cutoffFreq2, rq, (1-formantRatio))) * 0.75,
    ]);
  }}
}
