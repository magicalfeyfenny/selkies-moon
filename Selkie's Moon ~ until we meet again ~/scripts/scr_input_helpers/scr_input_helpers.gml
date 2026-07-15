// Device polling and device-agnostic input verbs used by gameplay and menus.

/// @func GameInputVerbStateCreate()
/// Creates the per-verb state container for one input action.
function GameInputVerbStateCreate() {
    return {
        down: false,
        pressed: false,
        released: false
    };
}

/// @func GameInputVerbNamesCreate()
/// Returns the stable action order shared by polling, persistence, and remapping UI.
function GameInputVerbNamesCreate() {
    return ["up", "down", "left", "right", "fire", "autofire", "focus", "bomb", "pause"];
}

/// @func GameInputBindingsCreateDefault()
/// Creates independent keyboard and gamepad binding sets.
function GameInputBindingsCreateDefault() {
    return {
        keyboard: {
            up: [vk_up, ord("W")],
            down: [vk_down, ord("S")],
            left: [vk_left, ord("A")],
            right: [vk_right, ord("D")],
            fire: [ord("Z")],
            autofire: [ord("C")],
            focus: [vk_shift],
            bomb: [ord("X")],
            pause: [vk_escape, ord("P")],
        },
        gamepad: {
            up: gp_padu,
            down: gp_padd,
            left: gp_padl,
            right: gp_padr,
            fire: gp_face1,
            autofire: gp_face3,
            focus: gp_shoulderl,
            bomb: gp_face2,
            pause: gp_start,
        },
    };
}

/// @func GameInputKeyboardCodeSupported(code)
/// Limits stored keyboard bindings to keys that can be named clearly in the UI.
function GameInputKeyboardCodeSupported(_code) {
    if (!is_real(_code)) return false;
    _code = round(_code);

    if ((_code >= ord("A") && _code <= ord("Z"))
        || (_code >= ord("0") && _code <= ord("9"))) {
        return true;
    }

    var _special = [vk_left, vk_right, vk_up, vk_down, vk_enter, vk_escape,
        vk_space, vk_shift, vk_control, vk_alt, vk_tab, vk_home, vk_end,
        vk_delete, vk_insert, vk_pageup, vk_pagedown, vk_pause,
        vk_f1, vk_f2, vk_f3, vk_f4, vk_f5, vk_f6,
        vk_f7, vk_f8, vk_f9, vk_f10, vk_f11, vk_f12];

    for (var i = 0; i < array_length(_special); i++) {
        if (_code == _special[i]) return true;
    }

    return false;
}

/// @func GameInputGamepadCodesCreate()
/// Returns every digital controller button accepted by the remapper.
function GameInputGamepadCodesCreate() {
    return [gp_face1, gp_face2, gp_face3, gp_face4,
        gp_shoulderl, gp_shoulderr, gp_shoulderlb, gp_shoulderrb,
        gp_start, gp_select, gp_stickl, gp_stickr,
        gp_padu, gp_padd, gp_padl, gp_padr];
}

/// @func GameInputGamepadCodeSupported(code)
function GameInputGamepadCodeSupported(_code) {
    if (!is_real(_code)) return false;
    var _codes = GameInputGamepadCodesCreate();
    for (var i = 0; i < array_length(_codes); i++) {
        if (round(_code) == _codes[i]) return true;
    }
    return false;
}

/// @func GameInputKeyboardBindingNormalize(value, fallback)
/// Normalizes one keyboard action to a non-empty array of unique key codes.
function GameInputKeyboardBindingNormalize(_value, _fallback) {
    var _source = is_array(_value) ? _value : [_value];
    var _result = [];

    for (var i = 0; i < array_length(_source); i++) {
        var _code = _source[i];
        if (!GameInputKeyboardCodeSupported(_code)) continue;

        _code = round(_code);
        var _duplicate = false;
        for (var j = 0; j < array_length(_result); j++) {
            if (_result[j] == _code) {
                _duplicate = true;
                break;
            }
        }
        if (!_duplicate) array_push(_result, _code);
    }

    if (array_length(_result) <= 0) {
        return is_array(_fallback) ? _fallback : [_fallback];
    }
    return _result;
}

