//This object is the player's ship
//It should move with "up", "down", "right", and "left" inputs at a speed of 4px per frame
//It should be constrained to a playable area that the width of the visible area (a 202x360 area centered around obj_camera)
//When it gets near the edge of the visible area, it should drag obj_camera along with it to the edge of a 100-radius square about its home position. This will create the playable width
//obj_camera should scroll slowly forward, and this should cause the playable and visible 360 height to move forward with it, and the player's ship to move forward with it as well
//It should have a 64x64 sprite, with a 2x2 collision mask used as the hitbox in the center.
//When "shot" is pressed, a volley of 6 shots should be queued. each time it is pressed, the volley should reset to 6.
//this shot volley should dequeue once per 3 frames, and when it dequeues, 12 instances of obj_player_shot should be created in front of the player; they should fire in pairs from 6 positions; 2 from the player's side and 4 from the player's front. 
//the 2 pairs on the player's side should be traveling at directions 100 and 80, the 4 in front of the player should be traveling at direction 90
//all shots should travel at speed 10, but this should be a #macro SHOT_SPEED 13 at the top of the helper script
//within each pair, the shots should be 5 px apart side-to-side
//when "autofire" is pressed or held, the "shot" volley queue should be filled
//when shot is held, if it's been more than 1 second, instead a sword should be swung. this sword is a line of 128 px from the player's center out 315 degrees. #macro SWEEP_RATE 2 swings occur each second. this line sweeps around in an arc clockwise to 45 degrees, then sweeps back with each swing. 
//this line sweep should stay in place for sweep_time * .25 on each end point, and spend sweep_time * .25 performing the swing, with a cosine bias towards the endpoints. sweep_time = 1 / SWEEP_RATE
//when the line sweep is moving, any obj_bullet_parent between in it and its prior position should be tagged as cancelled
//when an obj_bullet_parent is cancelled, it should destroy itself and produce an obj_medal
//when an obj_medal is present, it moves towards the player at speed 7
//when an obj_medal collides with the player, the obj_medal is destroyed and adds #macro CANCEL_BONUS 100 points to global.game_runtime.score and adds #macro CANCEL_METER 1 to global.game_runtime.meter
//when global.game_runtime.meter reaches 1000, it should enter "berserk" mode, cancel all bullets on the screen at the very first frame of berserk, then drain at 1 per frame, make the sword 1.5x longer, halve sweep_time, no longer gain global.game_runtime.meter from cancelling bullets, and gain 10x the score from cancelling bullets. 
//during "berserk", the "fire" input should be considered as being held. when meter reaches 0 in "berserk", berserk is cleared, all bullets on the screen should be cancelled, and all states changed by berserk return to normal. 
//when the player collides with an obj_bullet_parent, the player should be tagged as "hit"
//when hit, the player plays a death animation, loses 1 life and then if they have lives remaining they respawn at the bottom of the screen.
//when initially spawning or respawning, the player should be invulnerable for #macro INVULN_TIME 300 frames. the player should be able to move during this time. if any bullets collide with the player during this time, the bullet is destroyed without being cancelled.
//if the player has no lives, a "continue_request" signal is placed in global.game_runtime.signals. while this signal is true, only menu inputs are allowed and all objects freeze in place. a Continue? menu appears over the playable area that has "Yes" and "No as options, and should respond to "up", "down", and "fire". 
//if the player enters yes, continues_used should be incremented, the player's lives and bombs should be reset, and the player should respawn.
//if the player enters no, the game should display "game over" and should return to the menu, recording the high score in the same way that moving to rm_ending does.
