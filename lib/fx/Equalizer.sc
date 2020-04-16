EqualizerPedal : Pedal {
  *id { ^\equalizer; }

  *fxArguments { ^[\ls_freq, \ls_amp, \mid_freq, \mid_q, \mid_amp, \hs_freq, \hs_amp]; }

  *fxDef {^{|wet|
    wet = BLowShelf.ar(wet, freq: \ls_freq.kr(70), db: \ls_amp.kr(1.0).ampdb);
    wet = BPeakEQ.ar(wet, freq: \mid_freq.kr(1000), rq: \mid_q.kr(1.0).reciprocal, db: \mid_amp.kr(1.0).ampdb);
    wet = BHiShelf.ar(wet, freq: \hs_freq.kr(5000), db: \hs_amp.kr(1.0).ampdb);
  }}
}
