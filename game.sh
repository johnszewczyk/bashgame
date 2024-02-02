#!/bin/bash

# Tile-based game. Uses associative array for each tile.
# Another array is used as a framebuffer, as referencing every tile is too slow.

# FONT COLORS
# RED='\033[0;31m' # red
# OFF='\033[0m'    # off

# GLOBAL CONSTANTS
declare -g -i RESOLUTION=30 # game map & screen size
declare -g -i GAMESPEED=1   # think seconds-per-frame, rather
declare -g -i VIEWSIZE=7    # view range
declare -g -i VIEWRADIUS=$(((VIEWSIZE - 1) / 2))
declare -g TILE_ENTRY="🚪"  # door
declare -g TILE_FIELD="🌾"  # empty
declare -g TILE_TREES="🌳"  # blocked
declare -g TILE_WOODS="🌲"  # empty
declare -g TILE_CABIN="🏠"  # safe
declare -g TILE_WATER="🌊"  # trap
declare -g TILE_WINNER="🚔" # exit
declare -g TILE_PLAYER="🏃" # player
declare -g TILE_ENEMY="🔪"  # enemy
declare -g TILE_BORDER="🌳" # border
declare -g TILE_WOLVES="🐺" # enemy

################################################################################
# DEFINITION
################################################################################

# MAKE MAP
function makeCamp {
  # Function to create array of tiles, randomly, to a square
  # RESOLUTION of ARG1; e.g., 10 = 10x10 = 100 items in output array.

  # debug notify
  [[ $DBUG == on ]] && echo "DEBUG: making map"

  local myrandom    # var to hold generated tile content
  declare -i i=0    # int for loop
  declare -i x=0    # int for dynamic name
  declare -i y=1    # int for dynamic name
  declare -i r="$1" # int ARG1 RESOLUTION or dimension

  for ((i = 0; i < (r * r); i++)); do # for each in RESOLUTION^2
    ((x++))

    # BORDER HANDLER

    # top-border tiles = view radius * resolution
    if [[ $i -le $((VIEWRADIUS * r)) ]]; then

      # use eval to set dynamically-named variable
      eval "$(printf "declare -A -g p%02d%02d[init]=\"%s\"" "$x" "$y" "$TILE_BORDER")"

      # start a new row
      [[ $x == "$r" ]] && x=0 && ((y += 1))

      continue
    fi

    # side-border tiles
    if [[ $x -le $VIEWRADIUS ]] || [[ $x -gt $((r - VIEWRADIUS)) ]]; then

      # use eval to set dynamically-named variable
      eval "$(printf "declare -A -g p%02d%02d[init]=\"%s\"" "$x" "$y" "$TILE_BORDER")"

      # start a new row
      [[ $x == "$r" ]] && x=0 && ((y += 1))

      continue
    fi

    # bottom-border tiles
    if [[ $i -ge $((r * r - VIEWRADIUS * r)) ]]; then

      # use eval to set dynamically-named variable
      eval "$(printf "declare -A -g p%02d%02d[init]=\"%s\"" "$x" "$y" "$TILE_BORDER")"

      # start a new row
      [[ $x == "$r" ]] && x=0 && ((y += 1))

      continue
    fi

    # NORMAL TILES

    # make a random number
    myrandom=$((1 + RANDOM % 999))

    # select "tile type" from random
    if [[ "$myrandom" -le 1 ]]; then
      myrandom="$TILE_WINNER"

    elif [[ "$myrandom" -ge 2 ]] && [[ "$myrandom" -le 3 ]]; then
      myrandom="$TILE_WATER"

    elif [[ "$myrandom" -ge 4 ]] && [[ "$myrandom" -le 875 ]]; then
      myrandom="$TILE_WOODS"

    elif [[ "$myrandom" -ge 876 ]] && [[ "$myrandom" -le 900 ]]; then
      myrandom="$TILE_FIELD"

    elif [[ "$myrandom" -ge 901 ]] && [[ "$myrandom" -le 974 ]]; then
      myrandom="$TILE_TREES"

    elif [[ "$myrandom" -ge 975 ]]; then
      myrandom="$TILE_CABIN"
    fi

    # use eval to set dynamically-named list w/ key & value
    eval "$(printf "declare -A -g p%02d%02d[init]=\"%s\"" "$x" "$y" "$myrandom")"

    # create lists of tle type locations for later
    [[ $myrandom == "$TILE_CABIN" ]] && tilelist_cabin+=("$(printf "%02d%02d" "$x" "$y")")
    [[ $myrandom == "$TILE_ENTRY" ]] && tilelist_entry+=("$(printf "%02d%02d" "$x" "$y")")
    [[ $myrandom == "$TILE_FIELD" ]] && tilelist_field+=("$(printf "%02d%02d" "$x" "$y")")
    [[ $myrandom == "$TILE_WATER" ]] && tilelist_water+=("$(printf "%02d%02d" "$x" "$y")")
    [[ $myrandom == "$TILE_WOODS" ]] && tilelist_woods+=("$(printf "%02d%02d" "$x" "$y")")

    # [[ "$DBUG" == "on" ]] && echo "  makeCamp: ($x, $y): $myrandom"

    # start a new row
    [[ $x == "$r" ]] && x=0 && ((y += 1))

    # loading bar
    clear
    echo "LOADING MAP: $i"
  done
}
function makeDictionary {
  # Function to create a reference array
  [[ $DBUG == on ]] && echo "DEBUG: making reference array..."

  local -i i                      # for loop counter
  local -i x=0                    # for increment
  local -i y=$RESOLUTION          # for new row
  declare -A -g pixelDictonary=() # dict array for coord-pixel relationship

  for ((i = 0; i < (RESOLUTION * RESOLUTION); i++)); do
    ((x++))                                             # increment column
    pixelDictonary[$(printf "%02d%02d" "$x" "$y")]="$i" # store data
    [[ $x == "$RESOLUTION" ]] && x=0 && ((y += -1))     # start a new row
  done
}

