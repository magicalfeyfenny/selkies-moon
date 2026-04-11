//This object should handle displaying short text-based cutscenes.
//It should only display UI elements or capture input while global.game_runtime.signals.dialogue is true
//It should produce a semi-transparent black text box positioned near the bottom of the visible area
//It should load a queue of text from a JSON file containing the text
//The JSON file should have an array of text frames, and each text frame should be a struct with 4 fields: "name", "text", "portraits", and "positions"
//When starting a story segment, set global.game_runtime.signals.dialogue to true, then dequeue and display the first text frame
//On a "fire", "autofire", or "bomb" verb from obj_input_manager, the next text frame should be displayed
//If the queue is empty when it is attempting to be dequeued, instead set global.game_runtime.signals.dialogue to false