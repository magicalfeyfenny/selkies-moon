/// @func GameInputVerbStateCreate()
/// Creates the per-verb state container for one input action.
function GameInputVerbStateCreate() {
    return {
        down: false,
        pressed: false,
        released: false
    };
}

/// @func GameInputStateCreate()
/// Creates the global input state with all supported gameplay verbs.
function GameInputStateCreate() {
    return {
        device: "keyboard",
        gamepad_connected: false,
        gamepad_slot: -1,
        gamepad_deadzone: 0.25,
        move_x: 0,
        move_y: 0,
        verbs: {
            up: GameInputVerbStateCreate(),
            down: GameInputVerbStateCreate(),
            left: GameInputVerbStateCreate(),
            right: GameInputVerbStateCreate(),
            fire: GameInputVerbStateCreate(),
            autofire: GameInputVerbStateCreate(),
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

/// @func GameInputKeyboardSnapshotCreate()
/// Polls the complete keyboard mapping without mutating the shared input state.
function GameInputKeyboardSnapshotCreate() {
    var _snapshot = {
        up: keyboard_check(vk_up) == true,
        down: keyboard_check(vk_down) == true,
        left: keyboard_check(vk_left) == true,
        right: keyboard_check(vk_right) == true,
        fire: keyboard_check(ord("Z")) == true,
        autofire: keyboard_check(ord("C")) == true,
        bomb: keyboard_check(ord("X")) == true,
        pause: keyboard_check(vk_escape) == true || keyboard_check(ord("P")) == true,
        move_x: 0,
        move_y: 0,
        activity: false
    };

    _snapshot.move_x = (_snapshot.right ? 1 : 0) - (_snapshot.left ? 1 : 0);
    _snapshot.move_y = (_snapshot.down ? 1 : 0) - (_snapshot.up ? 1 : 0);
    _snapshot.activity = _snapshot.up || _snapshot.down || _snapshot.left || _snapshot.right
        || _snapshot.fire || _snapshot.autofire || _snapshot.bomb || _snapshot.pause;

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

    var _axis_x = gamepad_axis_value(_slot, gp_axislh);
    var _axis_y = gamepad_axis_value(_slot, gp_axislv);
    var _deadzone = _state.gamepad_deadzone;
    var _pad_up = gamepad_button_check(_slot, gp_padu) == true;
    var _pad_down = gamepad_button_check(_slot, gp_padd) == true;
    var _pad_left = gamepad_button_check(_slot, gp_padl) == true;
    var _pad_right = gamepad_button_check(_slot, gp_padr) == true;

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
    _snapshot.fire = gamepad_button_check(_slot, gp_face1) == true;
    _snapshot.autofire = gamepad_button_check(_slot, gp_face3) == true;
    _snapshot.bomb = gamepad_button_check(_slot, gp_face2) == true;
    _snapshot.pause = gamepad_button_check(_slot, gp_start) == true;
    _snapshot.move_x = (_pad_right ? 1 : 0) - (_pad_left ? 1 : 0);
    _snapshot.move_y = (_pad_down ? 1 : 0) - (_pad_up ? 1 : 0);

    if (!_pad_left && !_pad_right) {
        _snapshot.move_x = _axis_x;
    }
    if (!_pad_up && !_pad_down) {
        _snapshot.move_y = _axis_y;
    }

    _snapshot.activity = _snapshot.up || _snapshot.down || _snapshot.left || _snapshot.right
        || _snapshot.fire || _snapshot.autofire || _snapshot.bomb || _snapshot.pause;

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

/// @func GameInputUpdateKeyboard(state)
/// Refreshes verb states from the current keyboard mapping.
function GameInputUpdateKeyboard(_state) {
    var _keyboard = GameInputKeyboardSnapshotCreate();
    var _gamepad = GameInputGamepadSnapshotCreate(_state);
    _gamepad.up = false;
    _gamepad.down = false;
    _gamepad.left = false;
    _gamepad.right = false;
    _gamepad.fire = false;
    _gamepad.autofire = false;
    _gamepad.bomb = false;
    _gamepad.pause = false;
    _gamepad.activity = false;
    GameInputSnapshotApply(_state, _keyboard, _gamepad);
    _state.device = "keyboard";
    _state.move_x = _keyboard.move_x;
    _state.move_y = _keyboard.move_y;
}

/// @func GameInputUpdate(state)
/// Updates the active input device and polls its mapped verbs.
function GameInputUpdate(_state) {
    var _keyboard = GameInputKeyboardSnapshotCreate();
    var _gamepad = GameInputGamepadSnapshotCreate(_state);
    GameInputSnapshotApply(_state, _keyboard, _gamepad);
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

/// @func GameInputVerbReleased(verb)
/// Returns whether a named verb was released this frame.
function GameInputVerbReleased(_verb) {
    if (!variable_global_exists("game_input") || !struct_exists(global.game_input.verbs, _verb)) {
        return false;
    }

    return global.game_input.verbs[$ _verb].released;
}