# DISPLAY
function makeScreen {
  # Function to initialize framebuffer

  [[ $DBUG == on ]] && echo "DEBUG: making screen"

  declare -i i q                   # counters
  declare -i x=0                   # x coordinate
  declare -i y=$((RESOLUTION + 1)) # y coordinate

  for ((i = 1; i < (RESOLUTION + 1); i++)); do   # FOR
    ((y--))                                      # row by row
    for ((q = 1; q < (RESOLUTION + 1); q++)); do # FOR
      ((x++))                                    # column by column
      # [[ "$DBUG" == "on" ]] && echo "  BLD SCR: ($x,$y)"    # DBUG readout
      key_home=$(printf "%s%02d%02d[init]" "p" "$x" "$y") # get key values
      framebuffer+=("${!key_home}")                       # construct display list
      tile_list+=("$(printf "p%02d%02d" "$x" "$y")")      # log created vars
    done
    x=0
  done
}
function drawScreen {
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
function drawConsole {
  # Function to draw text below game area

  echo "$message1"                                                  # console message
  [[ "$DBUG" == on ]] && echo "CLOCK: $clock"                       # show clock
  [[ "$DBUG" == on ]] && echo "YOU: ($x,$y): ${!player_tile[init]}" # DBUG location / value
  [[ "$DBUG" == on ]] && echo "NPC: $TILE_ENEMY $npc_x $npc_y"      # DBUG badguy location
  echo                                                              # spacer

  # Idle text
  [[ "${!player_tile[init]}" == "$TILE_WOODS" ]] && message1="The woods are scary at night."
  [[ "${!player_tile[init]}" == "$TILE_CABIN" ]] && message1="The cabin feels safer."
  [[ "${!player_tile[init]}" == "$TILE_FIELD" ]] && message1="The clearing feels unsafe."

}
function drawWindow {
  # Function to draw a small window of map.
  # Needs handling for tiles out-of-bounds.

  clear

  # get player's current location by index - already defined elsewhere
  local player_index="${pixelDictonary[$player_tile_xy]}"

  # determine adjacent tiles; easy since tiles are grid; x = ones y = tens place
  # declare -a offsets=(-5 -4 -3 -2 -1 0 1 2 3 4 5)
  declare -a offsets=()

  # describe adjacent tiles in loop instead, to construct offsets array
  declare -i lower_bound=$((VIEWRADIUS * -1))

  for ((i = 0; i < VIEWSIZE; i++)); do

    offsets+=("$lower_bound")
    ((lower_bound++))

  done

  # draw adjacent tiles squarely around cursor
  for yoff in "${offsets[@]}"; do

    # line break to draw screen by column / row
    declare -i lineBR=0

    for xoff in "${offsets[@]}"; do
      ((lineBR++))

      new_offset=$((xoff + (yoff * RESOLUTION) + player_index))

      echo -n "${framebuffer[new_offset]}"

    done
    [[ $lineBR -eq "${#offsets[@]}" ]] && lineBR=0 && echo

  done

}

# MENUS
function debugMenu {
  local select
  clear
  echo "DEBUG MENU"
  echo
  echo "  player X,Y: ($x, $y) @ ${!player_tile[init]}"
  echo
  echo "WORKING PATH"
  echo "  $PWD"
  echo
  echo "Data Views"
  echo "  [1] - tile list - keys"
  echo "  [2] - tile list - values"
  echo "  [3] - framebuffer - keys"
  echo "  [4] - framebuffer - values"
  echo "        - (to disk)"
  echo "  [5] - exit"
  read -rsn1 select

  # show
  [[ $select == 1 ]] && debugDump tile_list key
  [[ $select == 2 ]] && debugDump tile_list value
  [[ $select == 3 ]] && debugDump framebuffer key
  [[ $select == 4 ]] && debugDump framebuffer value file
  [[ $select == 5 ]] && return

  startMenu
}
function debugDump {
  # Function to show array keys & values in columns

  # arguments
  declare -n arg1="$1" # array to dump
  declare arg2="$2"    # print key or value
  declare -i lineBR=0

  # vars to dump to disk
  local datetime
  local filename
  datetime=$(date +"%Y-%m-%d %H:%M:%S")
  filename="${datetime//\:/}"

  clear

  for akey in "${!arg1[@]}"; do
    ((lineBR++))

    # show keys or values
    [[ $2 == 'key' ]] && printf "%03d " "$akey"
    [[ $2 == 'value' ]] && echo -n "${arg1[$akey]} "

    # dump to text file
    if [[ $3 == 'file' ]]; then

      # write value
      echo -n "${arg1[$akey]}" >>"$filename.log"

      # write break
      [[ $lineBR -eq $RESOLUTION ]] && echo >>"$filename.log"
    fi
    # line break on resolution
    [[ $lineBR -eq $RESOLUTION ]] && lineBR=0 && echo

  done

  echo
  echo "Press any key"
  read -rsn1 select
  debugMenu
}
function startMenu {
  # Function to draw menu
  clear
  tput cup 5 5 && echo "   C A M P 🔪 E S C A P E"
  tput cup 7 10 && echo "Press 'g' to start"
  tput cup 9 10 && echo "Press 'q' to quit"
  echo

  read -rsn1 var1
  [[ $var1 == g ]] && startGame
  [[ $var1 == 1 ]] && debugMenu
  [[ $var1 == q ]] && exit
  startMenu
}
function gOverMenu {
  local lineBR=0
  clear
  echo
  echo
  for _ in {1..10}; do
    ((lineBR++))
    echo -n "    🪦    "
    [[ $lineBR -ge 5 ]] && lineBR=0 && echo && echo
  done

  echo && echo
  echo "         💀  G A M E   O V E R "
  echo && echo

  lineBR=0
  for _ in {1..10}; do
    ((lineBR++))
    echo -n "    🪦    "
    [[ $lineBR -ge 5 ]] && lineBR=0 && echo && echo
  done
  echo

  sleep 2
  startMenu
}
function mapFilter {
  declare arg1="$1" # show tile
  declare lineBR=0

  clear
  for each in "${tile_list[@]}"; do 
    [[ $each == $1 ]] && echo
    ((lineBR++))
  done
}

# CINEMATICS

function winMovie {
  clear
}
function dieMovie {
  tput civis
  clear

  ay=7
  for _ in {1..3}; do
    ax=0
    for _ in {1..9}; do
      clear
      tput cup $ax $ay
      echo -n "🩸"
      sleep .025
      ((ax++))
    done
  done
  gOverMenu
}

# TILE EXPANSION
function findTiles {
  # Function to parse array by values and create a new list to reference them.

  #  DEPRECATED

  declare -i x=0               # counter
  declare -i y=$((RESOLUTION)) # counter
  declare tile_array           # holds constructed name
  declare tile_match="$1"      # arg2 array value to match
  declare -a -g targ_list=()   # output

  for ((i = 0; i < RESOLUTION; i++)); do
    for ((q = 0; q < RESOLUTION; q++)); do
      ((x++))                                                                            # start x coord at 1
      tile_array=$(printf "p%02d%02d[init]" "$x" "$y")                                   # take a coordinate array
      if [[ ${!tile_array} == "$tile_match" ]]; then                                     # if value matches search target
        [[ "$DBUG" == "on" ]] && echo "  found: $1: ${tile_array:1:2},${tile_array:3:2}" # readout - targets
        targ_list+=("${tile_array:1:2}${tile_array:3:2}")                                # then store coordinates
      fi
    done
    x=0     # start new row
    ((y--)) # start new column
  done
}
function growTiles {
  # Function to clone array cells in grid-formation from 1x1 to 3x3

  declare arg2="$2"     #
  declare -n myref="$1" # name ref used to pass array as argument

  for pair in "${myref[@]}"; do
    declare x=${pair:0:2}
    declare y=${pair:2:3}

    replaceTile "$x" "$y" "$arg2" n
    replaceTile "$x" "$y" "$arg2" s
    replaceTile "$x" "$y" "$arg2" e
    replaceTile "$x" "$y" "$arg2" w
    replaceTile "$x" "$y" "$arg2" ne
    replaceTile "$x" "$y" "$arg2" nw
    replaceTile "$x" "$y" "$arg2" se
    replaceTile "$x" "$y" "$arg2" sw

  done
}
function growDoors {
  # Function change NSEW tile to door - has issues

  declare -n myref="$1" # name ref used to pass array as argument
  declare arg2="$2"     # tile type to write

  for pair in "${myref[@]}"; do
    declare x=${pair:0:2} # get X
    declare y=${pair:2:3} # get Y
    declare randnumb=0

    # randomly add door to NSEW position

    # make a random number to decide which wall holds door
    randnumb=$((1 + RANDOM % 8))

    # test doorstep for acceptable tile and make door
    [[ $randnumb == 1 ]] && tileTestA "$x" "$y" 0 2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" n
    [[ $randnumb == 2 ]] && tileTestA "$x" "$y" 0 -2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" s
    [[ $randnumb == 3 ]] && tileTestA "$x" "$y" 2 0 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" e
    [[ $randnumb == 4 ]] && tileTestA "$x" "$y" -2 0 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" w
    [[ $randnumb == 5 ]] && tileTestA "$x" "$y" 2 2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" ne
    [[ $randnumb == 6 ]] && tileTestA "$x" "$y" -2 2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" nw
    [[ $randnumb == 7 ]] && tileTestA "$x" "$y" 2 -2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" se
    [[ $randnumb == 8 ]] && tileTestA "$x" "$y" -2 -2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" sw

  done
}
function replaceTile {
  # Function to update a tile on the map based on coordinates, seek character, and compass direction.

  # Debug notification
  [[ "$DBUG" == on ]] && echo "REPLACE TILE"

  declare myx="$1"       # arg1 x coord
  declare myy="$2"       # arg2 y coord
  declare seek_char="$3" # arg3 search target tile
  declare compass="$4"   # arg4 compass direction
  declare t              # constructed name
  declare -i dx          # delta x
  declare -i dy          # delta y

  # Define named constants for compass directions
  [[ $compass == "c" ]] && dx=0 dy=0
  [[ $compass == "n" ]] && dx=0 dy=1
  [[ $compass == "s" ]] && dx=0 dy=-1
  [[ $compass == "e" ]] && dx=1 dy=0
  [[ $compass == "w" ]] && dx=-1 dy=0
  [[ $compass == "ne" ]] && dx=1 dy=1
  [[ $compass == "nw" ]] && dx=-1 dy=1
  [[ $compass == "se" ]] && dx=1 dy=-1
  [[ $compass == "sw" ]] && dx=-1 dy=-1

  # Remove padding for math; perform math
  myx=$(echo "$myx" | sed 's/^0*//')
  myy=$(echo "$myy" | sed 's/^0*//')
  myx=$((myx + dx))
  myy=$((myy + dy))

  # Do not create outside of bounds
  if ((myx > RESOLUTION || myx < 1 || myy > RESOLUTION || myy < 1)); then
    return
  fi

  # Reapply padding; construct name
  myx=$(printf "%02d" "$myx")
  myy=$(printf "%02d" "$myy")
  t=$(printf "p%s%s[init]" "$myx" "$myy")

  # Debug notification
  [[ "$DBUG" == on ]] && echo "  REPLACE TILE: $t = ${!t}"

  # Check for overlap
  # if [[ ${!t[init]} == "$seek_char" ]]; then
  #   [[ "$DBUG" == on ]] && printf "OVERLAP: %s %s %s %s @ %s\n" "$1" "$2" "$myx" "$myy" "$compass"
  #   return
  # fi

  # Update tile value to replace value
  eval "$t"="$seek_char"

  # Debug notification
  [[ "$DBUG" == on ]] && echo "  Updated $t = $seek_char"
}
function tileTestR {
  # Function to test a tile relative to player for type

  declare dx="$1"   # x offset dx
  declare dy="$2"   # y offset dy
  declare arg3="$3" # test for tile
  declare arg4="$4" # tile index
  declare makename  # test tile address/ name

  # ADJUST TARGET TILE

  # Remove padding for math; perform math
  dx=$(echo "$1" | sed 's/^0*//')
  dy=$(echo "$2" | sed 's/^0*//')
  dx=$((x + dx))
  dy=$((y + dy))

  # Reapply padding; construct name
  dx=$(printf "%02d" "$dx")
  dy=$(printf "%02d" "$dy")
  makename=$(printf "p%s%s[$4]" "$dx" "$dy")

  # test if true
  [[ "${!makename}" == "$arg3" ]] && return 0

  return 1

}
function tileTestA {
  # Function to test a tile relative to player for type

  declare arg1="$1" # x
  declare arg2="$2" # y
  declare arg3="$3" # x offset
  declare arg4="$4" # y offset
  declare arg5="$5" # test for tile
  declare arg6="$6" # tile index
  declare makename  # test tile address/ name

  # ADJUST TARGET TILE

  # Remove padding for math; perform math
  arg1=$(echo "$1" | sed 's/^0*//')
  arg2=$(echo "$2" | sed 's/^0*//')
  arg1=$((arg1 + arg3))
  arg2=$((arg2 + arg4))

  # Reapply padding; construct name
  arg1=$(printf "%02d" "$arg1")
  arg1=$(printf "%02d" "$arg2")
  makename=$(printf "p%s%s[$arg6]" "$arg1" "$arg2")

  # test if true
  [[ "${!makename}" == "$arg5" ]] && return 0

  return 1

}

# ACTION FUNCTIONS
function moveNPC {
  # Function to move NPC to 1 tile toward player

  declare npc_target_x="$npc_x" # npc x coordinate
  declare npc_target_y="$npc_y" # npc y coordinate
  declare player_x="$x"         # player's x coordinate
  declare player_y="$y"         # player's y coordinate

  # store the NPC's current/ old position
  npc_old_pos=$(printf "p%02d%02d" "$npc_x" "$npc_y")

  # NPC movement logic: move toward player location; first x, then y
  [[ "$npc_x" -lt "$player_x" ]] && ((npc_target_x++))
  [[ "$npc_x" -gt "$player_x" ]] && ((npc_target_x--))

  # disallow entry into certain tiles - horizontally
  npc_target=$(printf "p%02d%02d[init]" "$npc_target_x" "$npc_y") # new location, updated X only
  if ! [[ "${!npc_target}" == "$TILE_CABIN" ]]; then              # if not bad tile npc_target_ype
    npc_x=$npc_target_x                                           # approve movement
  fi

  # enemy vertical movement
  [[ "$npc_y" -lt "$player_y" ]] && ((npc_target_y++))
  [[ "$npc_y" -gt "$player_y" ]] && ((npc_target_y--))

  # disallow entry into certain tiles - vertically
  npc_target=$(printf "p%02d%02d[init]" "$npc_x" "$npc_target_y") # new location
  if ! [[ "${!npc_target}" == "$TILE_CABIN" ]]; then              # if not bad tile npc_target_ype
    npc_y=$npc_target_y                                           # approve movement
  fi

  # teleport
  npc_new_pos=$(printf "p%02d%02d" "$npc_x" "$npc_y")         # store new position
  [[ "$npc_old_pos" == "$npc_new_pos" ]] && ((npc_no_move++)) # compare old position, count no movement
  [[ "$npc_no_move" == 3 ]] && npc_no_move=0 && teleNPC       # after so many turns, run function and reset counter

}
function teleNPC {
  # local arg1="$1"
  # local arg2="$2"
  local new_npc_x
  local new_npc_y
  local npc_tele_targ
  new_npc_x=$((1 + RANDOM % RESOLUTION))
  new_npc_y=$((1 + RANDOM % RESOLUTION))
  npc_tele_targ=$(printf "p%02d%02d[init]" "$new_npc_x" "$new_npc_y")

  if [[ "${!npc_tele_targ}" == "$TILE_WOODS" ]]; then # IF not bad tile npc_target_ype
    npc_x=$new_npc_x                                  #  approve x movement
    npc_y=$new_npc_y                                  #  approve y movement
  else                                                # OR
    teleNPC                                           #  run until good tile npc_target_ype
  fi                                                  # END
}
function movePlayer {
  # Function to translate keyboard into directional movement

  # wait for any input key
  read -rsn1 -t${GAMESPEED} keystroke

  [[ $keystroke == "w" ]] && ((y = y + 1)) # directional movement north
  [[ $keystroke == "a" ]] && ((x = x - 1)) # directional movement west
  [[ $keystroke == "s" ]] && ((y = y - 1)) # directional movement south
  [[ $keystroke == "d" ]] && ((x = x + 1)) # directional movement east

  # keep player "in-bounds" via the array logic - send message
  [[ $x == $((RESOLUTION + 1)) ]] && x=$RESOLUTION && echo -n "NO WAY" && message1="No way to go east!"
  [[ $y == $((RESOLUTION + 1)) ]] && y=$RESOLUTION && echo -n "NO WAY" && message1="No way to go north!"
  [[ $x == 0 ]] && x=1 && echo -n "NO WAY" && message1="No way to go west"
  [[ $y == 0 ]] && y=1 && echo -n "NO WAY" && message1="No way to go south"

  # player can't enter some tiles
  denyMove "$TILE_TREES" "$keystroke" # can't pass tree
  denyMove "$TILE_CABIN" "$keystroke" # can't pass cabin from woods
  denyMove "$TILE_WOODS" "$keystroke" # can't pass woods from cabin
  denyMove "$TILE_FIELD" "$keystroke" # can't pass field from cabin

}
function denyMove {
  # Function to deny illegal movement; reverts position

  declare arg1=$1 # tile type to deny
  declare arg2=$2 # movement direction; need for reversion

  # get player location array
  play_dest=$(printf "p%02d%02d[init]" "$x" "$y")

  # if movement is to denied tile type, undo movement
  if [[ "${!play_dest}" == "$1" ]]; then # if destination = bad tile

    # EXCEPTION LIST - allow entry TO some tiles FROM others:

    # ...from doors to cabins
    [[ "${!player_tile[init]}" == "$TILE_ENTRY" ]] && [[ $1 == "$TILE_CABIN" ]] && return

    # ... from doors to fields
    [[ "${!player_tile[init]}" == "$TILE_ENTRY" ]] && [[ $1 == "$TILE_FIELD" ]] && return

    # ...from cabins to cabins
    [[ "${!player_tile[init]}" == "$TILE_CABIN" ]] && [[ $1 == "$TILE_CABIN" ]] && return

    # ...from woods to woods
    [[ "${!player_tile[init]}" == "$TILE_WOODS" ]] && [[ $1 == "$TILE_WOODS" ]] && return

    # ...from woods to fields
    [[ "${!player_tile[init]}" == "$TILE_WOODS" ]] && [[ $1 == "$TILE_FIELD" ]] && return

    # ...from fields to woods
    [[ "${!player_tile[init]}" == "$TILE_FIELD" ]] && [[ $1 == "$TILE_WOODS" ]] && return

    # ...from doors to woods
    [[ "${!player_tile[init]}" == "$TILE_ENTRY" ]] && [[ $1 == "$TILE_WOODS" ]] && return

    # revert movement
    [[ "$2" == "w" ]] && ((y = y - 1))
    [[ "$2" == "s" ]] && ((y = y + 1))
    [[ "$2" == "d" ]] && ((x = x - 1))
    [[ "$2" == "a" ]] && ((x = x + 1))

    # send message based on tile
    [[ $arg1 == "$TILE_TREES" ]] && message1="There's a huge tree!"
    [[ $arg1 == "$TILE_CABIN" ]] && message1="There's no way in!"
    [[ $arg1 == "$TILE_WOODS" ]] && message1="There's no way out!"

  fi

}
function mainLoop {

  declare clock
  declare keystroke

  while ! [[ $keystroke == "q" ]]; do
    ((clock++))

    # BEGIN TURN - write moving object positions to database and framebuffer...

    # update player location in database
    player_tile_id=$(printf "p%02d%02d" "$x" "$y") # get current tile's array
    player_tile="${player_tile_id}[init]"          # store tile init value in [init]
    eval "${player_tile_id}[occp]=$TILE_PLAYER"    # set tile val to player

    # update player location in framebuffer
    player_tile_xy=${player_tile_id:1}              # get only the coordinates
    player_index=${pixelDictonary[$player_tile_xy]} # get the index using coordinates
    framebuffer[player_index]="$TILE_PLAYER"        # update framebuffer

    # update NPC location in database
    npc_tile_id=$(printf "p%02d%02d" "$npc_x" "$npc_y") # get current tile's array
    npc_last_tile="${npc_tile_id}[init]"                # store tile init value
    eval "${npc_tile_id}[occp]=$TILE_ENEMY"             # set tile val to npc

    # update NPC location in framebuffer
    npc_tile_xy=${npc_tile_id:1}              # get only the coordinates
    npc_index=${pixelDictonary[$npc_tile_xy]} # get the index using coordinates
    framebuffer[npc_index]="$TILE_ENEMY"      # update framebuffer

    # draw screen + console
    # drawScreen "framebuffer" ${RESOLUTION}
    drawWindow
    drawConsole
    isGameOver

    # TAKE ACTION OF PLAYER + NPCs
    movePlayer # player movement is based on denial & reversion
    moveNPC    # NPC movement is based on approval or denial

    # SET LAST TILE TO INIT VALUE IN DATABASE
    unset "${player_tile_id}[occp]" # remove occupation flag from player's tile var
    unset "${npc_tile_id}[occp]"    # remove occupation flag from badguy's tile var

    # SET LAST TILE TO INIT VALUE IN FRAMEBUFFER
    framebuffer[player_index]=${!player_tile} # revert player's last tile at index
    framebuffer[npc_index]=${!npc_last_tile}  # revert badguy's last tile at index

  done
}
function isGameOver {
  # Function to test if game over

  # enemy tile?
  [[ "$npc_x" == "$x" ]] && [[ "$npc_y" == "$y" ]] && message1="GOT YOU" && dieMovie

  # escape tile?
  [[ "${!player_tile[init]}" == "$TILE_WINNER" ]] && echo "YOU ESCAPED" && sleep 1 && startMenu

  # trap tile?
  [[ "${!player_tile[init]}" == "$TILE_WATER" ]] && echo "YOU DROWNED" && sleep 1 && startMenu

  # in field?
  tileTestR 0 0 "$TILE_FIELD" 'init' && wolfManager
}

# GAME LOOP
function startGame {
  # Function to launch main game

  # Global variables
  declare -g -i x=10                                    # player coodinates X
  declare -g -i y=10                                    # player coodinates Y
  declare -g -i npc_x=$RESOLUTION                       # badguy coordinates X
  declare -g -i npc_y=$RESOLUTION                       # badguy coordinates Y
  declare -g -a framebuffer=()                          # where active display "pixels" are stored
  declare -g -a tile_list=()                            # all tile vars
  declare -g message1='Use A S D W to move, Q to quit.' # hold console text

  # Global lists of tiles
  declare -g -a wolflist=()
  declare -g -a tilelist_cabin=()
  declare -g -a tilelist_entry=()
  declare -g -a tilelist_field=()
  declare -g -a tilelist_water=()
  declare -g -a tilelist_woods=()

  # Build map
  makeCamp $RESOLUTION                     # generate map
  growTiles "tilelist_cabin" "$TILE_CABIN" # grow tiles to 3x3
  growDoors "tilelist_cabin" "$TILE_ENTRY" # make doors
  growTiles "tilelist_water" "$TILE_WATER" # grow tiles to 3x3
  makeDictionary                           # build coordinate–pixel dictionary
  makeScreen                               # create first screen from database

  # Start game
  mainLoop

  # unset database
  for var in "${tile_list[@]}"; do unset "$var"; done

}

function makePack {
  # Function to create managed enemy

  if [[ $1 == 'make' ]]; then
    echo "making"

  fi

  # wolves spawn near fields

  # initialize wolf - an associative array

  # use eval to set dynamically-named variable
  eval "$(printf "declare -A -g e%02d%02d[occp]=\"%s\"" "$x" "$y" "$TILE_WOLVES")"

  # add to list of all
  wolflist+=("$(printf "e%02d%02d" "$x" "$y")") # log created vars

  # PUT WOLF IN DATABASE

  for each in "${!wolflist[@]}"; do
    echo "${each} :: ${wolflist[$each]} "
  done

}

################################################################################
# EXECUTION
################################################################################

# show debug
# DBUG=on

# hide cursor
tput civis

# start main
startMenu

# show cursor
tput cnorm
