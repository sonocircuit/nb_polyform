-- polyform lite - nb edition v0.1 @sonoCircuit

local tx = require 'textentry'
local mu = require 'musicutil'
local md = require 'core/mods'
local vx = require 'voice'

local preset_path = "/home/we/dust/data/nb_polyform/polyform_patches"
local default_patch = "/home/we/dust/data/nb_polyform/polyform_patches/default.patch"
local failsafe_patch = "/home/we/dust/code/nb_polyform/data/polyform_patches/default.patch"
local current_patch = ""
local is_active = false

local NUM_VOICES = 6

local paramlist = {
  "amp", "spread", "send_a", "send_b", "mix", "saw_tune", "pulse_tune", "saw_shape", "pulse_width",
  "cutoff_lpf", "res_lpf", "env_lpf_depth", "attack", "decay", "sustain", "release",
  "mix_mod", "cut_lpf_mod", "saw_shape_mod", "pulse_width_mod"
}


---------------- osc msgs ----------------

local function init_nb_polyform()
  osc.send({ "localhost", 57120 }, "/nb_polyform/init")
end

local function free_nb_polyform()
  osc.send({ "localhost", 57120 }, "/nb_polyform/free")
end

local function dont_panic()
  osc.send({ "localhost", 57120 }, "/nb_polyform/panic")
end

local function set_param(key, val)
  osc.send({ "localhost", 57120 }, "/nb_polyform/set_param", {key, val})
end


---------------- functions ----------------

local function save_synth_patch(txt)
  if txt then
    local patch = {}
    for _, v in ipairs(paramlist) do
      patch[v] = params:get("nb_polyform_"..v)
    end
    tab.save(patch, preset_path.."/"..txt..".patch")
    current_patch = txt
    params:set("nb_polyform_load_patch", preset_path.."/"..txt..".patch", true)
    print("saved polyform patch: "..txt)
  end
end

