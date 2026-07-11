// Cache the final run values before credits eventually reset runtime.
credits_timer = 0;
credits_scroll_y = GAME_VIEW_HEIGHT - 112;
credits_line_height = 20;
credits_final_score = 0;
credits_ship_name = "Moon";

if (variable_global_exists("game_runtime")) {
    credits_final_score = global.game_runtime.score;
    credits_ship_name = GamePlayerShipDisplayNameGet(global.game_runtime.selected_ship_id);
}

credits_lines = [
    "Selkie's Moon",
    "~ until we meet again ~",
    "",
    "Final Score: " + string(credits_final_score),
    "Cleared By: " + credits_ship_name,
    "",
    "Created by Fenny",
    "AI collaboration and implementation support: OpenAI Codex",
    "",
    "Characters",
    "Moon - pilot of Sunset",
    "Selkie - pilot of Sunrise",
    "",
    "Game design additions",
    "Ten-stage run structure",
    "Selkie playable ship",
    "Stage variant enemies",
    "Power-up system",
    "CG Gallery and Music Room",
    "",
    "Tools and libraries",
    "GameMaker",
    "GameMaker Testing Library",
    "",
    "Assets",
    "Original project art, sound, and generated in-project shapes",
    "No additional third-party assets imported in this pass",
    "",
    "Thank you for playing"
];