/// @func GameInputBindingsNormalize(source)
/// Carries valid per-device bindings forward and fills malformed fields.
function GameInputBindingsNormalize(_source) {
    var _result = GameInputBindingsCreateDefault();
    if (!is_struct(_source)) return _result;

    var _verbs = GameInputVerbNamesCreate();
    if (struct_exists(_source, "keyboard") && is_struct(_source.keyboard)) {
        for (var i = 0; i < array_length(_verbs); i++) {
            var _verb = _verbs[i];
            if (struct_exists(_source.keyboard, _verb)) {
                _result.keyboard[$ _verb] = GameInputKeyboardBindingNormalize(
                    _source.keyboard[$ _verb], _result.keyboard[$ _verb]);
            }
        }
    }

    if (struct_exists(_source, "gamepad") && is_struct(_source.gamepad)) {
        for (var i = 0; i < array_length(_verbs); i++) {
            var _verb = _verbs[i];
            if (struct_exists(_source.gamepad, _verb)
                && GameInputGamepadCodeSupported(_source.gamepad[$ _verb])) {
                _result.gamepad[$ _verb] = round(_source.gamepad[$ _verb]);
            }
        }
    }
    return _result;
}

/// @func GameInputBindingsIsValid(source)
function GameInputBindingsIsValid(_source) {
    if (!is_struct(_source)
        || !struct_exists(_source, "keyboard") || !is_struct(_source.keyboard)
        || !struct_exists(_source, "gamepad") || !is_struct(_source.gamepad)) {
        return false;
    }

    var _verbs = GameInputVerbNamesCreate();
    for (var i = 0; i < array_length(_verbs); i++) {
        var _verb = _verbs[i];
        if (!struct_exists(_source.keyboard, _verb)
            || !is_array(_source.keyboard[$ _verb])
            || array_length(_source.keyboard[$ _verb]) <= 0) return false;

        var _keys = _source.keyboard[$ _verb];
        for (var j = 0; j < array_length(_keys); j++) {
            if (!GameInputKeyboardCodeSupported(_keys[j])) return false;
        }

        if (!struct_exists(_source.gamepad, _verb)
            || !GameInputGamepadCodeSupported(_source.gamepad[$ _verb])) return false;
    }
    return true;
}

/// @func GameInputBindingsGet()
/// Reads live config bindings, falling back safely during early boot and tests.
function GameInputBindingsGet() {
    if (variable_global_exists("game_config")
        && is_struct(global.game_config)
        && struct_exists(global.game_config, "input_bindings")
        && GameInputBindingsIsValid(global.game_config.input_bindings)) {
        return global.game_config.input_bindings;
    }
    return GameInputBindingsCreateDefault();
}

/// @func GameInputKeyboardBindingDown(binding, typed)
function GameInputKeyboardBindingDown(_binding, _typed = "") {
    var _keys = is_array(_binding) ? _binding : [_binding];
    for (var i = 0; i < array_length(_keys); i++) {
        var _code = _keys[i];
        if (keyboard_check(_code) == true
            || (_typed != "" && ord(_typed) == _code)) return true;
    }
    return false;
}

/// @func GameInputKeyboardCodeName(code)
function GameInputKeyboardCodeName(_code) {
    _code = round(_code);
    if ((_code >= ord("A") && _code <= ord("Z"))
        || (_code >= ord("0") && _code <= ord("9"))) return chr(_code);

    switch (_code) {
        case vk_left: return "Left";
        case vk_right: return "Right";
        case vk_up: return "Up";
        case vk_down: return "Down";
        case vk_enter: return "Enter";
        case vk_escape: return "Esc";
        case vk_space: return "Space";
        case vk_shift: return "Shift";
        case vk_control: return "Ctrl";
        case vk_alt: return "Alt";
        case vk_tab: return "Tab";
        case vk_home: return "Home";
        case vk_end: return "End";
        case vk_delete: return "Delete";
        case vk_insert: return "Insert";
        case vk_pageup: return "Page Up";
        case vk_pagedown: return "Page Down";
        case vk_pause: return "Pause";
        case vk_f1: return "F1";
        case vk_f2: return "F2";
        case vk_f3: return "F3";
        case vk_f4: return "F4";
        case vk_f5: return "F5";
        case vk_f6: return "F6";
        case vk_f7: return "F7";
        case vk_f8: return "F8";
        case vk_f9: return "F9";
        case vk_f10: return "F10";
        case vk_f11: return "F11";
        case vk_f12: return "F12";
    }
    return "Key " + string(_code);
}

