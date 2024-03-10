# Bash Tile Game

🌲🌲🌲🏠🏠🏠🌲🌲🌲🌲🌲<br>
🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲<br>
🌲🌳🌲🌲🌲🏃🏠🏠🌲🌳🌲<br>
🌲🌲🌲🌲🌲🏠🏠🏠🌲🌲🌳<br>
🌲🌲🌲🌲🔪🏠🏠🏠🌲🌲🌲<br>
🌳🌲🌲🌲🌲🚪🏠🏠🏠🏠🌲<br>
🌲🌲🌳🌳🌲🏠🏠🏠🏠🏠🏠<br>
🌾🌳🌲🐺🌲🌲🌳🏠🏠🏠🚪<br>

...is a text/ console game written in `Bash 5+`. A player-controlled cursor is pursued by AI enemies across a tile-based gameboard. Players make their way toward the exit tile while avoiding enemies on "safe" tiles. The goal of Bash Tile Game is to be a rudimentary yet modular, customisable, and understandable approach to basic computer game design.

**Features**
* Emoji Graphics
* Collision Detection
* Randomly Generated Maps

<br>

## Map & Display

A square game board of "tiles" (indexes of an array) is randomly generated. Additional functions modify the tile map after generation. A smaller viewable area is drawn each frame, scrolling with movement across the map. A map border prevents the player cursor from moving out of bounds, which causes wrap-around-type visual issues otherwise.

<br>
  
## Controls & Movement

Player movement is modeled using keystrokes to increment a cursor across an array. The main enemy cursor is able to move diagonally, to move each turn **_and_** each time the player moves, and to teleport in the event of becoming stuck on something. Further, the enemy cursor is unable to enter some tiles.

<br>

## Enemies & Obstacles

Enemies are spawned and managed in-loop, allowing for additions instantly. (Increasing the amount of AI-controlled units quickly reveals the limitations of BASH.)

<br>

## Future

- [ ] Game menu to launch or configure options
- [ ] Additional tile types; items, collectables, traps, etc.
- [ ] Scrolling map and scaleable viewport

## Thoughts
A section to reflect on milestones

### Tile Data
Previously, the game's map, an indexed array holding references to associative arrays for each tile, allowed for extensive tile attributes via the `-A` array's keys and values. This method was extremely slow, setting multiple variables/ values for each tile. Instead, indices of tiles with special attributes are held in an array and referenced when needed. Even same-tiles with different functionalities can be easily represented this way. Map creation logic is reduced significantly and much faster.

### Enemies
Previously, the game's enemies, single variables storing an occupied tile, required explicit creation and a convoluted system of `eval` to access. Now, all enemies are managed in-loop, allowing them to be spawned repeatedly. Game logic is significantly less abstract and more capable.

### Display
Previously, the game's map was drawn every "frame". The map size was thus limited by the terminal window size. Now, a "viewport" system is used to draw a small area of the map around the player allowing for map sizes well beyond 
