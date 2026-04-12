// Track whether this step closes the current room's story segment.
var _was_dialogue_active = global.game_runtime.signals.dialogue;

// Start queued stories and advance the current frame on dialogue input.
GameStoryUpdate(story_state);

// Move the opening cutscene forward into gameplay once its final frame is dismissed.
var _next_room = GameStoryTransitionRoomGet(room, _was_dialogue_active, global.game_runtime.signals.dialogue);
if (_next_room != -1) {
    room_goto(_next_room);
}