/// @func GameInputGamepadCodeName(code)
function GameInputGamepadCodeName(_code) {
    switch (round(_code)) {
        case gp_face1: return "A / Cross";
        case gp_face2: return "B / Circle";
        case gp_face3: return "X / Square";
        case gp_face4: return "Y / Triangle";
        case gp_shoulderl: return "LB / L1";
        case gp_shoulderr: return "RB / R1";
        case gp_shoulderlb: return "LT / L2";
        case gp_shoulderrb: return "RT / R2";
        case gp_start: return "Start";
        case gp_select: return "Select";
        case gp_stickl: return "Left Stick";
        case gp_stickr: return "Right Stick";
        case gp_padu: return "D-pad Up";
        case gp_padd: return "D-pad Down";
        case gp_padl: return "D-pad Left";
        case gp_padr: return "D-pad Right";
    }
    return "Button " + string(_code);
}

/// @func GameInputBindingLabel(device, verb)
function GameInputBindingLabel(_device, _verb) {
    var _bindings = GameInputBindingsGet();
    if (_device == "gamepad") {
        return GameInputGamepadCodeName(_bindings.gamepad[$ _verb]);
    }

    var _keys = _bindings.keyboard[$ _verb];
    var _label = "";
    for (var i = 0; i < array_length(_keys); i++) {
        if (i > 0) _label += " / ";
        _label += GameInputKeyboardCodeName(_keys[i]);
    }
    return _label;
}

/// @func GameInputActiveDeviceGet()
function GameInputActiveDeviceGet() {
    if (variable_global_exists("game_input")
        && global.game_input.gamepad_connected
        && global.game_input.device == "gamepad") return "gamepad";
    return "keyboard";
}

/// @func GameInputActiveBindingLabel(verb)
function GameInputActiveBindingLabel(_verb) {
    return GameInputBindingLabel(GameInputActiveDeviceGet(), _verb);
}

/// @func GameInputBindingAssign(device, verb, code)
/// Assigns one binding and resolves collisions by preserving or swapping the old key.
function GameInputBindingAssign(_device, _verb, _code) {
    if (!variable_global_exists("game_config")) return false;
    global.game_config.input_bindings = GameInputBindingsNormalize(
        struct_exists(global.game_config, "input_bindings")
            ? global.game_config.input_bindings : undefined);

    var _verbs = GameInputVerbNamesCreate();
    var _bindings = global.game_config.input_bindings;

    if (_device == "keyboard") {
        if (!GameInputKeyboardCodeSupported(_code)) return false;
        _code = round(_code);
        var _old_keys = _bindings.keyboard[$ _verb];
        var _old_code = _old_keys[0];

        for (var i = 0; i < array_length(_verbs); i++) {
            var _other = _verbs[i];
            if (_other == _verb) continue;
            var _other_keys = _bindings.keyboard[$ _other];
            var _kept = [];
            for (var j = 0; j < array_length(_other_keys); j++) {
                if (_other_keys[j] != _code) array_push(_kept, _other_keys[j]);
            }
            if (array_length(_kept) <= 0) array_push(_kept, _old_code);
            _bindings.keyboard[$ _other] = _kept;
        }
        _bindings.keyboard[$ _verb] = [_code];
        return true;
    }

    if (_device == "gamepad" && GameInputGamepadCodeSupported(_code)) {
        _code = round(_code);
        var _old_code = _bindings.gamepad[$ _verb];
        for (var i = 0; i < array_length(_verbs); i++) {
            var _other = _verbs[i];
            if (_other != _verb && _bindings.gamepad[$ _other] == _code) {
                _bindings.gamepad[$ _other] = _old_code;
            }
        }
        _bindings.gamepad[$ _verb] = _code;
        return true;
    }
    return false;
}

