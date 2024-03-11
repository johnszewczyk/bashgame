# Basic Game

This document introduces basic elements of _BASHGAME_ for new or curious users. The file "1-game_parts.sh" is BASHGAME at a most basic form. If nothing else, let this be a guide for brainstorming game ideas within BASH.

## init

Initializes global variables:  
- $keystroke: Stores the last pressed key.
- $p_index: Current position of the player's cursor in the game map array.
- $old_index: Previous position of the cursor.
- $gamesize: The width and height of the square game map.
- $game_map: An array representing the game map's tiles.
- $TILE1: Represents an empty tile (🌲).
- $TILE2: Represents the player's cursor (🏃).

## drawScreen

- Clears the terminal screen.
- Iterates through the game_map array, printing each tile and inserting line breaks to create the grid layout.
- Prints additional information: the player's current index and the total number of tiles.

## takeInput

- Saves the current player position in old_index.
- Prompts the user to use WASD for movement and Q to quit.
- Reads a single keystroke with a timeout (-t1).
- Uses a case statement to adjust p_index based on the key pressed, ensuring the player stays within the map boundaries.


## updateScreen

Function to update the framebuffer before next draw.

- Replaces the tile at the previous position (old_index) with the empty tile (TILE1).
- Replaces the tile at the current position (p_index) with the player cursor tile (TILE2).

## makeGame

- Fills the game_map array with empty tiles (TILE1) to create the initial map layout.

## startGame

The main game loop:

- Continues until the player presses 'q'.
- Calls updateScreen to visually reflect changes.
- Calls drawScreen to display the updated map.
- Calls takeInput to get player input.
- After the loop ends, prints "GAME OVER" and pauses briefly.
