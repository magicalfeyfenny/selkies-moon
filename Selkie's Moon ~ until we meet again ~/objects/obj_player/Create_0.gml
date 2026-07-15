// Initialize the local state that drives firing, invulnerability, and continue flow.
player_state = GamePlayerStateCreate();
GamePlayerRespawnStateApply(player_state);
sprite_index = GamePlayerShipSpriteGet(GameRunShipIdGet());
// Normal Draw places the ship beneath enemy bullets. Draw End separately
// restores the 2x2 hitbox above every bullet for precise dodging.
depth = -100;
