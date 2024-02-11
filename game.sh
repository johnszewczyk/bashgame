#!/bin/bash

# BASH5 tile game.

[[ -f log.txt ]] && rm log.txt

# FONT COLORS
# RED='\033[0;31m' # red
# OFF='\033[0m'    # off

# GLOBAL CONSTANTS - SYSTEM
declare -g -i RESOLUTION=20                        # game map & screen size
declare -g -i GAMESPEED=1                          # seconds per frame
declare -g -i VIEWSIZE=9                           # view range; MUST BE ODD
declare -g -i VIEWRADIUS="$(((VIEWSIZE - 1) / 2))" # viewport size

# GLOBAL CONSTANTS - TILES
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
# declare -g TILE_WOLVES="🐺" # enemy

################################################################################
# DEFINITION
################################################################################

# MAKE MAP
function makeCamp {
  # Function to create array of tiles, randomly, to a square
  # RESOLUTION of ARG1; e.g., 10 = 10x10 = 100 items in output array.

  # debug notify
  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') ${FUNCNAME[0]}"

  local myrandom       # var to hold generated tile content
  declare -i i=0       # for loop
  declare -i x=0       # for dynamic name
  declare -i y=1       # for dynamic name
  declare -i arg1="$1" # ARG1 resolution

  # for each in RESOLUTION^2
  for ((i = 0; i < (arg1 * arg1); i++)); do
    ((x++))

    # BORDER HANDLER

    # top-bottom-border tiles = view radius * resolution
    if [[ $i -le $((VIEWRADIUS * arg1)) ]] || [[ $i -ge $((arg1 * arg1 - VIEWRADIUS * arg1)) ]]; then

      # use eval to set dynamically-named variable
      eval "$(printf "declare -A -g p%02d%02d[disp]=\"%s\"" "$x" "$y" "$TILE_BORDER")"

      # start a new row
      [[ $x == "$arg1" ]] && x=0 && ((y += 1))

      continue
    fi

    # side-border tiles
    if [[ $x -le $VIEWRADIUS ]] || [[ $x -gt $((arg1 - VIEWRADIUS)) ]]; then

      # use eval to set dynamically-named variable
      eval "$(printf "declare -A -g p%02d%02d[disp]=\"%s\"" "$x" "$y" "$TILE_BORDER")"

      # start a new row
      [[ $x == "$arg1" ]] && x=0 && ((y += 1))

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
    eval "$(printf "declare -A -g p%02d%02d[disp]=\"%s\"" "$x" "$y" "$myrandom")"
    eval "$(printf "declare -A -g p%02d%02d[init]=\"%s\"" "$x" "$y" "$myrandom")"

    # create lists of tle type locations for later
    [[ $myrandom == "$TILE_CABIN" ]] && tilelist_cabin+=("$(printf "%02d%02d" "$x" "$y")")
    [[ $myrandom == "$TILE_ENTRY" ]] && tilelist_entry+=("$(printf "%02d%02d" "$x" "$y")")
    [[ $myrandom == "$TILE_FIELD" ]] && tilelist_field+=("$(printf "%02d%02d" "$x" "$y")")
    [[ $myrandom == "$TILE_WATER" ]] && tilelist_water+=("$(printf "%02d%02d" "$x" "$y")")
    [[ $myrandom == "$TILE_WOODS" ]] && tilelist_woods+=("$(printf "%02d%02d" "$x" "$y")")

    # [[ "$DBUG" == "on" ]] && echo "  makeCamp: ($x, $y): $myrandom"

    # start a new row
    [[ $x == "$arg1" ]] && x=0 && ((y += 1))

    # loading bar
    clear
    echo "LOADING MAP: $i"
  done

}
function makeDictionary {
  # Function to create a reference array
  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') MAKE DICTIONARY" >>log.txt

  local -i i             # for loop counter
  local -i x=0           # for increment
  local -i y=$RESOLUTION # for new row

  for ((i = 0; i < (RESOLUTION * RESOLUTION); i++)); do
    ((x++))                                             # increment column
    pixelDictonary[$(printf "%02d%02d" "$x" "$y")]="$i" # store data
    [[ $x == "$RESOLUTION" ]] && x=0 && ((y += -1))     # start a new row
  done
}

