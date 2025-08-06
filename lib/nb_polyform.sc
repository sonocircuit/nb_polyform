// polyform lite - nb editon v.0.1 @sonoCircuit

NB_PolyForm {

    *initClass {

        StartUp.add {
            (Routine.new {
                Server.default.sync;
            }).play;

            SynthDef(\nb_polyForm, {
                arg note = 60, amp = 1.0, spread = 0, mix = 0,
        				saw_tune = 0, pulse_tune = 0, saw_shape = 1, pulse_width = 0.5,
        				cutoff_lpf = 1200, res_lpf = 0.1, env_lpf_depth = 0.2,
        				gate = 1, attack = 0.001, decay = 0.8,
        				sendA = 0, sendB = 0,
        				out = 0, sendABus = 0, sendBBus = 0;
        
        				var env = EnvGen.kr(Env.perc(attack, decay), gate, doneAction: 2);
        
        				var freq = note.midicps;
        				var freq_saw = Lag.kr(freq * 2.pow(saw_tune / 12));
        			    var freq_pulse = Lag.kr(freq * 2.pow(pulse_tune / 12));
        				var osc_saw = VarSaw.ar(freq_saw, 0.248, saw_shape);
        				var osc_pulse = Pulse.ar(freq_pulse, pulse_width);
        				var osc_mix = XFade2.ar(osc_saw, osc_pulse, mix, amp) * -6.dbamp;
        
        				var	cut_lin_lpf = cutoff_lpf.explin(20, 18000, 0, 1);
        				var	cut_lpf_mod = cut_lin_lpf + (env * env_lpf_depth);
        				var	cutoff = cut_lpf_mod.linexp(0, 1, 20, 18000).max(20).min(18000);
        				var	rq_lpf = res_lpf.linlin(0, 1, 0, 4);
        				var	osc_lpf = MoogFF.ar(osc_mix, cutoff, rq_lpf) * env;

                var snd = Pan2.ar(osc_lpf, spread * Rand(-0.7, 0.7));

                Out.ar(out, snd);
                Out.ar(sendABus, sendA * snd);
                Out.ar(sendBBus, sendB * snd);
            }).add;

            OSCFunc.new({ |msg, time, addr, recvPort|
                var args = [
          					[\note, \amp, \spread, \mix, \saw_tune, \pulse_tune, \saw_shape, \pulse_width,
          					\cutoff_lpf, \res_lpf, \env_lpf_depth, \attack, \decay, \sendA, \sendB],
                    msg[1..]
                    ].lace;
                Synth.new(
                    \nb_polyForm,
                    args
                    ++ [
                     \sendABus, (~sendA ? Server.default.outputBus),
                     \sendBBus, (~sendB ? Server.default.outputBus)]);
            }, "/nb_polyform/note_on");

        }
    }
}
