// polyform lite - nb editon v0.2 @sonoCircuit

NB_PolyForm {

	*initClass {

		var synthParams, synthGroup, synthVoices;
		var numVoices = 6;

		synthParams = Dictionary.newFrom([
			\lastFreq, 110,
			\pitchBend, 1,
			\glide, 0,
			\amp, 0.8,
			\panDrift, 0,
			\mix, -0.6,
			\sawTune, 0,
			\pulseTune, 0,
			\sawShape, 1,
			\pulseWidth, 0.5,
			\cutoffLpf, 1200,
			\rezLpf, 0.2,
			\envDepthLpf, 0.24,
			\modDepth, 0,
			\mixMod, 0,
			\cutLpfMod, 0,
			\sawShapeMod, 0,
			\pulseWidthMod, 0,
			\attack, 0.01,
			\decay, 0.6,
			\sustain, 0.5,
			\release, 2.2,
			\sendA, 0,
			\sendB, 0
		]);

		StartUp.add {

			synthVoices = Array.newClear(numVoices);

			OSCFunc.new({ |msg|
				if (synthGroup.isNil) {

					synthGroup = Group.new(Server.default);

					SynthDef(\nb_polyForm,{
						arg out = 0, sendABus = 0, sendBBus = 0,
						freq = 110, lastFreq = 110, glide = 0, pitchBend = 1, bendDepth = 0,
						vel = 0.8, amp = 1.0, panDrift = 0, mix = 0, sendA = 0, sendB = 0,
						sawTune = 0, pulseTune = 0, sawShape = 1, pulseWidth = 0.5,
						cutoffLpf = 1200, rezLpf = 0.1, envDepthLpf = 0.2, modDepth = 0,
						gate = 1, attack = 0.01, decay = 0.6, sustain = 0.5, release = 2.2,
						mixMod = 0, cutLpfMod = 0, sawShapeMod = 0, pulseWidthMod = 0, sendAMod = 0, sendBMod = 0;

						var env, freqSaw, freqPulse, oscSaw, oscPulse, snd, cutLin, cutoff, rqLpf;
						
						// envelope
						env = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction: 2);

						// lag, rescale, clamp
						sendA = Lag.kr(sendA + (sendAMod * modDepth)).clip(0, 1);
						sendB = Lag.kr(sendB + (sendBMod * modDepth)).clip(0, 1);
						sawShape = Lag.kr(sawShape + (sawShapeMod * modDepth)).clip(0.02, 0.98);
						pulseWidth = Lag.kr(pulseWidth + (pulseWidthMod * modDepth)).clip(0.02, 0.98);
						mix = Lag.kr(mix + (mixMod * modDepth)).clip(-1, 1);
						
						cutLin = cutoffLpf.explin(20, 18000, 0, 1) + (env * envDepthLpf) + (cutLpfMod * modDepth);
						cutoff = cutLin.linexp(0, 1, 20, 18000);
						rqLpf = rezLpf.linlin(0, 1, 0, 4);
						
						// pitch
						freq = XLine.kr(lastFreq, freq, glide);
						freq = (freq * (pitchBend * bendDepth).midiratio).clip(20, 20000);
						freqSaw = Lag.kr(freq * sawTune.midiratio);
						freqPulse = Lag.kr(freq * pulseTune.midiratio);
						
						// oscillator
						oscSaw = VarSaw.ar(freqSaw, sawShape/2, sawShape);
						oscPulse = Pulse.ar(freqPulse, pulseWidth);
						snd = XFade2.ar(oscSaw, oscPulse, mix);
						
						// lpf and output stage
						snd = MoogFF.ar(snd, cutoff, rqLpf);
						snd = (snd * amp * env * vel).tanh * -9.dbamp;
						snd = Pan2.ar(snd, panDrift * Rand(-0.7, 0.7));

						Out.ar(out, snd);
						Out.ar(sendABus, sendA * snd);
						Out.ar(sendBBus, sendB * snd);
					}).add;

					"nb polyform initialized".postln;
				};
			}, "/nb_polyform/init");

			OSCFunc.new({ |msg|
				var vox = msg[1].asInteger;
				var freq = msg[2].asFloat;
				var vel = msg[3].asFloat;
				var syn;
				if (synthGroup.notNil) {
					if (synthVoices[vox].notNil) { synthVoices[vox].set(\gate, -1.05) };
					syn = Synth.new(\nb_polyForm,
						[
							\freq, freq,
							\vel, vel,
							\sendABus, ~sendA ? Server.default.outputBus,
							\sendBBus, ~sendB ? Server.default.outputBus,
						] ++ synthParams.getPairs, target: synthGroup
					);
					synthVoices[vox] = syn;
					syn.onFree({ if(synthVoices[vox] === syn) {synthVoices[vox] = nil} });
					synthParams[\lastFreq] = freq;
				};
			}, "/nb_polyform/note_on");

			OSCFunc.new({ |msg|
				var vox = msg[1].asInteger;
				if (synthVoices[vox].notNil) { synthVoices[vox].set(\gate, 0) };
			}, "/nb_polyform/note_off");

			OSCFunc.new({ |msg|
				var key = msg[1].asSymbol;
				var val = msg[2].asFloat;
				if (synthGroup.notNil) {
					synthGroup.set(key, val);
				};
				synthParams[key] = val;
			}, "/nb_polyform/set_param");

			OSCFunc.new({ |msg|
				if (synthGroup.notNil) {
					synthGroup.set(\gate, -1.05);
				};
			}, "/nb_polyform/panic");

			OSCFunc.new({ |msg|
				if (synthGroup.notNil) {
					synthGroup.free;
					synthGroup = nil;
					numVoices.do({ arg vox;
						synthVoices[vox] = nil
					});
					"nb polyform removed".postln;
				};
			}, "/nb_polyform/free");
			
		}
	}
}
