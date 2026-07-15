// True 3D is confined to Draw Begin. The matrices and depth state are restored
// before normal Draw and Draw GUI, so player, hitbox, bullets, effects, and UI
// remain crisp 2D elements above the scene.
GameStage3DRender(self, scene_state);
GameStage3DAtmosphereDraw(scene_state, stage3d_config);
