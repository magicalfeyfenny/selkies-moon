//This object should draw a menu that can be navigated using the verbs "up", "down", "left", "right", "shoot", and "bomb" from obj_input_manager. 
//Before the menu, there should be a title screen that has a game logo texture (a blank, brightly-colored sprite for now) and draws text that says "Press [FIRE] to start". 
//The menu should have 4 options: Start Game, Options, Scores, and Quit
//Scores should go to a submenu that shows the top 10 scores for each character retreived from global.game_save. Pressing "left" or "right" should change the character selected, but only 1 character should be available right now. Going back from this submenu should go back to the main menu.
//Options should go to a submenu that shows game settings from global.game_config. Going back from this submenu should go back to the main menu.
//Start Game should go to a character select submenu that shows a player character portrait, the player ship sprite firing its shot type, and a description of the ship.
//There should only be one character to select right now but the character select submenu should be built in a way that makes it possible to add more.
//The character selected should be recorded in the global.game_runtime, and then the room should transition to rm_opening.
//Quit ends the game 