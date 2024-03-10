# Bash Tile Game

🌲🌲🌲🏠🏠🏠🌲🌲🌲🌲🌲<br>
🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲🌲<br>
🌲🌳🌲🌲🌲🏃🏠🏠🌲🌳🌲<br>
🌲🌲🌲🌲🌲🏠🏠🏠🌲🌲🌳<br>
🌲🌲🌲🌲🔪🏠🏠🏠🌲🌲🌲<br>
🌳🌲🌲🌲🌲🏠🏠🏠🏠🏠🌲<br>
🌲🌲🌳🌳🌲🏠🏠🏠🏠🏠🏠<br>
🌾🌳🌲🌲🌲🌲🌳🏠🏠🏠🏠<br>

...is a text/ console game written in `Bash 5+`. A player-controlled cursor is pursued by AI enemies across a tile-based gameboard. Players make their way toward the exit tile while taking cover from the enemy on "safe" tiles.

**Features**

* Emoji Graphics
* Collision Detection
* Randomly Generated Maps

<br>

## Map & Display

<br>

A square game board of "tiles" (indexes of an array) is randomly generated. Additional functions modify the tile map after generation.

<br>

**Dyamically-Named Variable Assignment in-Loop**

```bash
# use eval to set dynamically-named variable
eval "$(printf "declare -A -g p%02d%02d[init]=\"%s\"" "$x" "$y" "$myrandom")"
```

`Printf` is used to maintain zero-padding for uniform coordinate pairs. Currenty, it should allow map sizes up to 90x90.

<br>

After tile generation, three functions to `find all tiles of a type` and `find adjacent tiles` and `replace tiles` are used to expand tile
areas beyond 1x1.

<br>

## Controls & Movement

<br>

```bash
# wait for any input key
read -rsn1 -t${GAMESPEED} keystroke

[[ $keystroke == "w" ]] && ((y = y + 1)) # directional movement north
[[ $keystroke == "a" ]] && ((x = x - 1)) # directional movement west
[[ $keystroke == "s" ]] && ((y = y - 1)) # directional movement south
[[ $keystroke == "d" ]] && ((x = x + 1)) # directional movement east
```

<br>

Player movement is modeled using keystrokes to increment a cursor across an array. The enemy cursor is able to move diagonally, to move each turn **_and_** each time the player moves, and to teleport in the event of becoming stuck on something. Further, the enemy cursor is unable to enter some tiles.

<br>

## Enemies & Obstacles

<br>

Enemies are spawned and managed in-loop, allowing for additions instantly. (Increasing the amount of AI-controlled units quickly reveals the limitations of BASH.)

<br>

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

When the map is generated, a second array is created to use as a framebuffer (the 'pixel' data to draw). Referencing the inital array, which serves as a database, is too slow to utilize as a framebuffer. The second array, which is updated only incrementally, is drawn repeatedly. (More to come.)

<br>

## Future

- [ ] Game menu to launch or configure options
- [ ] Additional tile types; items, collectables, traps, etc.
- [ ] Scrolling map and scaleable viewport

# Thoughts


### Tile Data
Previously, the game's map, an indexed array holding references to associative arrays for each tile, allowed for extensive tile attributes via the `-A` array's keys and values. This method was extremely slow, setting multiple variables/ values for each tile. Instead, indices of tiles with special attributes are held in an array and referenced when needed. Even same-tiles with different functionalities can be easily represented this way. Map creation logic is reduced significantly and much faster.

### Enemies
Previously, the game's enemies, single variables storing an occupied tile, required explicit creation and a convoluted system of `eval` to access. Now, all enemies are managed in-loop, allowing them to be spawned repeatedly. Game logic is significantly less abstract and more capable.

### Display
Previously, the game's map was drawn every "frame". The map size was thus limited by the terminal window size. Now, a "viewport" system is used to draw a small area of the map around the player allowing for map sizes well beyond 
