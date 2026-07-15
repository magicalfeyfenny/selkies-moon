// Initialize the local state that drives firing, invulnerability, and continue flow.
player_state = GamePlayerStateCreate();
GamePlayerRespawnStateApply(player_state);
sprite_index = GamePlayerShipSpriteGet(GameRunShipIdGet());
// The ship and its 2x2 hitbox always render above enemy bullets; decorative
// weapon, bomb, and destruction effects live in Draw Begin behind them.
depth = -300;
