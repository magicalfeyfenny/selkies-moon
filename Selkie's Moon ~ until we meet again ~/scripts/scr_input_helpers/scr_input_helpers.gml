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
        verbs: {
            up: GameInputVerbStateCreate(),
            down: GameInputVerbStateCreate(),
            left: GameInputVerbStateCreate(),
            right: GameInputVerbStateCreate(),
            fire: GameInputVerbStateCreate(),
            autofire: GameInputVerbStateCreate(),
            bomb: GameInputVerbStateCreate()
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

/// @func GameInputUpdateKeyboard(state)
/// Refreshes verb states from the current keyboard mapping.
function GameInputUpdateKeyboard(_state) {
    GameInputVerbAssign(_state, "up",
        keyboard_check(vk_up), keyboard_check_pressed(vk_up), keyboard_check_released(vk_up));
    GameInputVerbAssign(_state, "down",
        keyboard_check(vk_down), keyboard_check_pressed(vk_down), keyboard_check_released(vk_down));
    GameInputVerbAssign(_state, "left",
        keyboard_check(vk_left), keyboard_check_pressed(vk_left), keyboard_check_released(vk_left));
    GameInputVerbAssign(_state, "right",
        keyboard_check(vk_right), keyboard_check_pressed(vk_right), keyboard_check_released(vk_right));
    GameInputVerbAssign(_state, "fire",
        keyboard_check(ord("Z")), keyboard_check_pressed(ord("Z")), keyboard_check_released(ord("Z")));
    GameInputVerbAssign(_state, "autofire",
        keyboard_check(ord("C")), keyboard_check_pressed(ord("C")), keyboard_check_released(ord("C")));
    GameInputVerbAssign(_state, "bomb",
        keyboard_check(ord("X")), keyboard_check_pressed(ord("X")), keyboard_check_released(ord("X")));
}

/// @func GameInputUpdate(state)
/// Updates the active input device and polls its mapped verbs.
function GameInputUpdate(_state) {
    _state.device = global.game_config.input_device;

    switch (_state.device) {
        default:
        case "keyboard":
            GameInputUpdateKeyboard(_state);
            break;
    }
}

/// @func GameInputVerbDown(verb)
/// Returns whether a named verb is currently held down.
function GameInputVerbDown(_verb) {
    if (!variable_global_exists("game_input")) {
        return false;
    }

    return global.game_input.verbs[$ _verb].down;
}

/// @func GameInputVerbPressed(verb)
/// Returns whether a named verb was pressed this frame.
function GameInputVerbPressed(_verb) {
    if (!variable_global_exists("game_input")) {
        return false;
    }

    return global.game_input.verbs[$ _verb].pressed;
}

/// @func GameInputVerbReleased(verb)
/// Returns whether a named verb was released this frame.
function GameInputVerbReleased(_verb) {
    if (!variable_global_exists("game_input")) {
        return false;
    }

    return global.game_input.verbs[$ _verb].released;
}