/// @func GameInputBindingsResetDevice(device)
function GameInputBindingsResetDevice(_device) {
    if (!variable_global_exists("game_config")) return false;
    var _defaults = GameInputBindingsCreateDefault();
    global.game_config.input_bindings = GameInputBindingsNormalize(
        struct_exists(global.game_config, "input_bindings")
            ? global.game_config.input_bindings : undefined);

    if (_device == "keyboard") {
        global.game_config.input_bindings.keyboard = _defaults.keyboard;
    } else if (_device == "gamepad") {
        global.game_config.input_bindings.gamepad = _defaults.gamepad;
    } else {
        return false;
    }
    return true;
}

/// @func GameInputStateCreate()
/// Creates the global input state with all supported gameplay verbs.
function GameInputStateCreate() {
    return {
        device: "keyboard",
        gamepad_connected: false,
        gamepad_slot: -1,
        gamepad_deadzone: 0.25,
        keyboard_last_char: "",
        move_x: 0,
        move_y: 0,
        verbs: {
            up: GameInputVerbStateCreate(),
            down: GameInputVerbStateCreate(),
            left: GameInputVerbStateCreate(),
            right: GameInputVerbStateCreate(),
            fire: GameInputVerbStateCreate(),
            autofire: GameInputVerbStateCreate(),
            focus: GameInputVerbStateCreate(),
            bomb: GameInputVerbStateCreate(),
            pause: GameInputVerbStateCreate()
        }
    };
}

/// @func GameInputVerbAssign(state, verb, down, pressed, released)
/// Stores the latest button state values for a named verb.
function GameInputVerbAssign(_state, _verb, _down, _pressed, _released) {
    var _verb_state = _state.verbs[$ _verb];

    _verb_state.down = _down;
    _verb_state.pressed = _pressed;
    _verb_state.released = _released;
}

/// @func GameInputVerbAssignFromDown(state, verb, down)
/// Updates transition flags from the combined keyboard/gamepad held state.
function GameInputVerbAssignFromDown(_state, _verb, _down) {
    var _was_down = _state.verbs[$ _verb].down;
    GameInputVerbAssign(_state, _verb, _down, _down && !_was_down, !_down && _was_down);
}

/// @func GameInputTextImpulseConsume(state, last_char)
/// Buffers a text-key tap that began and ended between two input polls.
function GameInputTextImpulseConsume(_state, _last_char) {
    var _char = string_upper(string(_last_char));

    if (_char == "" || _char == _state.keyboard_last_char) {
        return "";
    }

    _state.keyboard_last_char = _char;
    return _char;
}

/// @func GameInputKeyboardSnapshotCreate(state)
/// Polls held keys and consumes one sub-frame text-key impulse when available.
function GameInputKeyboardSnapshotCreate(_state = undefined) {
    var _typed = (_state == undefined)
        ? ""
        : GameInputTextImpulseConsume(_state, keyboard_lastchar);
    var _bindings = GameInputBindingsGet().keyboard;
    var _snapshot = {
        up: GameInputKeyboardBindingDown(_bindings.up, _typed),
        down: GameInputKeyboardBindingDown(_bindings.down, _typed),
        left: GameInputKeyboardBindingDown(_bindings.left, _typed),
        right: GameInputKeyboardBindingDown(_bindings.right, _typed),
        fire: GameInputKeyboardBindingDown(_bindings.fire, _typed),
        autofire: GameInputKeyboardBindingDown(_bindings.autofire, _typed),
        focus: GameInputKeyboardBindingDown(_bindings.focus, _typed),
        bomb: GameInputKeyboardBindingDown(_bindings.bomb, _typed),
        pause: GameInputKeyboardBindingDown(_bindings.pause, _typed),
        move_x: 0,
        move_y: 0,
        activity: false
    };

    _snapshot.move_x = (_snapshot.right ? 1 : 0) - (_snapshot.left ? 1 : 0);
    _snapshot.move_y = (_snapshot.down ? 1 : 0) - (_snapshot.up ? 1 : 0);
    _snapshot.activity = _snapshot.up || _snapshot.down || _snapshot.left || _snapshot.right
        || _snapshot.fire || _snapshot.autofire || _snapshot.focus
        || _snapshot.bomb || _snapshot.pause;

    return _snapshot;
}

