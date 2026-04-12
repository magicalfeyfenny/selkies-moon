// Create the local queue state used to display and advance story frames.
story_state = GameStoryStateCreate();

// Auto-start the room's default story file when one exists and nothing else is queued yet.
if (GameStoryRuntimeEnsure()) {
    var _default_story_file = GameStoryDefaultFileGet(room);

    if (_default_story_file != "" && global.game_runtime.story.requested_file == "" && global.game_runtime.story.current_file == "") {
        GameStoryQueueRequest(_default_story_file);
    }
}
