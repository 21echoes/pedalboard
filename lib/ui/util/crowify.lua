--- Crowify class.
-- Create a new instance to support a Crow device
--
-- @classmod Crowify
-- @release v0.1.0
-- @author @21echoes (https://github.com/21echoes)
-- Based on Arcify by @Mimetaur

local tabutil = require "tabutil"
local ControlSpec = require "controlspec"

local Crowify = {}
Crowify.__index = Crowify

-- constants
local NUM_INPUTS = 2
local MIN_VOLTS = -5
local MAX_VOLTS = 10
local MIN_SEPARATION = 0.01
local NO_ASSIGMENT = "none"
local SHIFT_KEYS = {"none", "key 2", "key 3"}
local SHIFT_MODE = {"toggle", "hold"}


------------------
-- private methods
-------------------

local function default_input_mapping()
    return {nil, nil}
end

--- Params as options.
-- Builds an array of registered params starting with "none"
local function params_as_options(self)
    local param_names = {}
    table.insert(param_names, NO_ASSIGMENT)

    -- local sorted_params = tab.sort(self.params_order_)
    for idx, param_name in ipairs(self.params_order_) do
        table.insert(param_names, param_name)
    end

    return param_names
end

local function param_id_for_input(input_num, is_shift)
    local offset = 0
    if is_shift then
        offset = NUM_INPUTS
    end
    return "crow_input_" .. input_num + offset .. "_mapping"
end

local function map_input(self, position, param_id, is_shift)
    if position < 1 or position > NUM_INPUTS then
        print("Invalid crow input number: " .. position)
        return
    end
    if param_id == NO_ASSIGMENT or param_id == nil then
        param_id = nil
    elseif not params:lookup_param(param_id) then
        print("Invalid parameter name: " .. param_id .. "at" .. position)
        return
    end
    if is_shift then
        self.shift_inputs_[position] = param_id
    else
        self.inputs_[position] = param_id
    end
end

local function build_input_mapping_param(self, input_num, is_shift, opts)
    local param_id = param_id_for_input(input_num, is_shift)
    local name = "Crow Input #" .. input_num
    if is_shift then
        name = "[shift] Crow Input #" .. input_num
    end

    params:add {
        type = "option",
        id = param_id,
        name = name,
        options = opts,
        default = 1,
        action = function(value)
            local opt_name = opts[value]
            if opt_name == NO_ASSIGMENT then
                self:clear_input_mapping(input_num, is_shift)
            else
                map_input(self, input_num, opt_name, is_shift)
            end
        end
    }
end

local function query_input(self, position)
    crow.input[position].stream = function(v)
        local is_shift = self.is_shifted_
        local param_id = self:param_id_at_input(position, is_shift)
        local param = param_id and params:lookup_param(param_id) or nil
        if param_id and param then
            local param_type = param.t
            if param_type == params.tCONTROL or param_type == params.tTAPER or param_type == params.tNUMBER or param_type == params.tOPTION then
                local input_min = params:get("min_volts_"..position)
                local input_max = params:get("max_volts_"..position)
                local value = util.clamp(v, input_min, input_max)
                local output_min = param.min
                local output_max = param.max
                if param_type == params.tCONTROL then
                    output_min = param.controlspec.minval
                    output_max = param.controlspec.maxval
                elseif param_type == params.tOPTION then
                    output_min = 1
                    output_max = param.count
                end
                if param_type == params.tCONTROL or param_type == params.tTAPER then
                    value = util.linlin(input_min, input_max, 0, 1, value)
                    params:set_raw(param_id, value)
                elseif param_type == params.tNUMBER or param_type == params.tOPTION then
                    value = util.linlin(input_min, input_max, output_min, output_max, value)
                    value = util.round(value)
                    params:set(param_id, value)
                end
            elseif param_type == params.tBINARY or param_type == params.tTRIGGER then
                local gate_threshold = params:get("gate_threshold_"..i)
                local cleared_threshold = v > gate_threshold
                if param_type == params.tBINARY then
                    params:delta(param_id, cleared_threshold and 1 or 0)
                else
                    if self.trigger_state_[position] ~= cleared_threshold then
                        if cleared_threshold then params:bang() end
                        self.trigger_state_[position] = cleared_threshold
                    end
                end
            end
        end
    end
end

-------------------
-- Public interface
-------------------

--- Create a new Crowify object.
-- @int sample_rate By default, 25 Hz (optional)
-- @treturn Crowify Instance of Crowify.
function Crowify.new(sample_rate)
    local self = {}
    self.params_order_ = {}
    self.inputs_ = default_input_mapping()
    self.shift_inputs_ = default_input_mapping()
    self.is_shifted_ = false
    self.sample_rate_ = sample_rate or (1 / 25)
    self.trigger_state_ = {false, false}

    for position=1,NUM_INPUTS do
        crow.input[position].mode("stream", self.sample_rate_)
        query_input(self, position)
    end

    setmetatable(self, Crowify)
    return self
end

--- Add Crowify assignment params to the Norns PARAMS screen.
local NUM_PARAMS_PER_INPUT = 4
function Crowify:add_params(allow_shift)
    local base_num_params = (NUM_INPUTS*NUM_PARAMS_PER_INPUT)
    params:add_group("Crow", allow_shift and (base_num_params + 4 + NUM_INPUTS) or base_num_params)
    self.opts_ = params_as_options(self)
    for i = 1, NUM_INPUTS do
        build_input_mapping_param(self, i, false, self.opts_)
    end
    for i = 1, NUM_INPUTS do
        params:add_control("min_volts_"..i, "Input "..i..": Min Volts", ControlSpec.new(MIN_VOLTS, MAX_VOLTS, "lin", MIN_SEPARATION, MIN_VOLTS, 'V'))
        params:set_action("min_volts_"..i, function(value)
            if params:get("max_volts_"..i) < value + MIN_SEPARATION then
                params:set("max_volts_"..i, value + MIN_SEPARATION)
            end
        end)
        params:add_control("max_volts_"..i, "Input "..i..": Max Volts", ControlSpec.new(MIN_VOLTS, MAX_VOLTS, "lin", MIN_SEPARATION, 5, 'V'))
        params:set_action("max_volts_"..i, function(value)
            if params:get("min_volts_"..i) > value - MIN_SEPARATION then
                params:set("min_volts_"..i, value - MIN_SEPARATION)
            end
        end)
        params:add_control("gate_threshold_"..i, "Input "..i..": Gate Threshold", ControlSpec.new(MIN_VOLTS, MAX_VOLTS, "lin", MIN_SEPARATION, 1, 'V'))
    end

    if allow_shift then
        params:add_separator()
        params:add {
            type = "option",
            id = "crowify_shift_key",
            name = "shift key",
            options = SHIFT_KEYS,
            default = 1
        }
        params:add {
            type = "option",
            id = "crowify_shift_mode",
            name = "shift mode",
            options = SHIFT_MODE,
            default = 1
        }
        params:add_separator()
        for i = 1, NUM_INPUTS do
            build_input_mapping_param(self, i, true, self.opts_)
        end
    end
end

--- Register a param to be available to Crowify.
-- @string param_id ID of param
function Crowify:register(param_id)
    if not param_id then
        print("Param is missing a name. Not registered.")
        return
    end

    local p = params:lookup_param(param_id)
    if not p then
        print("Referencing invalid param. Not registered.")
        return
    end
    if p.t == paramset.tSEPARATOR or p.t == paramset.tFILE or p.t == paramset.tGROUP or p.t == paramset.tTEXT then
        print("Referencing invalid param. Unsupported param type. Not registered.")
        return
    end

    table.insert(self.params_order_, param_id)
    return true
end

--- Map an input to a param, using params:set
-- @int position which input to map
-- @string param_id which param ID to map it to
-- @bool is_shift if mapping an input in shift mode
function Crowify:map_input(position, param_id, is_shift)
    if position < 1 or position > NUM_INPUTS then
        print("Invalid crow input number: " .. position)
        return
    end
    if param_id == NO_ASSIGMENT or param_id == nil then
        param_id = nil
    elseif not params:lookup_param(param_id) then
        print("Invalid parameter name: " .. param_id .. "at" .. position)
        return
    end
    local param_mapping_id = param_id_for_input(position, is_shift)
    local option_num = tabutil.key(self.opts_, param_id)
    if option_num == nil then
        print("Invalid parameter name: " .. param_id .. "at" .. position)
        return
    end
    params:set(param_mapping_id, option_num)
end

--- Clear an input mapping.
-- @int position which input to clear
-- @bool is_shift if mapping an input in shift mode
function Crowify:clear_input_mapping(position, is_shift)
    if position < 1 or position > NUM_INPUTS then
        print("Invalid crow input number: " .. position)
        return
    end
    if is_shift then
        self.shift_inputs_[position] = nil
    else
        self.inputs_[position] = nil
    end
end

--- Clear all input mappings
function Crowify:clear_all_input_mappings()
    self.inputs_ = default_input_mapping()
end

--- Get the param ID value for a particular input.
-- @int position which crow input to get Param ID for
-- @bool is_shift if mapping an input in shift mode
function Crowify:param_id_at_input(position, is_shift)
    if is_shift then
        return self.shift_inputs_[position]
    end
    return self.inputs_[position]
end

--- Get the param Name value for a particular input.
-- @int position which crow input to get Param Name for
-- @bool is_shift if mapping an input in shift mode
function Crowify:param_name_at_input(position, is_shift)
    local param_id = self:param_id_at_input(position, is_shift)
    if not param_id then return nil end
    local param = params:lookup_param(param_id)
    if param then return nil end
    return param.name
end

--- Call this from inside the key() function
-- @int key_pressed is which key was pressed
-- @int key_state is whether it is up or down
function Crowify:handle_shift(key_pressed, key_state)
    local key_num = params:get("crowify_shift_key")
    local key_mode = SHIFT_MODE[params:get("crowify_shift_mode")]

    if not key_num or key_num == 1 then
        return
    end

    if key_num == key_pressed then
        if key_mode == "toggle" and key_state == 1 then
            self.is_shifted_ = not self.is_shifted_
        end

        if key_mode == "hold" and key_state == 1 then
            self.is_shifted_ = true
        end

        if key_mode == "hold" and key_state == 0 then
            self.is_shifted_ = false
        end
    end
end

return Crowify
