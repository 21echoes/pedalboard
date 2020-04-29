Engine_Pedalboard : CroneEngine {
  var allPedalDefinitions;
  var allPedalIds;
  var boardIds;
  var pedalDetails;
  var buses;
  var passThru;
  var inputStage;
  var inputAmp = 1;
  var outputStage;
  var outputAmp = 1;
  var numInputChannels = 2;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    // Set up pedal definitions and commands
    allPedalDefinitions = [
      AmpSimulatorPedal,
      AutoWahPedal,
      BitcrusherPedal,
      ChorusPedal,
      CompressorPedal,
      DelayPedal,
      DistortionPedal,
      EqualizerPedal,
      FlangerPedal,
      LoFiPedal,
      OverdrivePedal,
      PhaserPedal,
      PitchShifterPedal,
      ReverbPedal,
      RingModulatorPedal,
      SubBoostPedal,
      SustainPedal,
      TremoloPedal,
      TunerPedal,
      VibratoPedal,
      WavefolderPedal,
    ];
    allPedalIds = List.new;
    pedalDetails = Dictionary.new;
    allPedalDefinitions.do({|pedalDefinition|
      pedalDefinition.addDef(context);
      allPedalIds.add(pedalDefinition.id);
      pedalDetails[pedalDefinition.id] = Dictionary.new;
      pedalDetails[pedalDefinition.id][\arguments] = Dictionary.new;
      pedalDefinition.arguments.do({|argument|
        this.addCommand(pedalDefinition.id ++ "_" ++ argument, "f", {|msg|
          pedalDetails[pedalDefinition.id][\arguments].add(argument -> msg[1]);
          if (pedalDetails[pedalDefinition.id][\synth].notNil, {
            pedalDetails[pedalDefinition.id][\synth].set(argument, msg[1]);
          });
        });
      });
    });

    // Make a simple passthru synth for the empty board
    SynthDef(\passThru, {|inL, inR, out, amp=1|
      Out.ar(out, [In.ar(inL), In.ar(inR)] * amp);
    }).add;
    context.server.sync;

    boardIds = List[];
    buses = List.new;
    // Start the buses with a bus coming from inputStage and a bus going to outputStage
    buses.add(Bus.audio(context.server, 2));
    buses.add(Bus.audio(context.server, 2));

    // make the inputStage and outputStage and connect the input and output buses
    inputStage = Synth.new(\passThru, [
      \inL, this.getInL,
      \inR, this.getInR,
      \out, buses[0].index,
      \amp, inputAmp,
    ], context.xg);
    outputStage = Synth.new(\passThru, [
      \inL, buses[1].index,
      \inR, buses[1].index + 1,
      \out, context.out_b.index,
      \amp, outputAmp,
    ], inputStage, \addAfter);

    // Set up commands for board management
    this.addCommand("add_pedal", "s", {|msg| this.addPedal(msg[1]);});
    this.addCommand("insert_pedal_at_index", "is", {|msg| this.insertPedalAtIndex(msg[1], msg[2]);});
    this.addCommand("remove_pedal_at_index", "i", {|msg| this.removePedalAtIndex(msg[1]);});
    this.addCommand("swap_pedal_at_index", "is", {|msg| this.swapPedalAtIndex(msg[1], msg[2]);});
    this.addCommand("set_num_input_channels", "i", {|msg| this.setNumInputChannels(msg[1]);});
    this.addCommand("set_input_amp", "f", {|msg| this.setInputAmp(msg[1]);});
    this.addCommand("set_output_amp", "f", {|msg| this.setOutputAmp(msg[1]);});

    this.buildNoPedalState;

    // TODO: before outs, put a basic Limiter.ar(mixdown, 1.0) ?
  }

  buildNoPedalState {
    // Have a no-op "pedal" in the middle to connect buses[1] to buses[2]
    passThru = Synth.new(\passThru, [
      \inL, buses[0].index,
      \inR, buses[0].index + 1,
      \out, buses[1].index,
    ], inputStage, \addAfter);
  }

  addPedal {|pedalId|
    this.insertPedalAtIndex(boardIds.size, pedalId);
  }

  insertPedalAtIndex {|index, pedalId|
    var inL, inR, out, target, addAction = \addAfter, indexToRemove = -1;

    // Don't allow inserting beyond the end of the board (other than adding just onto the end)
    if (index > boardIds.size, {
      index = boardIds.size;
    });

    // If the pedal is already elsewhere in the chain, remove it first.
    // TODO: this could be made somewhat more "correct" by saving synths on a board array, rather than in the id lookup.
    // This would mean a rethinking of how the addCommand works (likely: loop over board until match is found)
    if (pedalDetails[pedalId][\synth].notNil, {
      boardIds.do({|item, i| if (item == pedalId, { indexToRemove = i; }); });
    });
    if (indexToRemove != -1, {
      // No work to do if the pedal is already in the right place
      if (indexToRemove == index, { ^this; });
      this.removePedalAtIndex(indexToRemove);
      // This now results in the pedal not being put at exactly `index`,
      // but for now it's necessary given how we don't allow duplicate pedals
      if (index > indexToRemove, { index = index - 1 });
    });

    // Okay, enough edge cases. Now for the real insertion.
    // Our inputs are always the bus at our target index
    inL = buses[index].index;
    inR = buses[index].index + 1;
    // If there's pedals, we have to make a bus as our output to patch in to the existing pedals
    // (if there's no pedals yet, there's already a bus at buses[1] waiting for us to use)
    if (boardIds.size != 0, {
      buses.insert(index + 1, Bus.audio(context.server, 2));
    });
    // Our output is the bus at index+1
    out = buses[index + 1].index;
    // We add ourselves after the prior pedal (or after the inputStage if there's no pedals yet)
    if (index == 0, {
      target = inputStage;
    }, {
      target = pedalDetails[boardIds[index - 1]][\synth];
    });
    pedalDetails[pedalId][\synth] = Synth.new(
      pedalId,
      pedalDetails[pedalId][\arguments].merge((inL: inL, inR: inR, out: out)).getPairs,
      target,
      addAction
    );
    if (index == boardIds.size, {
        // If we're inserting at the end, we set the outputStage to have its inputs as our outputs
      outputStage.set(\inL, out, \inR, out + 1);
    }, {
      // Otherwise we set the pedal after us's inputs as our outputs
      pedalDetails[boardIds[index]][\synth].set(\inL, out, \inR, out + 1);
    });
    if (boardIds.size == 0, {
      // If there used to be no pedals, we have to free up the passThru synth
      passThru.free;
    });
    boardIds.insert(index, pedalId);
  }

  removePedalAtIndex {|index|
    if (boardIds.size == 1, {
      this.buildNoPedalState;
    }, {
      // Set the pedal (or output stage) after us to have our inputs as its new inputs
      var inputBus = buses[index];
      if (index == (boardIds.size - 1), {
        outputStage.set(\inL, inputBus.index, \inR, inputBus.index + 1);
      }, {
        var nextPedal = pedalDetails[boardIds[index + 1]][\synth];
        nextPedal.set(\inL, inputBus.index, \inR, inputBus.index + 1);
      });
      // Free up the bus we were using as an output
      buses[index + 1].free;
      buses.removeAt(index + 1);
    });
    pedalDetails[boardIds[index]][\synth].free;
    pedalDetails[boardIds[index]][\synth] = nil;
    boardIds.removeAt(index);
  }

  swapPedalAtIndex {|index, newPedalId|
    if (index < boardIds.size, {
      this.removePedalAtIndex(index);
    });
    this.insertPedalAtIndex(index, newPedalId);
  }

  setNumInputChannels {|numChannelsArg|
    numInputChannels = numChannelsArg;
    inputStage.set(\inL, this.getInL, \inR, this.getInR);
  }

  getInL {
    ^context.in_b[0].index;
  }

  getInR {
    if (numInputChannels == 1, {
      ^context.in_b[0].index;
    }, {
      ^context.in_b[1].index;
    });
  }

  setInputAmp {|amp|
    inputAmp = amp;
    inputStage.set(\amp, inputAmp);
  }

  setOutputAmp {|amp|
    outputAmp = amp;
    outputStage.set(\amp, outputAmp);
  }

  free {
    buses.do({|bus| bus.free; });
    allPedalIds.do({|pedalId| pedalDetails[pedalId][\synth].free;});
    outputStage.free;
    passThru.free;
    inputStage.free;
  }
}
