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

- [ ] Additional tile types; items, collectables, traps, etc.
- [ ] Save / Load tile maps; dedicated levels.

