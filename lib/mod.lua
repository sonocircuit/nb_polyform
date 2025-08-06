-- polyform lite - nb edition v0.1 @sonoCircuit

local tx = require 'textentry'
local mu = require 'musicutil'
local md = require 'core/mods'
local vx = require 'voice'

local p = {
  amp = 0.8, spread = 0, mix = -0.6, send_a = 0, send_b = 0,
  saw_tune = 0, pulse_tune = 0, saw_shape = 1, pulse_width = 0.5,
  cutoff_lpf = 1200, res_lpf = 0.1, env_lpf_depth = 0.2, attack = 0.001, decay = 0.8
}

local preset_path = "/home/we/dust/data/nb_polyform/polyform_patches"
local default_patch = "/home/we/dust/data/nb_polyform/polyform_patches/default.patch"
local failsafe_patch = "/home/we/dust/code/nb_polyform/data/polyform_patches/default.patch"
local current_patch = ""

local function save_synth_patch(txt)
  if txt then
    local patch = {}
    for k, v in pairs(p) do
      patch[k] = params:get("nb_polyform_"..k)
    end
    tab.save(patch, preset_path.."/"..txt..".patch")
    current_patch = txt
    params:set("nb_polyform_load_patch", preset_path.."/"..txt..".patch", true)
    print("saved patch : "..txt)
  end
end

local function load_synth_patch(path)
  if path ~= "cancel" and path ~= "" then
    --polyForm.panic(i)
    if path:match("^.+(%..+)$") == ".patch" then
      local patch = tab.load(path)
      if patch ~= nil then
        for k, v in pairs(patch) do
          params:set("nb_polyform_"..k, v)
        end
        local name = path:match("[^/]*$")
        current_patch = name:gsub(".patch", "")
        print("loaded patch : "..name)
      else
        if util.file_exists(failsafe_patch) then
          load_synth_patch(failsafe_patch)
        end
        print("error: could not find patch", path)
      end
    else
      print("error: not a polyform patch file")
    end
  end
end

local function round_form(param, quant, form)
  return(util.round(param, quant)..form)
end

local function mix_display(param)
  local saw = util.round(util.linlin(-1, 1, 100, 0, param), 1)
  local pulse = util.round(util.linlin(-1, 1, 0, 100, param), 1)
  return saw.."/"..pulse
end