/// @func GameInputGamepadSlotRefresh(state)
/// Keeps the first connected gamepad selected and handles hot-plug disconnects.
function GameInputGamepadSlotRefresh(_state) {
    var _slot = _state.gamepad_slot;

    if (_slot >= 0 && gamepad_is_connected(_slot)) {
        _state.gamepad_connected = true;
        return _slot;
    }

    _state.gamepad_connected = false;
    _state.gamepad_slot = -1;

    // Stay inside GMTL's eight-slot shim; desktop targets may expose a subset.
    for (var _candidate = 0; _candidate < 8; _candidate += 1) {
        if (gamepad_is_connected(_candidate)) {
            _state.gamepad_connected = true;
            _state.gamepad_slot = _candidate;
            gamepad_set_axis_deadzone(_candidate, _state.gamepad_deadzone);
            return _candidate;
        }
    }

    return -1;
}

/// @func GameInputGamepadSnapshotCreate(state)
/// Polls D-pad, left stick, face buttons, and Start for the selected controller.
function GameInputGamepadSnapshotCreate(_state) {
    var _snapshot = {
        up: false,
        down: false,
        left: false,
        right: false,
        fire: false,
        autofire: false,
        focus: false,
        bomb: false,
        pause: false,
        move_x: 0,
        move_y: 0,
        activity: false
    };
    var _slot = GameInputGamepadSlotRefresh(_state);

    if (_slot < 0) {
        return _snapshot;
    }

    var _bindings = GameInputBindingsGet().gamepad;
    var _axis_x = gamepad_axis_value(_slot, gp_axislh);
    var _axis_y = gamepad_axis_value(_slot, gp_axislv);
    var _deadzone = _state.gamepad_deadzone;
    var _pad_up = gamepad_button_check(_slot, _bindings.up) == true;
    var _pad_down = gamepad_button_check(_slot, _bindings.down) == true;
    var _pad_left = gamepad_button_check(_slot, _bindings.left) == true;
    var _pad_right = gamepad_button_check(_slot, _bindings.right) == true;

    if (abs(_axis_x) < _deadzone) {
        _axis_x = 0;
    }
    if (abs(_axis_y) < _deadzone) {
        _axis_y = 0;
    }

    _snapshot.left = _pad_left || _axis_x <= -_deadzone;
    _snapshot.right = _pad_right || _axis_x >= _deadzone;
    _snapshot.up = _pad_up || _axis_y <= -_deadzone;
    _snapshot.down = _pad_down || _axis_y >= _deadzone;
    _snapshot.fire = gamepad_button_check(_slot, _bindings.fire) == true;
    _snapshot.autofire = gamepad_button_check(_slot, _bindings.autofire) == true;
    _snapshot.focus = gamepad_button_check(_slot, _bindings.focus) == true;
    _snapshot.bomb = gamepad_button_check(_slot, _bindings.bomb) == true;
    _snapshot.pause = gamepad_button_check(_slot, _bindings.pause) == true;
    _snapshot.move_x = (_pad_right ? 1 : 0) - (_pad_left ? 1 : 0);
    _snapshot.move_y = (_pad_down ? 1 : 0) - (_pad_up ? 1 : 0);

    if (!_pad_left && !_pad_right) {
        _snapshot.move_x = _axis_x;
    }
    if (!_pad_up && !_pad_down) {
        _snapshot.move_y = _axis_y;
    }

    _snapshot.activity = _snapshot.up || _snapshot.down || _snapshot.left || _snapshot.right
        || _snapshot.fire || _snapshot.autofire || _snapshot.focus
        || _snapshot.bomb || _snapshot.pause;

    return _snapshot;
}

