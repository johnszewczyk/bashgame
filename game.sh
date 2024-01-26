#!/bin/bash

# Tile-based game uses array to store a grid formation.
# Array is used for database of tiles; cells hold listvar name for tile data
# Another array is used as a framebuffer, as referencing every tile is too slow

# FONT COLORS
RED='\033[0;31m' # red
OFF='\033[0m'    # off

declare dbug=on # dbug switch
tput civis      # turn off cursor display

# GLOBAL
declare -i npc_x=10       # badguy starting coordinates X
declare -i npc_y=10       # badguy starting coordinates Y
declare -a framebuffer=() # where active display "pixels" are stored
declare -g movepath

# GRAPHIC OPTIONS LOL
declare -i RESOLUTION=20 # game screen size
declare -i GAMESPEED=2   # think seconds-per-frame, rather
declare TILE_TREE="🌳"    # a tree
declare TILE_WOOD="🌲"    # an empty tile
declare TILE_CABIN="🏠"   # a cabin
declare TILE_WINNER="🚔"  # an exit
declare TILE_PLAYER="🏃"  # a player
declare TILE_ENEMY="🔪"   # an enemy

function makeDictionary() {
  [[ $dbug == on ]] && echo "DEBUG: making dict"

  # create pixel–coordinate dictionary to access arrays by values of keys
  local -i i                      # for loop counter
  local x=0                       # for increment
  local y=$RESOLUTION             # for new row
  declare -A -g pixelDictonary=() # dict array for coord-pixel relationship

  for ((i = 0; i < (RESOLUTION * RESOLUTION); i++)); do
    ((x++))                                             # increment column
    pixelDictonary[$(printf "%02d%02d" "$x" "$y")]="$i" # store data
    [[ $x == "$RESOLUTION" ]] && x=0 && ((y += -1))     # start a new row
  done
}

################################################################################
# MAP GENERATION
################################################################################

function makeCamp() {
  # Function to create array of tiles, randomly, to a square
  # RESOLUTION of ARG1; e.g., 10 = 10x10 = 100 items in output array.

  # notificatoin
  [[ $dbug == on ]] && echo "DEBUG: making camp"

  declare myrandom  # var to hold generated tile content
  declare -i i=0    # var for loop
  declare -i x=0    # var for dynamic name
  declare -i y=1    # var for dynamic name
  declare -i r="$1" # ARG1 RESOLUTION or dimension

  for ((i = 0; i < (r * r); i++)); do # for each in RESOLUTION^2
    ((x++))

    # generate a random number
    myrandom=$((1 + RANDOM % 999))

    # determine "tile type" from random
    if [[ "$myrandom" -le 1 ]]; then
      myrandom="$TILE_WINNER"
    elif [[ "$myrandom" -ge 2 ]] && [[ "$myrandom" -le 900 ]]; then
      myrandom="$TILE_WOOD"
    elif [[ "$myrandom" -ge 901 ]] && [[ "$myrandom" -le 974 ]]; then
      myrandom="$TILE_TREE"
    elif [[ "$myrandom" -ge 975 ]]; then
      myrandom="$TILE_CABIN"
    fi

    # use eval to set dynamically-named variable
    eval "$(printf "declare -A -g p%02d%02d[home]=\"%s\"" "$x" "$y" "$myrandom")" # set var loop

    # [[ "$dbug" == "on" ]] && printf "\n GENERATED: (%02d,%02d): %s" "$x" "$y" "$myrandom"

    # start a new row
    [[ $x == "$r" ]] && x=0 && ((y += 1))
  done
}
function makeScreen() {
  # Function to initialize framebuffer
  [[ $dbug == on ]] && echo "DEBUG: making screen"

  # creates array to hold pixel data
  # this method is too slow to use as a screen
  # so it runs once to generate a screen which is then updated in increments

  declare -a -g dump_list=()           # log file
  declare -i i q                       # counters
  declare -i x=0 y=$((RESOLUTION + 1)) # coordinates

  for ((i = 1; i < (RESOLUTION + 1); i++)); do   # FOR
    ((y--))                                      # row by row
    for ((q = 1; q < (RESOLUTION + 1); q++)); do # FOR
      ((x++))                                    # column by column
      # [[ "$dbug" == "on" ]] && echo "BLD SCR: ($x,$y)"    # dbug readout
      key_home=$(printf "%s%02d%02d[home]" "p" "$x" "$y") # get key values
      framebuffer+=("${!key_home}")                       # construct display list
      dump_list+=("$(printf "p%02d%02d" "$x" "$y")")      # log created vars
    done
    x=0
  done
}
function drawScreen() {
  # Function to draw-print a square array line-by-line, row-by-by

  declare -n arg1=$1  # array to draw
  declare -i arg2=$2  # needed for line break
  declare -i ticker=0 # array index

  clear

  for point in "${arg1[@]}"; do
    ((ticker++))                                   # increment index
    printf "%s " "$point"                          # draw value
    [[ "$ticker" == "$arg2" ]] && ticker=0 && echo # new line
  done
}