# DISPLAY
function makeScreen {
  # Function to initialize framebufferf

  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') INIT FRAMEBUFFER" >>log.txt

  declare -i i q                   # counters
  declare -i x=0                   # x coordinate
  declare -i y=$((RESOLUTION + 1)) # y coordinate

  for ((i = 1; i < (RESOLUTION + 1); i++)); do   # FOR
    ((y--))                                      # row by row
    for ((q = 1; q < (RESOLUTION + 1); q++)); do # FOR
      ((x++))                                    # column by column
      # [[ "$DBUG" == "on" ]] && echo "  BLD SCR: ($x,$y)"    # DBUG readout
      key_home=$(printf "%s%02d%02d[disp]" "p" "$x" "$y") # get key values
      framebuffer+=("${!key_home}")                       # construct display list
      tile_list+=("$(printf "p%02d%02d" "$x" "$y")")      # log created vars
    done
    x=0
  done
}
function drawScreen {
  # Function to draw-print a square array line-by-line, row-by-by

  declare -n arg1=$1   # array to draw
  declare -i arg2=$2   # $RESOLUTION
  declare -i line_br=0 # array index

  clear

  for point in "${arg1[@]}"; do
    ((line_br++))                                          # increment index
    printf "%s " "$point"                                  # draw value
    [[ "$line_br" == "$RESOLUTION" ]] && line_br=0 && echo # new line
  done
}
function drawConsole {
  # Function to draw text below game area
  echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') DRAW CONSOLE" >>"log.txt"

  if [[ $DBUG == on ]]; then
    echo "CLOCK: $clock"                                  # show clock
    echo "$TILE_PLAYER @ (${pData[xpos]},${pData[ypos]})" # DBUG location / value
    echo "$TILE_ENEMY @ $npc_x $npc_y "                   # DBUG badguy location
    echo                                                  # spacer
  fi

  # console message
  echo "$message1"

  # idle text
  [[ "${pData[tileicon]}" == "$TILE_WOODS" ]] && message1="The woods are scary at night."
  [[ "${pData[tileicon]}" == "$TILE_CABIN" ]] && message1="The cabin feels safer."
  [[ "${pData[tileicon]}" == "$TILE_ENTRY" ]] && message1="Get inside!"
  [[ "${pData[tileicon]}" == "$TILE_FIELD" ]] && message1="The clearing feels unsafe."

}
function drawWindow {
  # Function to draw a small window of map.

  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') DRAW WINDOW" >>"log.txt"

  clear

  # get player's current location by index - already defined elsewhere
  local player_tile_xy=${pData[tilexy]}
  local player_index="${pixelDictonary[$player_tile_xy]}"

  # determine adjacent tiles; easy since tiles are grid; x = ones y = tens place
  # EXAMPLE: declare -a offsets=(-5 -4 -3 -2 -1 0 1 2 3 4 5)

  declare -a offsets=()

  # describe adjacent tiles in loop
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

      # calc index location
      new_offset=$((xoff + (yoff * RESOLUTION) + player_index))

      # draw at index
      echo -n "${framebuffer[new_offset]}"

    done

    # next row
    [[ $lineBR -eq "${#offsets[@]}" ]] && lineBR=0 && echo

  done

}

# MENUS
function debugMenu {
  local select
  clear
  echo "DEBUG MENU"
  echo
  echo "  player (${pData[xpos]},${pData[ypos]}) @ ${pData[tileicon]}"
  echo
  echo "WORKING PATH"
  echo "  $PWD"
  echo
  echo "Data Views"
  echo "  [1] - tile list - keys"
  echo "  [2] - tile list - values"
  echo "  [3] - framebuffer - keys"
  echo "  [4] - framebuffer - values"
  echo "  [5] - exit"
  read -rsn1 select

  # show
  [[ $select == 1 ]] && debugDump tile_list key RESOLUTION
  [[ $select == 2 ]] && debugDump tile_list value RESOLUTION
  [[ $select == 3 ]] && debugDump framebuffer key RESOLUTION
  [[ $select == 4 ]] && debugDump framebuffer value file RESOLUTION
  [[ $select == 5 ]] && return

  startMenu
}
function debugDump {
  # Function to show array keys & values in columns

  # arguments
  declare -n arg1="$1" # array to dump
  declare arg2="$2"    # print key or value
  declare arg3="$3"    # RESOLUTION for columns
  declare -i lineBR=0  # line break

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
      sleep .05
      ((ax++))
    done
  done
  gOverMenu
}