/// @func GameInputSnapshotApply(state, keyboard, gamepad)
/// Combines both devices so controller access does not require a settings change.
function GameInputSnapshotApply(_state, _keyboard, _gamepad) {
    GameInputVerbAssignFromDown(_state, "up", _keyboard.up || _gamepad.up);
    GameInputVerbAssignFromDown(_state, "down", _keyboard.down || _gamepad.down);
    GameInputVerbAssignFromDown(_state, "left", _keyboard.left || _gamepad.left);
    GameInputVerbAssignFromDown(_state, "right", _keyboard.right || _gamepad.right);
    GameInputVerbAssignFromDown(_state, "fire", _keyboard.fire || _gamepad.fire);
    GameInputVerbAssignFromDown(_state, "autofire", _keyboard.autofire || _gamepad.autofire);
    GameInputVerbAssignFromDown(_state, "focus", _keyboard.focus || _gamepad.focus);
    GameInputVerbAssignFromDown(_state, "bomb", _keyboard.bomb || _gamepad.bomb);
    GameInputVerbAssignFromDown(_state, "pause", _keyboard.pause || _gamepad.pause);

    if (_gamepad.activity) {
        _state.device = "gamepad";
        _state.move_x = _gamepad.move_x;
        _state.move_y = _gamepad.move_y;
    } else if (_keyboard.activity) {
        _state.device = "keyboard";
        _state.move_x = _keyboard.move_x;
        _state.move_y = _keyboard.move_y;
    } else if (_state.device == "gamepad" && _state.gamepad_connected) {
        // Preserve the last active device for prompts, but always consume the
        // neutral snapshot so a released stick cannot leave movement latched.
        _state.move_x = _gamepad.move_x;
        _state.move_y = _gamepad.move_y;
    } else {
        _state.device = "keyboard";
        _state.move_x = 0;
        _state.move_y = 0;
    }
}

/// @func GameInputUpdate(state)
/// Updates the active input device and polls its mapped verbs.
function GameInputUpdate(_state) {
    var _keyboard = GameInputKeyboardSnapshotCreate(_state);
    var _gamepad = GameInputGamepadSnapshotCreate(_state);
    GameInputSnapshotApply(_state, _keyboard, _gamepad);
}

/// @func GameMenuIndexWrap(index, delta, count)
/// Moves a menu cursor by one delta and wraps it inside the item count.
function GameMenuIndexWrap(_index, _delta, _count) {
    if (_count <= 0) {
        return 0;
    }

    return ((_index + _delta) mod _count + _count) mod _count;
}

/// @func GameMenuIndexStep(index, negative_pressed, positive_pressed, count)
/// Applies one pair of directional menu inputs to a wrapping cursor.
function GameMenuIndexStep(_index, _negative_pressed, _positive_pressed, _count) {
    var _delta = (_positive_pressed ? 1 : 0) - (_negative_pressed ? 1 : 0);
    return GameMenuIndexWrap(_index, _delta, _count);
}

/// @func GameInputVerbDown(verb)
/// Returns whether a named verb is currently held down.
function GameInputVerbDown(_verb) {
    if (!variable_global_exists("game_input") || !struct_exists(global.game_input.verbs, _verb)) {
        return false;
    }

    return global.game_input.verbs[$ _verb].down;
}

/// @func GameInputVerbPressed(verb)
/// Returns whether a named verb was pressed this frame.
function GameInputVerbPressed(_verb) {
    if (!variable_global_exists("game_input") || !struct_exists(global.game_input.verbs, _verb)) {
        return false;
    }

    return global.game_input.verbs[$ _verb].pressed;
}