local function add_nb_polyform_params()
  params:add_group("nb_polyform_group", "polyform", 21)
  params:hide("nb_polyform_group")

  params:add_separator("nb_polyform_patches", "presets")

  params:add_file("nb_polyform_load_patch", ">> load", default_patch)
  params:set_action("nb_polyform_load_patch", function(path) load_synth_patch(path) end)

  params:add_trigger("nb_polyform_save_patch", "<< save")
  params:set_action("nb_polyform_save_patch", function() tx.enter(save_synth_patch, current_patch) end)

  params:add_separator("nb_polyform_levels", "levels")
  params:add_control("nb_polyform_amp", "amp", controlspec.new(0, 1, "lin", 0, p.amp), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_amp", function(x) p.amp = x end)

  params:add_control("nb_polyform_spread", "spread", controlspec.new(0, 1, "lin", 0, p.spread), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_spread", function(x) p.spread = x end)

  params:add_control("nb_polyform_send_a", "send a", controlspec.new(0, 1, "lin", 0, p.send_a), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_send_a", function(x) p.send_a = x end)
  
  params:add_control("nb_polyform_send_b", "send b", controlspec.new(0, 1, "lin", 0, p.send_b), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_send_b", function(x) p.send_b = x end)

  params:add_separator("nb_polyform_osc", "oscillators")
  params:add_control("nb_polyform_mix", "mix [saw/pulse]", controlspec.new(-1, 1, "lin", 0, p.mix), function(param) return mix_display(param:get()) end)
  params:set_action("nb_polyform_mix", function(x) p.mix = x end)

  params:add_control("nb_polyform_saw_tune", "saw tune", controlspec.new(-24, 24, "lin", 0, p.saw_tune, "", 1/480), function(param) return (round_form(param:get(), 0.01, "st")) end)
  params:set_action("nb_polyform_saw_tune", function(x) p.saw_tune = x end)

  params:add_control("nb_polyform_saw_shape", "saw shape", controlspec.new(0, 1, "lin", 0, p.saw_shape), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_saw_shape", function(x) p.saw_shape = util.linlin(0, 1, 0.5, 1, x) end)

  params:add_control("nb_polyform_pulse_tune", "pulse tune", controlspec.new(-24, 24, "lin", 0, p.pulse_tune, "", 1/480), function(param) return (round_form(param:get(), 0.01, "st")) end)
  params:set_action("nb_polyform_pulse_tune", function(x) p.pulse_tune = x end)

  params:add_control("nb_polyform_pulse_width", "pulse width", controlspec.new(0.1, 0.9, "lin", 0, p.pulse_width), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_pulse_width", function(x) p.pulse_width = x end)

  params:add_separator("nb_polyform_filter", "lp filter")

  params:add_control("nb_polyform_cutoff_lpf", "cutoff", controlspec.new(20, 18000, "exp", 0, p.cutoff_lpf), function(param) return round_form(param:get(), 1, " hz") end)
  params:set_action("nb_polyform_cutoff_lpf", function(x) p.cutoff_lpf = x end)

  params:add_control("nb_polyform_res_lpf", "resonance", controlspec.new(0, 1, "lin", 0, p.res_lpf), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_res_lpf", function(x) p.res_lpf = x end)

  params:add_control("nb_polyform_env_lpf_depth", "env depth", controlspec.new(-1, 1, "lin", 0, p.env_lpf_depth), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_env_lpf_depth", function(x) p.env_lpf_depth = x end)

  params:add_separator("nb_polyform_env", "envelope")

  params:add_control("nb_polyform_attack", "attack", controlspec.new(0.001, 10, "exp", 0, p.attack), function(param) return (round_form(param:get(),0.01," s")) end)
  params:set_action("nb_polyform_attack", function(x) p.attack = x end)

  params:add_control("nb_polyform_decay", "decay", controlspec.new(0.01, 10, "exp", 0, p.decay), function(param) return (round_form(param:get(),0.01," s")) end)
  params:set_action("nb_polyform_decay", function(x) p.decay = x end)

end

function add_nb_polyform_player()
  local player = {
    is_active = false,
    active_routine = nil
  }

  function player:active()
    if self.name ~= nil then
      self.is_active = true
      self.active_routine = clock.run(function()
        clock.sleep(1)
        if self.is_active then
          params:set("nb_polyform_load_patch", default_patch)
        end
        self.active_routine = nil
      end)
      params:show("nb_polyform_group")
      if md.is_loaded("fx") == false then
        params:hide("nb_polyform_send_a")
        params:hide("nb_polyform_send_b")
      end
      _menu.rebuild_params()
    end
  end

  function player:inactive()
    if self.name ~= nil then
      self.is_active = false
      if self.active_routine ~= nil then
          clock.cancel(self.active_routine)
      end
      params:hide("nb_polyform_group")
      _menu.rebuild_params()
    end
  end

  function player:stop_all()

  end

  function player:modulate(val)

  end

  function player:set_slew(s)
    
  end

  function player:describe()
    return {
      name = "nb_polyform",
      supports_bend = false,
      supports_slew = false
    }
  end

  function player:pitch_bend(note, amount)

  end

  function player:modulate_note(note, key, value)

  end

  function player:note_on(note, vel, properties)
    local level = p.amp * vel * vel
    osc.send({ "localhost", 57120 }, "/nb_polyform/note_on", {
      note,
      level,
      p.spread,
      p.mix,
      p.saw_tune,
      p.pulse_tune,
      p.saw_shape,
      p.pulse_width,
			p.cutoff_lpf,
      p.res_lpf,
      p.env_lpf_depth,
      p.attack,
      p.decay,
      p.send_a,
      p.send_b
    })
  end

  function player:note_off(note)

  end

  function player:add_params()
    add_nb_polyform_params(i)
  end

  if note_players == nil then
    note_players = {}
  end
  note_players["polyform"] = player
end

local function post_system()
  if util.file_exists(preset_path) == false then
    util.make_dir(preset_path)
    os.execute('cp '.. '/home/we/dust/code/nb_polyform/data/polyform_patches/*.patch '.. preset_path)
  end
end

local function pre_init()
  add_nb_polyform_player()
end

md.hook.register("system_post_startup", "nb_polyform post startup", post_system)
md.hook.register("script_pre_init", "nb_polyform pre init", pre_init)