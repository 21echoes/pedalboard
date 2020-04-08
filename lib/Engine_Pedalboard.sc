Engine_Pedalboard : CroneEngine {
  var allPedalDefinitions;
  var allPedalIds;
  var boardIds;
  var pedalDetails;
  var buses;
  var passThru;

  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    // Set up pedal definitions and commands
    allPedalDefinitions = [
      BitcrusherPedal,
      ChorusPedal,
      CompressorPedal,
      DelayPedal,
      DistortionPedal,
      FlangerPedal,
      OverdrivePedal,
      ReverbPedal,
      SustainPedal,
      TremoloPedal
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
    SynthDef(\passThru, {|inL, inR, out|
      Out.ar(out, [In.ar(inL), In.ar(inR)]);
    }).add;
    context.server.sync;

    boardIds = List[];
    buses = List.new;

    // Set up commands for board management
    this.addCommand("add_pedal", "s", {|msg| this.addPedal(msg[1]);});
    this.addCommand("insert_pedal_at_index", "is", {|msg| this.insertPedalAtIndex(msg[1], msg[2]);});
    this.addCommand("remove_pedal_at_index", "i", {|msg| this.removePedalAtIndex(msg[1]);});
    this.addCommand("swap_pedal_at_index", "is", {|msg| this.swapPedalAtIndex(msg[1], msg[2]);});

    this.buildNoPedalState;

    // TODO: before outs, put a basic Limiter.ar(mixdown, 1.0) ?
  }

  buildNoPedalState {
    passThru = Synth.new(\passThru, [
      \inL, context.in_b[0].index,
      \inR, context.in_b[1].index,
      \out, context.out_b.index,
    ], context.xg);
  }

  addPedal {|pedalId|
    this.insertPedalAtIndex(boardIds.size, pedalId);
  }

  insertPedalAtIndex {|index, pedalId|
    var inL, inR, out, target, addAction;
    if (index == 0, {
      // The first pedal always has the main ins as its inputs, and is added to the head of the group
      inL = context.in_b[0].index;
      inR = context.in_b[1].index;
      target = context.xg;
      addAction = \addToHead;
    });
    if (index == boardIds.size, {
      // The last pedal always has the main outs as its outputs
      out = context.out_b.index;
    });
    if (boardIds.size != 0, {
      // If there's pedals, we have to make a bus to patch in to the existing pedals
      var bus;
      bus = Bus.audio(context.server, 2);
      if (index == boardIds.size, {
        // The last pedal uses the bus as its inputs
        inL = bus.index;
        inR = bus.index + 1;
      }, {
        // The other pedals use the new bus as their output
        out = bus.index;
        if (index != 0, {
          // Middle pedals also use the existing bus coming out of the pedal already at their index as their input
          var priorBus = buses[index - 1],
          inL = priorBus.index;
          inR = priorBus.index + 1;
        });
      });
      if (index != 0, {
        // If we're not the first pedal, define which pedal we're going after
        target = pedalDetails[boardIds[index - 1]][\synth];
        addAction = \addAfter;
      });
      buses.insert(index, bus);
    });
    pedalDetails[pedalId][\synth] = Synth.new(
      pedalId,
      pedalDetails[pedalId][\arguments].merge((inL: inL, inR: inR, out: out)).getPairs,
      target,
      addAction
    );
    if (boardIds.size == 0, {
      // If there used to be no pedals, we have to free up the passThru synth
      passThru.free;
    }, {
      if (index == boardIds.size, {
        // The new last pedal, if there are already pedals,
        // sets the output of the current last pedal as the new last pedal's input
        pedalDetails[boardIds[index - 1]][\synth].set(\out, inL);
      }, {
        // The new first pedal, if there are already pedals,
        // sets the input of the current first pedal as the new first pedal's output
        pedalDetails[boardIds[index]][\synth].set(\inL, out, \inR, out + 1);
      });
    });
    boardIds.insert(index, pedalId);
  }

  removePedalAtIndex {|index|
    if (boardIds.size == 1, {
      this.buildNoPedalState;
    }, {
      if (index == 0, {
        var nextPedal = pedalDetails[boardIds[index + 1]][\synth];
        nextPedal.set(\inL, context.in_b[0].index, \inR, context.in_b[1].index);
        buses[index].free;
        buses.removeAt(index);
      }, {
        var priorPedal = pedalDetails[boardIds[index - 1]][\synth];
        if (index == (boardIds.size - 1), {
          priorPedal.set(\out, context.out_b);
        }, {
          priorPedal.set(\out, buses[index]);
        });
        buses[index - 1].free;
        buses.removeAt(index - 1);
      });
    });
    pedalDetails[boardIds[index]][\synth].free;
    pedalDetails[boardIds[index]][\synth] = nil;
    boardIds.removeAt(index);
  }

  swapPedalAtIndex {|index, newPedalId|
    this.removePedalAtIndex(index);
    this.insertPedalAtIndex(index, newPedalId);
  }

  movePedal {|fromIndex, toIndex|
    // TODO later
  }

  free {
    buses.do({|bus| bus.free; });
    allPedalIds.do({|pedalId| pedalDetails[pedalId][\synth].free;});
    passThru.free;
  }
}
