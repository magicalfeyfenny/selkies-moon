suite(function() {
    section("Game setup", function() {
        test("Default config keeps the playfield at 640x360", function() {
            var _config = GameConfigCreateDefault();

            expect(_config.room_width).toBe(640);
            expect(_config.room_height).toBe(360);
            expect(_config.target_fps).toBe(60);
        });

        test("Default save data starts clean", function() {
            var _save = GameSaveDataCreateDefault();

            expect(_save.high_score).toBe(0);
            expect(_save.runs_started).toBe(0);
            expect(_save.options.display_scale).toBe(2);
            expect(_save.options.fullscreen).toBeFalsy();
        });
    });
});