# CABIN EXPANSION
function findTiles() {
  # Function to parse array by values and create a new list to reference them.

  declare -i x=0               # counter
  declare -i y=$((RESOLUTION)) # counter
  # declare -i r=$((RESOLUTION)) # store max RESOLUTION

  declare pix_add      #
  declare pix_val="$1" # ARG1: array value to match
  declare -a -g targ_list=()

  for ((i = 0; i < RESOLUTION; i++)); do
    for ((q = 0; q < RESOLUTION; q++)); do
      ((x++))                                                                     # start x coord at 1
      pix_add=$(printf "%s%02d%02d[home]" "p" "$x" "$y")                          # take a coordinate array
      if [[ ${!pix_add} == "$pix_val" ]]; then                                    # if value matches search target
        [[ "$dbug" == "on" ]] && echo " found: $1: ${pix_add:1:2},${pix_add:3:2}" # readout - targets
        targ_list+=("${pix_add:1:2}${pix_add:3:2}")                               # then store coordinates
      fi
    done
    x=0     # start new row
    ((y--)) # start new column
  done
}
function expandTiles() {
  # Function to clone array cells in grid-formation from 1x1 to 3x3

  declare -n myref="$1" # name ref used to pass array as argument

  for pair in "${myref[@]}"; do
    declare x=${pair:0:2}
    declare y=${pair:2:3}

    # debug notification
    # [[ "$dbug" == on ]] && echo "EXPAND: ($x,$y)"

    replaceTile "$x" "$y" "$TILE_CABIN" n
    replaceTile "$x" "$y" "$TILE_CABIN" s
    replaceTile "$x" "$y" "$TILE_CABIN" e
    replaceTile "$x" "$y" "$TILE_CABIN" w
    replaceTile "$x" "$y" "$TILE_CABIN" ne
    replaceTile "$x" "$y" "$TILE_CABIN" nw
    replaceTile "$x" "$y" "$TILE_CABIN" se
    replaceTile "$x" "$y" "$TILE_CABIN" sw

  done
}
function replaceTile() {
  # Function to update a tile on the map based on coordinates, seek character, and compass direction.

  declare t
  declare myx="$1"       # arg1 x coord
  declare myy="$2"       # arg2 y coord
  declare seek_char="$3" # arg3 search target tile
  declare compass="$4"   # arg4 compass direction

  # Define named constants for compass directions

  [[ $compass == "n" ]] && dx=0 dy=1
  [[ $compass == "s" ]] && dx=0 dy=-1
  [[ $compass == "e" ]] && dx=1 dy=0
  [[ $compass == "w" ]] && dx=-1 dy=0
  [[ $compass == "ne" ]] && dx=1 dy=1
  [[ $compass == "nw" ]] && dx=-1 dy=1
  [[ $compass == "se" ]] && dx=1 dy=-1
  [[ $compass == "sw" ]] && dx=-1 dy=-1

  myx=$(echo "$myx" | sed 's/^0*//') # Remove padding for math
  myy=$(echo "$myy" | sed 's/^0*//') # Remove padding for math
  myx=$((myx + dx))                  # Perform math
  myy=$((myy + dy))                  # Perform math

  # Do not create outside of bounds
  if ((myx > RESOLUTION || myx < 1 || myy > RESOLUTION || myy < 1)); then
    return
  fi

  myx=$(printf "%02d" "$myx")             # Reapply padding
  myy=$(printf "%02d" "$myy")             # Reapply padding
  t=$(printf "p%s%s[home]" "$myx" "$myy") # Construct name

  # Debug notification
  [[ "$dbug" == on ]] && echo "TARGET: $t = ${!t}"

  # Check for overlap
  if [[ ${!t[home]} == "$seek_char" ]]; then
    [[ "$dbug" == on ]] && printf "OVERLAP: %s %s %s %s @ %s\n" "$1" "$2" "$myx" "$myy" "$compass"
    return
  fi

  # Update tile value to replace value
  eval "$t"="$seek_char"

  # Debug notification
  [[ "$dbug" == on ]] && echo "Updated $t = $seek_char"
}