local function load_synth_patch(path)
  if is_active then
    if path ~= "cancel" and path ~= "" then
      dont_panic()
      if path:match("^.+(%..+)$") == ".patch" then
        local patch = tab.load(path)
        if patch ~= nil then
          for k, v in pairs(patch) do
            params:set("nb_polyform_"..k, v)
          end
          local name = path:match("[^/]*$")
          current_patch = name:gsub(".patch", "")
          print("loaded polyform: "..current_patch)
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
  params:add_group("nb_polyform_group", "polyform", 28)
  params:hide("nb_polyform_group")

  params:add_separator("nb_polyform_patches", "presets")

  params:add_file("nb_polyform_load_patch", ">> load", default_patch)
  params:set_action("nb_polyform_load_patch", function(path) load_synth_patch(path) end)
  
  params:add_trigger("nb_polyform_save_patch", "<< save")
  params:set_action("nb_polyform_save_patch", function() tx.enter(save_synth_patch, current_patch) end)

  params:add_separator("nb_polyform_levels", "levels")
  params:add_control("nb_polyform_amp", "amp", controlspec.new(0, 1, "lin", 0, 0.8), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_amp", function(val) set_param('amp', val) end)

  params:add_control("nb_polyform_spread", "spread", controlspec.new(0, 1, "lin", 0, 0), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_spread", function(val) set_param('spread', val) end)

  params:add_control("nb_polyform_send_a", "send a", controlspec.new(0, 1, "lin", 0, 0), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_send_a", function(val) set_param('sendA', val) end)
  
  params:add_control("nb_polyform_send_b", "send b", controlspec.new(0, 1, "lin", 0, 0), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_send_b", function(val) set_param('sendB', val) end)

  params:add_separator("nb_polyform_osc", "oscillators")
  params:add_control("nb_polyform_mix", "mix [saw/pulse]", controlspec.new(-1, 1, "lin", 0, -0.6), function(param) return mix_display(param:get()) end)
  params:set_action("nb_polyform_mix", function(val) set_param('mix', val) end)

  params:add_control("nb_polyform_saw_tune", "saw tune", controlspec.new(-24, 24, "lin", 0, 0, "", 1/480), function(param) return (round_form(param:get(), 0.01, "st")) end)
  params:set_action("nb_polyform_saw_tune", function(val) set_param('saw_tune', val) end)

  params:add_control("nb_polyform_saw_shape", "saw shape", controlspec.new(0, 1, "lin", 0, 1), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_saw_shape", function(val) set_param('saw_shape', util.linlin(0, 1, 0.5, 1, val)) end)

  params:add_control("nb_polyform_pulse_tune", "pulse tune", controlspec.new(-24, 24, "lin", 0, 0, "", 1/480), function(param) return (round_form(param:get(), 0.01, "st")) end)
  params:set_action("nb_polyform_pulse_tune", function(val) set_param('pulse_tune', val) end)

  params:add_control("nb_polyform_pulse_width", "pulse width", controlspec.new(0.1, 0.9, "lin", 0, 0.5), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_pulse_width", function(val) set_param('pulse_width', val) end)

  params:add_separator("nb_polyform_filter", "lp filter")

  params:add_control("nb_polyform_cutoff_lpf", "cutoff", controlspec.new(20, 18000, "exp", 0, 1200), function(param) return round_form(param:get(), 1, " hz") end)
  params:set_action("nb_polyform_cutoff_lpf", function(val) set_param('cutoff_lpf', val) end)

  params:add_control("nb_polyform_res_lpf", "resonance", controlspec.new(0, 1, "lin", 0, 0.1), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_res_lpf", function(val) set_param('res_lpf', val) end)

  params:add_control("nb_polyform_env_lpf_depth", "env depth", controlspec.new(-1, 1, "lin", 0, 0.2), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_env_lpf_depth", function(val) set_param('env_lpf_depth', val) end)

  params:add_separator("nb_polyform_env", "envelope")

  params:add_control("nb_polyform_attack", "attack", controlspec.new(0.001, 10, "exp", 0, 0.001), function(param) return (round_form(param:get(),0.01," s")) end)
  params:set_action("nb_polyform_attack", function(val) set_param('attack', val) end)

  params:add_control("nb_polyform_decay", "decay", controlspec.new(0.01, 10, "exp", 0, 2.2), function(param) return (round_form(param:get(),0.01," s")) end)
  params:set_action("nb_polyform_decay", function(val) set_param('decay', val) end)

  params:add_control("nb_polyform_sustain", "sustain", controlspec.new(0, 1, "lin", 0, 0.5), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_sustain", function(val) set_param('sustain', val) end)

  params:add_control("nb_polyform_release", "release", controlspec.new(0.01, 10, "exp", 0, 2.2), function(param) return (round_form(param:get(), 0.01, " s")) end)
  params:set_action("nb_polyform_release", function(val) set_param('release', val) end)

  params:add_separator("nb_polyform_mod", "modulation")

  params:add_control("nb_polyform_mix_mod", "mix", controlspec.new(-1, 1, "lin", 0, 0), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_mix_mod", function(val) set_param('mix_mod', val) end)

  params:add_control("nb_polyform_cut_lpf_mod", "cutoff", controlspec.new(-1, 1, "lin", 0, 0), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_cut_lpf_mod", function(val) set_param('cut_lpf_mod', val) end)

  params:add_control("nb_polyform_saw_shape_mod", "saw shape", controlspec.new(-1, 1, "lin", 0, 0), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_saw_shape_mod", function(val) set_param('saw_shape_mod', val) end)

  params:add_control("nb_polyform_pulse_width_mod", "pulse width", controlspec.new(-1, 1, "lin", 0, 0), function(param) return round_form(param:get() * 100, 1, "%") end)
  params:set_action("nb_polyform_pulse_width_mod", function(val) set_param('pulse_width_mod', val) end)

end


---------------- nb player ----------------

function add_nb_polyform_player()
  local player = {
    alloc = vx.new(NUM_VOICES, 2),
    slot = {},
    clk = nil
  }

  function player:describe()
    return {
      name = "nb_polyform",
      supports_bend = false,
      supports_slew = false
    }
  end
  
  function player:active()
    if self.name ~= nil then
      if self.clk ~= nil then
        clock.cancel(self.clk)
      end
      self.clk = clock.run(function()
        clock.sleep(0.4)
        if not is_active then
          is_active = true
          params:lookup_param("nb_polyform_load_patch"):bang()
          params:show("nb_polyform_group")
          if md.is_loaded("fx") == false then
            params:hide("nb_polyform_send_a")
            params:hide("nb_polyform_send_b")
          end
          _menu.rebuild_params()
        end
      end)
    end
  end

  function player:inactive()
    if self.name ~= nil then
      if self.clk ~= nil then
        clock.cancel(self.clk)
      end
      self.clk = clock.run(function()
        clock.sleep(0.4)
        if is_active then
          is_active = false
          dont_panic()
          params:hide("nb_polyform_group")
          _menu.rebuild_params()
        end
      end)
    end
  end

  function player:stop_all()
    dont_panic()
  end

  function player:modulate(val)
    set_param('moddepth', val)
  end

  function player:set_slew(s)
  end

  function player:pitch_bend(note, amount)
  end

  function player:modulate_note(note, key, value)
  end

  function player:note_on(note, vel)
    local freq = mu.note_num_to_freq(note)
    local slot = self.slot[note]
    if slot == nil then
      slot = self.alloc:get()
      slot.count = 1
    end
    local voice = slot.id - 1 -- sc is zero indexed!
    slot.on_release = function()
      osc.send({ "localhost", 57120 }, "/nb_polyform/note_off", {voice})
    end
    self.slot[note] = slot
    osc.send({ "localhost", 57120 }, "/nb_polyform/note_on", {voice, freq, vel})
  end

  function player:note_off(note)
    local slot = self.slot[note]
    if slot ~= nil then
      self.alloc:release(slot)
    end
    self.slot[note] = nil
  end

  function player:add_params()
    add_nb_polyform_params()
  end

  if note_players == nil then
    note_players = {}
  end

  note_players["polyform"] = player
end


---------------- mod zone ----------------

local function post_system()
  if util.file_exists(preset_path) == false then
    util.make_dir(preset_path)
    os.execute('cp '.. '/home/we/dust/code/nb_polyform/data/polyform_patches/*.patch '.. preset_path)
  end
end

local function pre_init()
  init_nb_polyform()
  add_nb_polyform_player()
end

md.hook.register("system_post_startup", "nb_polyform post startup", post_system)
md.hook.register("script_pre_init", "nb_polyform pre init", pre_init)
