// polyform lite - nb editon v0.1 @sonoCircuit

NB_PolyForm {

	*initClass {

		var synthParams, synthGroup, synthVoices;
		var numVoices = 6;

		synthParams = Dictionary.newFrom([
			\amp, 0.8,
			\spread, 0,
			\mix, -0.6,
			\saw_tune, 0,
			\pulse_tune, 0,
			\saw_shape, 1,
			\pulse_width, 0.5,
			\cutoff_lpf, 1200,
			\res_lpf, 0.2,
			\env_lpf_depth, 0.24,
			\moddepth, 0,
			\cut_lpf_mod, 0,
			\saw_shape_mod, 0,
			\pulse_width_mod, 0,
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

					synthGroup = ParGroup.new(Server.default);

					SynthDef(\nb_polyForm,{
						arg out = 0, sendABus = 0, sendBBus = 0,
						freq = 110, vel = 0.8, amp = 1.0, spread = 0, mix = 0, sendA = 0, sendB = 0,
						saw_tune = 0, pulse_tune = 0, saw_shape = 1, pulse_width = 0.5,
						cutoff_lpf = 1200, res_lpf = 0.1, env_lpf_depth = 0.2, moddepth = 0,
						gate = 1, attack = 0.01, decay = 0.6, sustain = 0.5, release = 2.2,
						mix_mod = 0, cut_lpf_mod = 0, saw_shape_mod = 0, pulse_width_mod = 0;

						var env = EnvGen.kr(Env.adsr(attack, decay, sustain, release), gate, doneAction: 2);

						var freq_saw = Lag.kr(freq * 2.pow(saw_tune / 12));
						var freq_pulse = Lag.kr(freq * 2.pow(pulse_tune / 12));

						var osc_saw = VarSaw.ar(freq_saw, 0.248, (saw_shape + (saw_shape_mod * moddepth)).clip(-1, 1));
						var osc_pulse = Pulse.ar(freq_pulse, (pulse_width + (pulse_width_mod * moddepth)).clip(0.02, 0.98));
						var osc_mix = XFade2.ar(osc_saw, osc_pulse, (mix + (mix_mod * moddepth)).clip(-1, 1)) * -9.dbamp;

						var	cut_lin_lpf = cutoff_lpf.explin(20, 18000, 0, 1);
						var	cut_lpf_val = cut_lin_lpf + (env * env_lpf_depth) + (cut_lpf_mod * moddepth);
						var	cutoff = cut_lpf_val.linexp(0, 1, 20, 18000);
						var	rq_lpf = res_lpf.linlin(0, 1, 0, 4);

						var	osc_lpf = MoogFF.ar(osc_mix, cutoff, rq_lpf);

						var snd = Pan2.ar(osc_lpf, Lag3.kr(spread * Rand(-0.7, 0.7), 0.2));

						snd = snd * amp * env * vel;

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