# ACTION FUNCTIONS
function moveNPC() {
  # Function to move NPC to 1 tile toward player

  declare npc_target_x="$npc_x" # npc x coordinate
  declare npc_target_y="$npc_y" # npc y coordinate
  declare playerX="$x"          # player's x coordinate
  declare playerY="$y"          # player's y coordinate

  # store the NPC's current/ old position
  npc_old_pos=$(printf "p%02d%02d" "$npc_x" "$npc_y")

  # NPC movement logic: move toward player location; first x, then y
  [[ "$npc_x" -lt "$playerX" ]] && ((npc_target_x++))
  [[ "$npc_x" -gt "$playerX" ]] && ((npc_target_x--))

  # disallow entry into certain tiles - horizontally
  npc_target=$(printf "p%02d%02d[home]" "$npc_target_x" "$npc_y") # new location, updated X only
  if ! [[ "${!npc_target}" == "$TILE_CABIN" ]]; then              # if not bad tile npc_target_ype
    npc_x=$npc_target_x                                           # approve movement
  fi

  # enemy vertical movement
  [[ "$npc_y" -lt "$playerY" ]] && ((npc_target_y++))
  [[ "$npc_y" -gt "$playerY" ]] && ((npc_target_y--))

  # disallow entry into certain tiles - vertically
  npc_target=$(printf "p%02d%02d[home]" "$npc_x" "$npc_target_y") # new location
  if ! [[ "${!npc_target}" == "$TILE_CABIN" ]]; then              # if not bad tile npc_target_ype
    npc_y=$npc_target_y                                           # approve movement
  fi

  # teleport
  npc_new_pos=$(printf "p%02d%02d" "$npc_x" "$npc_y")         # store new position
  [[ "$npc_old_pos" == "$npc_new_pos" ]] && ((npc_no_move++)) # compare old position, count no movement
  [[ "$npc_no_move" == 3 ]] && npc_no_move=0 && teleportNPC   # after so many turns, run function and reset counter

}
function teleportNPC() {
  local new_npc_x
  local new_npc_y
  local npc_tele_targ
  new_npc_x=$((1 + RANDOM % RESOLUTION))
  new_npc_y=$((1 + RANDOM % RESOLUTION))
  npc_tele_targ=$(printf "p%02d%02d[home]" "$new_npc_x" "$new_npc_y")

  if [[ "${!npc_tele_targ}" == "$TILE_WOOD" ]]; then # IF not bad tile npc_target_ype
    npc_x=$new_npc_x                                 #  approve x movement
    npc_y=$new_npc_y                                 #  approve y movement
  else                                               # OR
    teleportNPC                                      #  run until good tile npc_target_ype
  fi                                                 # END
}
function movePlayer() {
  declare movepath
  # Function to translate keyboard into directional movement

  # wait for any input key
  read -rsn1 -t${GAMESPEED} keystroke

  [[ $keystroke == "w" ]] && ((y = y + 1)) && movepath="n" # directional movement north
  [[ $keystroke == "a" ]] && ((x = x - 1)) && movepath="w" # directional movement west
  [[ $keystroke == "s" ]] && ((y = y - 1)) && movepath="s" # directional movement south
  [[ $keystroke == "d" ]] && ((x = x + 1)) && movepath="e" # directional movement east
  # [[ $keystroke == "m" ]] && seeoldmap && read -rsn1       # launch map viewer

  # keep player "in-bounds" via the array logic
  [[ $x == $((RESOLUTION + 1)) ]] && x=$RESOLUTION && echo "NO WAY" && read -rsn1
  [[ $y == $((RESOLUTION + 1)) ]] && y=$RESOLUTION && echo "NO WAY" && read -rsn1
  [[ $x == 0 ]] && x=1 && echo "NO WAY" && read -rsn1 -t${GAMESPEED}
  [[ $y == 0 ]] && y=1 && echo "NO WAY" && read -rsn1 -t${GAMESPEED}

  # player can't enter some tiles
  denyMove "$TILE_TREE" "$keystroke"

}
function denyMove() {
  # Function to deny illegal movement; reverts position

  declare arg1=$1 # tile type to deny
  declare arg2=$2 # movement direction; need for reversion

  # get location
  play_dest=$(printf "p%02d%02d[home]" "$x" "$y")

  # if movement is to denied tile type
  if [[ "${!play_dest}" == "$1" ]]; then # if bad tile type...
    [[ "$2" == "w" ]] && ((y = y - 1))   # revert last movement
    [[ "$2" == "s" ]] && ((y = y + 1))   # revert last movement
    [[ "$2" == "d" ]] && ((x = x - 1))   # revert last movement
    [[ "$2" == "a" ]] && ((x = x + 1))   # revert last movement
  fi

}
function mainLoop() {
  local clock
  local keystroke
  x=1
  y=1

  while ! [[ $keystroke == "q" ]]; do
    ((clock++))

    # PUT PLAYER ON MAP
    player_tile_id=$(printf "p%02d%02d" "$x" "$y") # store coordinate variable name
    player_target_tile="${player_tile_id}[home]"   # store tile init value
    eval "${player_tile_id}[area]=$TILE_PLAYER"    # set tile val to player

    # PUT PLAYER ON QUICKMAP
    player_tile_xy=${player_tile_id:1}              # get only the coordinates
    player_index=${pixelDictonary[$player_tile_xy]} # get the index using coordinates
    framebuffer[player_index]="$TILE_PLAYER"        # update framebuffer

    # PUT BADGUY ON MAP
    npc_tile_id=$(printf "p%02d%02d" "$npc_x" "$npc_y") # store coordinate variable name
    npc_last_tile="${npc_tile_id}[home]"                # store tile init value
    eval "${npc_tile_id}[area]=$TILE_ENEMY"             # set tile val to enemy

    # PUT BADGUY ON QUICKMAP
    npc_tile_xy=${npc_tile_id:1}              # get only the coordinates
    npc_index=${pixelDictonary[$npc_tile_xy]} # get the index using coordinates
    framebuffer[npc_index]="$TILE_ENEMY"      # update framebuffer

    # QUICK DRAW SCREEN + TEXT
    drawScreen "framebuffer" ${RESOLUTION}                                                   # draw stored screen data
    [[ "$dbug" == on ]] && printf "p%02d%02d:%s \n" "$x" "$y" "${!player_target_tile[home]}" # dbug location / value
    [[ "$dbug" == on ]] && echo "here's $TILE_ENEMY $npc_x $npc_y"                           # dbug badguy location

    # [[ "${!player_target_tile[home]}" == "$TILE_WOOD" ]] && printf "\nThe woods are scary at night.\n"
    # [[ "${!player_target_tile[home]}" == "$TILE_CABIN" ]] && printf "\nInside the cabin feels safer.\n"

    # draw console
    printf "\nUse A S D W to move around, Q to quit.\n\n" # show text
    [[ "$dbug" == on ]] && printf "CLOCK: %s\n" "$clock"  # show clock
    echo                                                  # show spacer

    # CHECK FOR GAME OVER - collision with enemy or exit tile
    [[ "$npc_x" == "$x" ]] && [[ "$npc_y" == "$y" ]] && printf "%sTHEY GOT YOU%s \n" "$RED" "$OFF" && read -rsn1 && return
    [[ "${!player_target_tile[home]}" == "$TILE_WINNER" ]] && printf "\nYOU ESCAPED\n" && read -rsn1 && return

    # PLAYER & BADGUY ACTION
    movePlayer
    moveNPC

    # SET LAST TILE TO INIT VALUE IN VAR DATABASE
    unset "${player_tile_id}[area]" # remove occupation flag from player's tile var
    unset "${npc_tile_id}[area]"    # remove occupation flag from badguy's tile var

    # SET LAST TILE TO INIT VALUE IN QUICK DRAW SCREEN
    framebuffer[player_index]=${!player_target_tile} # revert player's last tile at index
    framebuffer[npc_index]=${!npc_last_tile}         # revert badguy's last tile at index

  done
}

################################################################################
# EXECUTION
################################################################################

function startGame {
  makeCamp $RESOLUTION    # generate map
  findTiles "$TILE_CABIN" # find cabins
  expandTiles "targ_list" # grow cabins
  makeDictionary          # build coordinate–pixel dictionary
  makeScreen              # create first screen from database
  mainLoop                # start game

  # Cleanup
  tput cnorm                                          # restore cursor
  for var in "${dump_list[@]}"; do unset "$var"; done # unset database

}

startGame # generate elements
