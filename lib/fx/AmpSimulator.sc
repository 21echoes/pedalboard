AmpSimulatorPedal : Pedal {
  *id { ^\ampsimulator; }

  *fxArguments { ^[\drive, \room, \bass, \mid, \treble, \presence]; }

  *fxDef {^{|wet|
    // Adapted from Michel Buffa, Jerome Lebrun "Real time tube guitar amplifier simulation using WebAudio"
    var asymmetric, drive, room, buf, transferFunc;
    drive = \drive.kr(0.5);

    // Define a transfer function simulating the Marshall JCM800's response
    // Originally adapted from Pakarinen, J., & Yeh, D. T. "A review of digital techniques for modeling vacuum-tube guitar amplifiers."
    buf = Buffer.alloc(context.server, 2048, 1);
    transferFunc = Signal.fill(1025, { |i|
      var in = i.linlin(0.0, 1024, -1.0, 1.0);
      if (in <= -1, {
        -0.9818;
      }, {
        if (in < -0.08905, {
          (-0.75 * (1 - ((1 - (in.abs - 0.029847)) ** 12) + (0.333 * (in.abs - 0.029847)))) + 0.01;
        }, {
          if (in < 0.320018, {
            (-6.153 * (in ** 2)) + (3.9375 * in);
          }, {
            0.6140341 + (0.05 * in);
          });
        });
      });
    });
    buf.sendCollection(transferFunc.asWavetableNoWrap);

    // Send through an initial pair of low-shelf filters
    wet = BLowShelf.ar(wet, 720, 1, -3.3);
    wet = BLowShelf.ar(wet, 320, 1, -5);
    // Use the transfer function (and xfade it with the "dry" signal based on the drive control)
    asymmetric = Shaper.ar(buf.bufnum, wet);
    wet = XFade2.ar(wet, asymmetric, LinLin.kr(drive, 0, 1, -1, 1));
    wet = LeakDC.ar(wet);
    // Send through another low-shelf and another softclip-esque amplifier
    wet = BLowShelf.ar(wet, 720, 1, -6);
    wet = (wet * LinLin.kr(drive, 0, 1, 1.5, 3.5)).tanh;

    // Send through the tone section
    wet = BLowShelf.ar(wet, freq: 100, db: \bass.kr(0));
    wet = BPeakEQ.ar(wet, freq: 1700, rq: 0.7071.reciprocal, db: \mid.kr(0));
    wet = BHiShelf.ar(wet, freq: 6500, db: \treble.kr(0));
    wet = BPeakEQ.ar(wet, freq: 3900, db: LinLin.kr(\presence.kr(0.5), 0, 1, -12, 12));

    // Filter out some harsh frequencies
    wet = BPeakEQ.ar(wet, freq: 10000, db: -25);
    wet = BPeakEQ.ar(wet, freq: 60, db: -19);

    // Finally, send through a basic reverb
    room = \room.kr(0.5);
    wet = FreeVerb.ar(
      wet, mix: LinExp.kr(room, 0, 1, 0.2, 0.8),
      room: LinExp.kr(room, 0, 1, 0.2, 0.8),
      damp: LinExp.kr(room, 0, 1, 0.9, 0.1)
    );
  }}
}
