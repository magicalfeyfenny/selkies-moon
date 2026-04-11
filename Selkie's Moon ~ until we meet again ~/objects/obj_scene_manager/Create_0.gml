//This object is to manage global.game_runtime, control obj_camera, manage enemy appearance timelines, etc.
//It should initialize its state at the beginning of a run based on the runtime mode.
//It should have an associated timeline file, tml_stage, with moments corresponding with enemy appearances within the stage
//It should manage the playable field, centered by obj_camera, as a separate x/y coordinate axis from the background. 
// obj_camera should move slowly upward while shifting left or right to bounded limits if the player moves to the left or right