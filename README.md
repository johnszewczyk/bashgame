# Bash Tile Game

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

<br>

## Map & Display

<br>

A square map of customisable size is generated randomly. Each tile is an array with keys [init] for initial tile value and [occp] to designate an occupation by a player, enemy, or item. `eval` is used to make associative arrays in-loop, with each name reflecting the tile's location on a coordinate plane.

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

Player movement is modeled using keystrokes to increment a cursor across an array. The enemy cursor is able to move diagonally, to move each turn **_and_** each time the player moves, and to teleport in the event of becoming stuck on something. Further, the enemy cursor is unable to enter some tiles by way of a movement approval method in `moveNPC`.

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

When the map is generated, a second array is created to use as a framebuffer (the 'pixel' data to draw). Referencing the
inital array, which serves as a database, is too slow to utilize as a framebuffer. The second array, which is updated
only incrementally, is drawn repeatedly. (More to come.)

<br>

## Future

- [ ] Game menu to launch or configure options
- [ ] Additional tile types; items, collectables, traps, etc.
- [ ] Scrolling map and scaleable viewport

