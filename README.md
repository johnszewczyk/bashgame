# Bash Tile Game

🌲🌲🌲🏠🏠🏠🌲🌲🌲🌲🌲<br>
🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲<br>
🌲🌳🌲🌲🌲🏃🏠🏠🌲🌳🌲<br>
🌲🌲🌲🌲🌲🏠🏠🏠🌲🌲🌳<br>
🌲🌲🌲🌲🔪🏠🏠🏠🌲🌲🌲<br>
🌳🌲🌲🌲🌲🏠🏠🏠🏠🏠🌲<br>
🌲🌲🌳🌳🌲🏠🏠🏠🏠🏠🏠<br>
🌾🌳🌲🌲🌲🌲🌳🏠🏠🏠🏠<br>

...is a text/ console game written in `Bash 5+`. A player-controlled cursor is pursued by an AI enemy across a
tile-based gameboard. Players make their way toward the exit tile while taking cover from the enemy on "safe" tiles.

### Features

<ul>
  <li>Emoji graphics</li>
  <li>Collision detection</li>
  <li>Scaleable game board size</li>
</ul>

### Tile Types

```bash
declare TILE_FIELD="🌾"  # empty tile
declare TILE_TREES="🌳"  # blocked tile
declare TILE_WOODS="🌲"  # empty tile
declare TILE_CABIN="🏠"  # safe tile
declare TILE_WATER="🌊"  # trap tile
declare TILE_WINNER="🚔" # exit tile
declare TILE_PLAYER="🏃" # player
declare TILE_ENEMY="🔪"  # enemy
```

<br><br>

## Map & Display

<br>

An indexed array of tiles is randomly generated. Players traverse the array logically, +1/ -1 to move horizontally and +(dimension)/ -(dimension) to move vertically across indices. For some calculatios, index/ position is converted to x,y via grid properties.

<br>

#### Dyamically-Named Variable Assignment in-Loop

```bash
# use eval to set dynamically-named variable
eval "$(printf "declare -A -g p%02d%02d[init]=\"%s\"" "$x" "$y" "$myrandom")"
```

`Printf` is used to maintain zero-padding for uniform coordinate pairs. Currenty, it should allow map sizes up to 90x90.

<br>

After tile generation, three functions to `find all tiles of a type` and `find adjacent tiles` and `replace tiles` are used to expand tile
areas beyond 1x1.

<br><br>

## Controls & Movement

<br>

```bash
# take input
read -rsn1 -t${GAMESPEED} keystroke
```

<br>

Player movement is modeled using keystrokes to increment a cursor across an array. The enemy cursor is able to move diagonally, to move each turn or each time the player moves, and to teleport in the event of becoming stuck on something. Further, the enemy cursor is unable to enter some tiles.

<br><br>

## Database & Framebuffer

<br>

```bash
# update player location in database
player_tile_id=$(printf "p%02d%02d" "$x" "$y") # locate tile in database
player_target_tile="${player_tile_id}[init]" # store tile init value in [init]
eval "${player_tile_id}[occp]=$TILE_PLAYER" # set tile val to player

# update player location in framebuffer
player_tile_xy=${player_tile_id:1} # get only the coordinates
player_index=${pixelDictonary[$player_tile_xy]} # get the index using coordinates
framebuffer[player_index]="$TILE_PLAYER" # update framebuffer
```

<br>

When the map is generated, a second array is created to use as a framebuffer (the 'pixel' data to draw). Referencing the
inital array, which serves as a database, is too slow to utilize as a framebuffer. The second array, which is updated
only incrementally, is drawn repeatedly. Finally, a third array describing the viewable area of the map (relative to the player) is used to choose which tiles are drawn.

<br><br>

## Future

- [ ] Game menu to launch or configure options
- [ ] Additional tile types; items, collectables, traps, etc.
- [ ] Multiple NPCs

## Historical Comments
A section to reflect on milestones

### Tile Database

Initially, a tile was an associative array, allowing many properties through keys and values. An array held the names of each tile for reference. The limitations of nested arrays in bash created a convoluted system to set or access tiles. Ultimately, the added complexity, though functional, resulted in the program becoming tedious to understand. Further, moving away from a padded coordinate system (via printf) to a positional/ indexed organiztaion not only simplified code, but immediately allowed game size to increase from ~90x90 to ~600x600 or more. Finally, moving to a single indexed array for all tiles massively reduced load times. 