# MAKE TILES
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
      tile_array=$(printf "p%02d%02d[disp]" "$x" "$y")                                   # take a coordinate array
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

    if [[ $randnumb == 1 ]]; then
      tileTestA "$x" "$y" 0 2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" n || ((randnumb++))

    elif [[ $randnumb == 2 ]]; then
      tileTestA "$x" "$y" 0 -2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" s || ((randnumb++))

    elif [[ $randnumb == 3 ]]; then
      tileTestA "$x" "$y" 2 0 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" e || ((randnumb++))

    elif [[ $randnumb == 4 ]]; then
      tileTestA "$x" "$y" -2 0 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" w || ((randnumb++))

    elif [[ $randnumb == 5 ]]; then
      tileTestA "$x" "$y" 1 2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" ne || ((randnumb++))

    elif [[ $randnumb == 6 ]]; then
      tileTestA "$x" "$y" -1 2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" nw || ((randnumb++))

    elif [[ $randnumb == 7 ]]; then
      tileTestA "$x" "$y" 1 -2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" se || ((randnumb++))

    elif [[ $randnumb == 8 ]]; then
      tileTestA "$x" "$y" -1 -2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" sw
    fi

    # old method - leaves some without
    # [[ $randnumb == 1 ]] && tileTestA "$x" "$y" 0 2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" n
    # [[ $randnumb == 2 ]] && tileTestA "$x" "$y" 0 -2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" s
    # [[ $randnumb == 3 ]] && tileTestA "$x" "$y" 2 0 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" e
    # [[ $randnumb == 4 ]] && tileTestA "$x" "$y" -2 0 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" w
    # [[ $randnumb == 5 ]] && tileTestA "$x" "$y" 1 2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" ne
    # [[ $randnumb == 6 ]] && tileTestA "$x" "$y" -1 2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" nw
    # [[ $randnumb == 7 ]] && tileTestA "$x" "$y" 1 -2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" se
    # [[ $randnumb == 8 ]] && tileTestA "$x" "$y" -1 -2 $TILE_WOODS init && replaceTile "$x" "$y" "$arg2" sw

  done
}
function replaceTile {
  # Function to update a tile on the map based on coordinates, seek character, and compass direction.

  # Debug notification
  [[ "$DBUG" == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') REPLACE TILE"

  declare myx="$1"       # arg1 x coord
  declare myy="$2"       # arg2 y coord
  declare seek_char="$3" # arg3 search target tile
  declare compass="$4"   # arg4 compass direction
  declare tileicon       # constructed name
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
  tileicon=$(printf "p%s%s[disp]" "$myx" "$myy")

  # Debug notification
  [[ "$DBUG" == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')   TILE: $tileicon = ${!tileicon}"

  # Check for overlap
  # if [[ ${!tileicon[disp]} == "$seek_char" ]]; then
  #   [[ "$DBUG" == on ]] && printf "OVERLAP: %s %s %s %s @ %s\n" "$1" "$2" "$myx" "$myy" "$compass"
  #   return
  # fi

  # Update tile value to replace value
  eval "$tileicon"="$seek_char"

  # Debug notification
  [[ "$DBUG" == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')   Updated $tileicon = $seek_char"
}
function tileTestA {
  # Function to test a tile at absolute position + offsets
  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') TILE TEST: ($1,$2:$3,$4:$5)" >>log.txt

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
  arg2=$(printf "%02d" "$arg2")
  makename=$(printf "p%s%s[$arg6]" "$arg1" "$arg2")

  # test if true
  [[ "${!makename}" == "$arg5" ]] && return 0
  return 1

}

# TURN LOOP FUNCTIONS
function shortCuts {
  # Function to update shortcut variables since subshells do not run @ call

  # array name of occupied tile
  pData[tilename]="$(printf "p%02d%02d" "${pData[xpos]}" "${pData[ypos]}")"

  # store occupied tile's [disp] data by address
  pData[tiledisp]="$(printf "%s[disp]" "${pData[tilename]}")"

  # store occupied tile's [disp] data content
  pData[tileicon]="${!pData[tiledisp]}"

  # store occupied tile's XY address as padded 4-digit XXYY
  pData[tilexy]="$(printf "%02d%02d" "${pData[xpos]}" "${pData[ypos]}")"

}
function isGameOver {
  # Function to test if game over
  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') IS GAME OVER" >>"log.txt"

  # enemy tile?
  [[ "$npc_x" == "${pData[xpos]}" ]] && [[ "$npc_y" == "${pData[ypos]}" ]] && message1="GOT YOU" && dieMovie

  # escape tile?
  [[ "${pData[tileicon]}" == "$TILE_WINNER" ]] && echo "YOU ESCAPED" && sleep 1 && startMenu

  # trap tile?
  [[ "${pData[tileicon]}" == "$TILE_WATER" ]] && echo "YOU DROWNED" && sleep 1 && startMenu

  # in field?
  tileTestA "${pData[xpos]}" "${pData[ypos]}" 0 0 "$TILE_FIELD" 'init' && echo WOLF
}

# ACTION FUNCTIONS
function moveNPC {
  # Function to move NPC to 1 tile toward player

  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') MOVE NPC" >>"log.txt"

  declare npc_target_x="$npc_x"     # npc x coordinate
  declare npc_target_y="$npc_y"     # npc y coordinate
  declare player_x="${pData[xpos]}" # player x coordinate
  declare player_y="${pData[ypos]}" # player y coordinate

  # store the NPC's current/ old position
  npc_old_pos=$(printf "p%02d%02d" "$npc_x" "$npc_y")

  # NPC movement logic: move toward player location; first x, then y
  [[ "$npc_x" -lt "$player_x" ]] && ((npc_target_x++))
  [[ "$npc_x" -gt "$player_x" ]] && ((npc_target_x--))

  # disallow entry into certain tiles - horizontally
  npc_target=$(printf "p%02d%02d[disp]" "$npc_target_x" "$npc_y") # new location, updated X only
  if ! [[ "${!npc_target}" == "$TILE_CABIN" ]]; then              # if not bad tile npc_target_ype
    npc_x=$npc_target_x                                           # approve movement
  fi

  # enemy vertical movement
  [[ "$npc_y" -lt "$player_y" ]] && ((npc_target_y++))
  [[ "$npc_y" -gt "$player_y" ]] && ((npc_target_y--))

  # disallow entry into certain tiles - vertically
  npc_target=$(printf "p%02d%02d[disp]" "$npc_x" "$npc_target_y") # new location
  if ! [[ "${!npc_target}" == "$TILE_CABIN" ]]; then              # if not bad tile npc_target_ype
    npc_y=$npc_target_y                                           # approve movement
  fi

  # teleport
  npc_new_pos=$(printf "p%02d%02d" "$npc_x" "$npc_y")         # store new position
  [[ "$npc_old_pos" == "$npc_new_pos" ]] && ((npc_no_move++)) # compare old position, count no movement
  [[ "$npc_no_move" == 3 ]] && npc_no_move=0 && teleNPC       # after so many turns, run function and reset counter

}
function teleNPC {
  # Function to move NPC randomly

  local -i new_npc_x
  local -i new_npc_y
  local npc_tele_targ
  new_npc_x=$((1 + RANDOM % RESOLUTION))
  new_npc_y=$((1 + RANDOM % RESOLUTION))
  npc_tele_targ=$(printf "p%02d%02d[disp]" "$new_npc_x" "$new_npc_y")

  if [[ "${!npc_tele_targ}" == "$TILE_WOODS" ]]; then # IF not bad tile npc_target_ype
    npc_x=$new_npc_x                                  #  approve x movement
    npc_y=$new_npc_y                                  #  approve y movement
  else                                                # OR
    teleNPC                                           #  run until good tile npc_target_ype
  fi                                                  # END
}

# PLAYER MOVEMENT
function movePlayer {
  # Function to move player to new tile; test new tile; revert or approve move

  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') MOVE PLAYER" >>log.txt
  # [[ $DBUG == on ]] && echo "  now: ${pData[tileicon]} @ ${pData[xpos]}, ${pData[ypos]}" >>log.txt

  # store the last tile
  lasttile=${pData[tileicon]}

  # wait for any input key
  read -rsn1 -t${GAMESPEED} keystroke

  # directional movement
  [[ $keystroke == "w" ]] && ((pData[ypos] += 1))
  [[ $keystroke == "a" ]] && ((pData[xpos] -= 1))
  [[ $keystroke == "s" ]] && ((pData[ypos] -= 1))
  [[ $keystroke == "d" ]] && ((pData[xpos] += 1))
  [[ $keystroke == "0" ]] && debugMenu
  [[ -z $keystroke ]] && return

  # keep in bounds
  moveBounds

  # update shortcuts after input
  shortCuts

  # player can't enter some tiles
  moveApprove "$TILE_TREES" "$keystroke" "$lasttile" # can't enter tree
  moveApprove "$TILE_CABIN" "$keystroke" "$lasttile" # can't enter cabin
  moveApprove "$TILE_WOODS" "$keystroke" "$lasttile" # can't enter woods from cabin
  # moveApprove "$TILE_FIELD" "$keystroke" "$lasttile" # can't enter field from cabin

}
function moveBounds {
  # Function to stop movement out-of-bounds

  # keep player "in-bounds" via the array logic - send message
  [[ ${pData[xpos]} == $((RESOLUTION + 1)) ]] && pData[xpos]=$RESOLUTION && message1="No way to go east!"
  [[ ${pData[ypos]} == $((RESOLUTION + 1)) ]] && pData[ypos]=$RESOLUTION && message1="No way to go north!"
  [[ ${pData[xpos]} == 0 ]] && pData[xpos]=1 && message1="No way to go west"
  [[ ${pData[ypos]} == 0 ]] && pData[ypos]=1 && message1="No way to go south"

}
function moveApprove {
  # Function to deny illegal movement; reverts position

  declare arg1=$1 # illegal tile to test
  declare arg2=$2 # movement direction for reversion
  declare arg3=$3 # last approved tile

  # if movement is to denied tile type, undo movement
  if [[ "${pData[tileicon]}" == "$1" ]]; then # if destination = bad tile

    # UNESS... - EXCEPTION LIST - allow entry TO some tiles FROM others:

    # ...from doors to cabin
    [[ "$3" == "$TILE_ENTRY" ]] && [[ $1 == "$TILE_CABIN" ]] && return

    # ...from cabin to cabin
    [[ "$3" == "$TILE_CABIN" ]] && [[ $1 == "$TILE_CABIN" ]] && return

    # ... from doors to field
    [[ "$3" == "$TILE_ENTRY" ]] && [[ $1 == "$TILE_FIELD" ]] && return

    # ...from woods to woods
    [[ "$3" == "$TILE_WOODS" ]] && [[ $1 == "$TILE_WOODS" ]] && return

    # ...from woods to field
    [[ "$3" == "$TILE_WOODS" ]] && [[ $1 == "$TILE_FIELD" ]] && return

    # ...from fields to woods
    [[ "$3" == "$TILE_FIELD" ]] && [[ $1 == "$TILE_WOODS" ]] && return

    # ...from doors to woods
    [[ "$3" == "$TILE_ENTRY" ]] && [[ $1 == "$TILE_WOODS" ]] && return

    [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') DENY MOVE to $1 [$2] fr $3" >>log.txt
    [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')   to: ${pData[tileicon]}" >>log.txt

    # revert movement
    [[ "$2" == "w" ]] && ((pData[ypos] -= 1))
    [[ "$2" == "s" ]] && ((pData[ypos] += 1))
    [[ "$2" == "d" ]] && ((pData[xpos] -= 1))
    [[ "$2" == "a" ]] && ((pData[xpos] += 1))

    # update player data
    shortCuts

    [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')   no entry: ${pData[tilexy]}:${pData[tileicon]}" >>log.txt

    # send message based on tile
    [[ $1 == "$TILE_TREES" ]] && message1="There's a huge tree!"
    [[ $1 == "$TILE_CABIN" ]] && message1="There's no way in!"
    [[ $1 == "$TILE_WOODS" ]] && message1="There's no way out!"

  fi

}

function mainLoop {
  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') MAIN LOOP" >>log.txt

  declare clock
  declare keystroke

  while ! [[ $keystroke == "q" ]]; do
    ((clock++))

    # BEGIN TURN - write moving object positions to database and framebuffer...

    # update player location in framebuffer
    player_index="${pixelDictonary[${pData[tilexy]}]}" # get the index using coordinates
    framebuffer[player_index]="$TILE_PLAYER"           # update framebuffer
    player_tile="p${pData[tilexy]}[disp]"              # store tile init value in [disp]

    # update NPC location in database
    npc_tile_id=$(printf "p%02d%02d" "$npc_x" "$npc_y") # get current tile's array
    npc_last_tile="${npc_tile_id}[disp]"                # store tile init value address
    npc_last_tile=${!npc_last_tile}                     # store tile init value

    # # update NPC location in framebuffer
    npc_tile_xy=$(printf "%02d%02d" "$npc_x" "$npc_y") # get only the coordinates
    npc_index=${pixelDictonary[$npc_tile_xy]}          # get the index using coordinates
    framebuffer[npc_index]="$TILE_ENEMY"               # update framebuffer

    # draw screen + console
    drawWindow
    drawConsole
    isGameOver

    # TAKE ACTION OF PLAYER + NPCs
    movePlayer # player movement is based on denial & reversion
    moveNPC    # NPC movement is based on approval or denial

    # UPDATE FRAMEBUFFER INCREMENTALLY - clear previous tile
    framebuffer[player_index]=${!player_tile} # revert player's last tile at index
    framebuffer[npc_index]="${npc_last_tile}" # revert badguy's last tile at index

  done
}

# GAME LOOP
function startGame {
  # Function to launch main game

  # Global variables
  declare -g keystroke                                  # last keystroke
  declare -g lasttile                                   # last tile occupied
  declare -g message1='Use A S D W to move, Q to quit.' # init console text
  declare -g -a framebuffer=()                          # where active display "pixels" are stored
  declare -A -g pixelDictonary=()                       # dict array for coord-pixel relationship

  # vars to manage moving items
  declare -g -A pData=()          # array of player data
  declare -g -i npc_x=$RESOLUTION # badguy coordinates X
  declare -g -i npc_y=$RESOLUTION # badguy coordinates Y

  # vars to manage tiles
  declare -g -a tile_list=()
  declare -g -a tilelist_cabin=()
  declare -g -a tilelist_entry=()
  declare -g -a tilelist_field=()
  declare -g -a tilelist_water=()
  declare -g -a tilelist_woods=()

  # Build map
  makeCamp RESOLUTION                    # generate map
  growTiles tilelist_cabin "$TILE_CABIN" # grow tiles to 3x3
  growDoors tilelist_cabin "$TILE_ENTRY" # make doors
  growTiles tilelist_water "$TILE_WATER" # grow tiles to 3x3
  makeDictionary                         # build coordinate–pixel dictionary
  makeScreen RESOLUTION                  # create first screen from database

  # make player
  pData[xpos]=6
  pData[ypos]=6
  shortCuts

  # Start game
  mainLoop

  # unset database
  for var in "${tile_list[@]}"; do unset "$var"; done

}

################################################################################
# EXECUTION
################################################################################

# show debug
DBUG=on

# hide cursor
tput civis

# auto-launch
startGame

# start main menu
# startMenu

# show cursor
tput cnorm

clear
cat log.txt
