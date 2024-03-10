#!/bin/bash

# BASH5 tile game.

[[ -f log.txt ]] && rm log.txt

################################################################################
# DEFINITION
################################################################################

function initConstants {
  # Function to set all global constant vars

  # FONT COLORS
  declare -g -r RED='\033[0;31m' # red
  declare -g -r OFF='\033[0m'    # off

  # GLOBAL CONSTANTS - SYSTEM
  declare -g DBUG=on
  declare -g -i DIMS=100                          # map size
  declare -g -i GAMESPEED=1                       # seconds per frame
  declare -g -i VIEWSIZE=9                        # view range; MUST BE ODD
  declare -g -i VIEWRAD="$(((VIEWSIZE - 1) / 2))" # viewport size

  # GLOBAL CONSTANTS - OFFSETS
  declare -g -i -r PATHN=$((-DIMS))
  declare -g -i -r PATHS=$((DIMS))
  declare -g -i -r PATHE=1
  declare -g -i -r PATHW=-1
  declare -g -i -r PATHNE=$((-DIMS + 1))
  declare -g -i -r PATHNW=$((-DIMS - 1))
  declare -g -i -r PATHSE=$((DIMS + 1))
  declare -g -i -r PATHSW=$((DIMS - 1))

  # GLOBAL CONSTANTS - TILES
  declare -g -r TILE_BORDER="🌳" # border
  declare -g -r TILE_CABIN="🏠"  # safe
  declare -g -r TILE_DOOR="🚪"   # door
  declare -g -r TILE_FIELD="🌾"  # empty
  declare -g -r TILE_TREES="🌳"  # blocked
  declare -g -r TILE_WOODS="🌲"  # empty
  declare -g -r TILE_LAKE="🌊"   # trap
  declare -g -r TILE_EXIT="🚔"   # exit
  declare -g -r TILE_HUMAN="🏃"  # human
  declare -g -r TILE_KNIFE="🔪"  # enemy
  declare -g -r TILE_WOLF="🐺"   # enemy
}
function initGameVars {
  # Function to initialize variables used in-game

  # Global variables
  declare -g gametime=0                                 # gametime / clock
  declare -g keypress=0                                 # last keypress
  declare -g message1='Use A S D W to move, Q to quit.' # init console text
  declare -a -g framebuffer=()                          # where active display "pixels" are stored
  declare -a -g tile_map=()                             # initial map for ref

  # vars to manage moving items
  declare -g -a wolflist=()
  declare -g -a knife_list=()

  # vars to manage tiles
  declare -g -a tilelist_cabin=()
  declare -g -a tilelist_entry=()
  declare -g -a tilelist_field=()
  declare -g -a tilelist_water=()
  declare -g -a tilelist_woods=()
  declare -g tile_loss # report loss reason

  # define some specifc squares
  declare -g GRID_SW=$((DIMS * DIMS - VIEWRAD * DIMS + VIEWRAD - DIMS))
  declare -g GRID_NE=$((VIEWRAD * DIMS - VIEWRAD + DIMS))
  declare -g GRID_NW=$((DIMS * VIEWRAD + VIEWRAD))
}

# MAKE MAP
function loadCamp {
  # Function to read array from text file
  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') LOAD CAMP" >>log.txt

  declare filename="stage01.txt"
  declare -g char_array=()

  # Loop through each line in the file
  while IFS= read -r line; do
    # Loop through each character in the line
    for ((i = 0; i < ${#line}; i++)); do
      # Extract character and append it to the array
      char="${line:$i:1}"
      char_array+=("$char")
      DIMS=${#line}
    done
  done <"$filename"

  tile_map=("${char_array[@]}")

  clear
  echo "map size = $DIMS"
  sleep 2

  startLoad

}
function makeCamp {
  declare -a -g tile_map=()
  # Function to make array of tiles, randomly. ARG must be square number.

  # debug notify
  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') MAKE CAMP" >>log.txt

  local myrandom # var to hold generated tile content
  local -i i x y

  # for each in DIMS^2
  for ((i = 0; i < ($1 * $1); i++)); do
    # [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')   loading: $i of $(($1 * $1))"

    # BORDER HANDLER

    # top-bottom-border tiles = view radius * DIMS
    if [[ $i -le $((VIEWRAD * $1)) ]] || [[ $i -ge $(($1 * $1 - VIEWRAD * $1)) ]]; then
      tile_map[i]=$TILE_BORDER
      continue
    fi

    # side-border tiles
    x=$((i % $1)) # calc x
    y=$((i / $1)) # calc y

    if ((x < VIEWRAD || x >= ($1 - VIEWRAD))); then
      tile_map[i]="$TILE_BORDER"
      continue
    elif ((y < VIEWRAD || y >= ($1 - VIEWRAD))); then
      tile_map[i]="$TILE_BORDER"
      continue
    fi

    # NORMAL TILES

    # make a random number
    myrandom=$((1 + RANDOM % 999))

    # select "tile type" from random
    if [[ "$myrandom" -le 1 ]]; then
      myrandom="$TILE_EXIT"

    elif [[ "$myrandom" -ge 2 ]] && [[ "$myrandom" -le 3 ]]; then
      myrandom="$TILE_LAKE"

    elif [[ "$myrandom" -ge 4 ]] && [[ "$myrandom" -le 875 ]]; then
      myrandom="$TILE_WOODS"

    elif [[ "$myrandom" -ge 876 ]] && [[ "$myrandom" -le 900 ]]; then
      myrandom="$TILE_FIELD"

    elif [[ "$myrandom" -ge 901 ]] && [[ "$myrandom" -le 974 ]]; then
      myrandom="$TILE_TREES"

    elif [[ "$myrandom" -ge 975 ]]; then
      myrandom="$TILE_CABIN"
    fi

    # make lists of tile type locations for later
    [[ $myrandom == "$TILE_CABIN" ]] && tilelist_cabin+=("$i")
    [[ $myrandom == "$TILE_DOOR" ]] && tilelist_entry+=("$i")
    [[ $myrandom == "$TILE_FIELD" ]] && tilelist_field+=("$i")
    [[ $myrandom == "$TILE_LAKE" ]] && tilelist_water+=("$i")
    [[ $myrandom == "$TILE_WOODS" ]] && tilelist_woods+=("$i")

    # save tile
    tile_map[i]=$myrandom

  done

}
function expand3x3 {
  # Function to clone array cells in grid-formation from 1x1 to 3x3

  [[ "$DBUG" == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') GROW TILE ($1, $2, $3)" >>log.txt

  declare -n myref="$1" # name ref used to pass array as argument
  declare arg2="$2"     # tile

  for i in "${myref[@]}"; do
    replaceTile "$i" $PATHN "$2"
    replaceTile "$i" $PATHS "$2"
    replaceTile "$i" $PATHE "$2"
    replaceTile "$i" $PATHW "$2"
    replaceTile "$i" $PATHNE "$2"
    replaceTile "$i" $PATHNW "$2"
    replaceTile "$i" $PATHSE "$2"
    replaceTile "$i" $PATHSW "$2"
  done
}
function makeDoors {
  # Function change NSEW tile to door - has issues

  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') GROW DOORS" >>log.txt

  declare -n myref="$1" # name ref used to pass array as argument
  local arg2="$2"       # tile type to write

  for idx in "${myref[@]}"; do
    # [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')   @ $idx" >>log.txt

    # ALTERNATE - exaustive

    local -i randnumb=1

    while [[ $randnumb -le 8 ]]; do
      if [[ $randnumb == 1 ]]; then
        tileTest "$idx" $PATHN 2 $TILE_WOODS && replaceTile "$idx" $PATHN "$2" && break
      elif [[ $randnumb == 2 ]]; then
        tileTest "$idx" $PATHS 2 $TILE_WOODS && replaceTile "$idx" $PATHS "$2" && break
      elif [[ $randnumb == 3 ]]; then
        tileTest "$idx" $PATHE 2 $TILE_WOODS && replaceTile "$idx" $PATHE "$2" && break
      elif [[ $randnumb == 4 ]]; then
        tileTest "$idx" $PATHW 2 $TILE_WOODS && replaceTile "$idx" $PATHW "$2" && break
      elif [[ $randnumb == 5 ]]; then
        tileTest "$idx" $PATHNE 2 $TILE_WOODS && replaceTile "$idx" $PATHNE "$2" && break
      elif [[ $randnumb == 6 ]]; then
        tileTest "$idx" $PATHNW 2 $TILE_WOODS && replaceTile "$idx" $PATHNW "$2" && break
      elif [[ $randnumb == 7 ]]; then
        tileTest "$idx" $PATHSE 2 $TILE_WOODS && replaceTile "$idx" $PATHSE "$2" && break
      elif [[ $randnumb == 8 ]]; then
        tileTest "$idx" $PATHSW 2 $TILE_WOODS && replaceTile "$idx" $PATHSW "$2" && break
      fi
      ((randnumb++))
    done

  done
}
function replaceTile {
  # Function to update a tile using index, tile, compass direction.

  # [[ "$DBUG" == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') REPLACE TILE ($1, $2, $3)" >>log.txt

  local -i arg1=$1   # index
  local -i arg2="$2" # compass direction
  local arg3=$3      # tile
  local -i new_index # math

  # calc new index & set
  new_index=$(($1 + $2))
  tile_map[new_index]=$3

}
function tileTest {
  # Function to test a tile at absolute position + direction + tiles
  # [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')   TILE TEST: ${tile_map[(($1 + $2 * $3))]} = $4 ???" >>log.txt

  local -i arg1="$1" # index
  local -i arg2="$2" # index direction
  local -i arg3="$3" # index offset
  local -i offset=$(($1 + $2 * $3))

  # test if true
  [[ "${tile_map[offset]}" == "$4" ]] && return 0

  # [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')     test: fail" >>log.txt

  return 1

}

# DISPLAY
function drawScreen {
  # Function to draw-print a square array line-by-line, row-by-by
  # [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')   DRAW SCREEN" >>log.txt

  local -n arg1=$1  # array to draw
  local -i arg2=$2  # $DIMS
  local -i lineBr=0 # array index

  clear

  #  draw each line
  for point in "${arg1[@]}"; do
    ((lineBr++))
    echo -n "$point"
    [[ "$lineBr" -ge $2 ]] && lineBr=0 && echo
  done
}
function drawConsole {
  # Function to draw text below game area

  if [[ $DBUG == on ]]; then
    echo
    echo "🕰️: $gametime"
    echo "$hmn_last_icon @ $hmn_idx @ ($((hmn_idx % DIMS)),$((hmn_idx / DIMS)))"
    echo
  fi

  # console message
  echo "$message1"

  # idle text
  [[ "${tile_map[hmn_idx]}" == "$TILE_WOODS" ]] && message1="The woods are scary at night."
  [[ "${tile_map[hmn_idx]}" == "$TILE_CABIN" ]] && message1="The cabin feels safer."
  [[ "${tile_map[hmn_idx]}" == "$TILE_DOOR" ]] && message1="Get inside!"
  [[ "${tile_map[hmn_idx]}" == "$TILE_FIELD" ]] && message1="The clearing feels unsafe."

}
function drawWindow {
  # Function to draw a small window of map.
  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') DRAW WINDOW" >>"log.txt"

  # re-calc - allows viewport +/- in-game
  VIEWRAD="$(((VIEWSIZE - 1) / 2))"
  [[ VIEWSIZE -gt DIMS ]] && ((VIEWSIZE -= 2))

  clear

  # get adjacent tiles; use grid principle; x = ones y = tens place

  # EXAMPLE: declare -a offsets=(-5 -4 -3 -2 -1 0 1 2 3 4 5)

  declare -a offsets=()
  declare -i new_offset
  declare -i lineBr

  # describe adjacent tiles in loop; save them in a list of 'offsets'
  declare -i lower_bound=$((VIEWRAD * -1))

  for ((i = 0; i < VIEWSIZE; i++)); do
    offsets+=("$lower_bound")
    ((lower_bound++))
  done

  # for each row
  for yoff in "${offsets[@]}"; do

    # line break to draw by column / row
    lineBr=0

    # for each column
    for xoff in "${offsets[@]}"; do
      ((lineBr++))

      # calc index location via grid principle; x = x and y = (Y * COLUMN)
      new_offset=$((xoff + (yoff * DIMS) + hmn_idx))

      # draw at index
      echo -n "${framebuffer[new_offset]}"

    done

    # next row
    lineBr=0 && echo

  done

}

# MENUS
function debugMenu {
  local select
  clear
  echo "DEBUG MENU"
  echo "  $TILE_HUMAN @ $hmn_idx @ ($((hmn_idx % DIMS)),$((hmn_idx / DIMS)))" # DBUG location / value
  echo "SYSTEM"
  echo "  VIEWSIZE (RAD): $VIEWSIZE ($VIEWRAD)"
  echo
  echo "WORKING DIR"
  echo "  $PWD"
  echo
  echo "Data Views"
  echo "  [1] - framebuffer - keys"
  echo "  [2] - framebuffer - values"
  echo "  [3] - tile map - values"
  echo "  [4] - RESUME"
  echo "  [5] - RESTART"
  read -rsn1 select

  # show

  [[ $select == 1 ]] && debugDump framebuffer key DIMS
  [[ $select == 2 ]] && debugDump framebuffer value DIMS
  [[ $select == 3 ]] && debugDump tile_map value DIMS file
  [[ $select == 4 ]] && return
  [[ $select == 5 ]] && startMenu

}
function debugDump {
  # Function to show array keys & values in columns

  # arguments
  declare -n arg1="$1" # array to dump
  declare arg2="$2"    # print key or value
  declare arg3="$3"    # DIMS for columns
  declare arg4="$4"    # file output switch
  declare -i lineBr=0  # line break

  # vars to dump to disk
  local datetime
  local filename
  datetime=$(date +"%Y-%m-%d %H:%M:%S")
  filename="${datetime//\:/}"

  clear

  for akey in "${!arg1[@]}"; do
    ((lineBr++))

    # show keys or values
    [[ $2 == 'key' ]] && printf "%03d " "$akey"
    [[ $2 == 'value' ]] && echo -n "${arg1[$akey]} "

    # dump to text file
    if [[ $4 == 'file' ]]; then

      # write value
      echo -n "${arg1[$akey]}" >>"$filename.log"

      # write break
      [[ $lineBr -eq $3 ]] && echo >>"$filename.log"

    fi
    # line break on DIMS
    [[ $lineBr -eq $3 ]] && lineBr=0 && echo

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

  local var1
  read -rsn1 var1
  [[ $var1 == g ]] && startGame
  [[ $var1 == 1 ]] && debugMenu
  [[ $var1 == q ]] && exit
  startMenu
}
function gOverMenu {
  local lineBr=0
  clear
  echo
  echo
  for _ in {1..10}; do
    ((lineBr++))
    echo -n "    🪦    "
    [[ $lineBr -ge 5 ]] && lineBr=0 && echo && echo
  done

  echo && echo
  printf "         💀   ${RED}G A M E   O V E R${OFF}   $tile_loss"
  echo && echo && echo

  lineBr=0
  for _ in {1..10}; do
    ((lineBr++))
    echo -n "    🪦    "
    [[ $lineBr -ge 5 ]] && lineBr=0 && echo && echo
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

  local -i ax ay

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

# EVENT FUNCTIONS
function isGameOver {
  # Function to test if game over
  # [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')   IS GAME OVER" >>"log.txt"

  # if player tile = enemy tile
  [[ $hmn_last_icon == "$TILE_WOLF" ]] && tile_loss=$TILE_WOLF && dieMovie
  [[ $hmn_last_icon == "$TILE_KNIFE" ]] && tile_loss=$TILE_KNIFE && dieMovie

  # if player moves onto tile...
  [[ ${tile_map[hmn_idx]} == "$TILE_EXIT" ]] && echo "YOU ESCAPED" && sleep 1 && startMenu
  [[ ${tile_map[hmn_idx]} == "$TILE_LAKE" ]] && echo "YOU DROWNED" && sleep 1 && tile_loss=$TILE_LAKE && dieMovie

}

# ACTION FUNCTIONSa
function moveTeleport {
  # Function to move NPC randomly

  local -n mover="$1" # get ref
  local -i new_idx=0  # set new
  local -i old_idx=0  # save old

  # randomize location
  new_idx=$((RANDOM % (DIMS * DIMS)))

  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')     moveTeleport: ${mover[icon]} #${mover[id]} @ ${mover[indx]} -> ${tile_map[new_idx]} ($new_idx) " >>log.txt

  if [[ ${framebuffer[new_idx]} == "$TILE_WOODS" ]]; then
    mover[indx]=$new_idx
  else
    moveTeleport "$1"
  fi

}
function makeKnife {
  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') makeKnife: $TILE_KNIFE" >>"log.txt"

  local -i hunter_id=0
  local -i random # random

  # each hunter is stored in a -a array (knife_list)

  while [[ $hunter_id -lt $1 ]]; do

    # create hunter's array name & set
    local varname="hunter${hunter_id}"
    declare -A -g $varname

    # set attributes
    random=$((RANDOM % (DIMS * DIMS)))

    # keep in bounds
    while [[ ${tile_map[random]} != "$TILE_WOODS" ]]; do
      random=$((RANDOM % (DIMS * DIMS)))
    done

    # should replace with a nameref
    eval "$varname[indx]=$random"
    eval "$varname[icon]=$TILE_KNIFE"
    eval "$varname[tele]=0"
    eval "$varname[id]=$hunter_id"

    # add entity's array to list
    knife_list[hunter_id]="hunter${hunter_id}"

    ((hunter_id++))
  done

}
function makeWolf {
  # Function to make array-managed entity
  # [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') makeWolf: $TILE_WOLF" >>"log.txt"

  local -i wolf_id=0
  local -i random # random

  # each wolf is an -A array stored in an -a array (wolflist)

  while [[ $wolf_id -lt $1 ]]; do

    # create wolf's array name & set
    local varname="wolf${wolf_id}"
    declare -A -g $varname

    # set attributes
    random=$((RANDOM % (DIMS * DIMS)))

    # keep in bounds
    while [[ ${tile_map[random]} != "$TILE_WOODS" ]]; do
      random=$((RANDOM % (DIMS * DIMS)))
    done

    eval "$varname[indx]=$random"
    eval "$varname[icon]=$TILE_WOLF"
    eval "$varname[id]=$wolf_id"

    # add entity's array to wolflist
    wolflist[wolf_id]="wolf${wolf_id}"

    ((wolf_id++))
  done

  # DEBUG
  # for each in "${!wolflist[@]}"; do
  #   local -n tnameref=${wolflist[each]}
  #   [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')   madeloop: $TILE_WOLF ${tnameref[id]} @ ${tnameref[indx]}" >>log.txt
  # done

}
function moveWolf {
  # Function to manipulate each array in a list of arrays

  local -n array_name_list=$1
  local -i last_pos=0
  local -i random=0

  # for each array in array
  for eachitem in "${array_name_list[@]}"; do

    # use nameref to access array
    local -n mover=$eachitem

    # save last position
    last_pos="${mover[indx]}"

    # determine movement
    random=$((RANDOM % 5))
    [[ $random == 0 ]] # no move
    [[ $random == 1 ]] && ((mover[indx]++))
    [[ $random == 2 ]] && ((mover[indx]--))
    [[ $random == 3 ]] && ((mover[indx] += DIMS))
    [[ $random == 4 ]] && ((mover[indx] -= DIMS))

    # keep in bounds & safe tile
    [[ ${mover[indx]} -ge $((DIMS * DIMS)) ]] && mover[indx]=$last_pos
    [[ ${mover[indx]} -lt 0 ]] && mover[indx]=$last_pos
    ! [[ ${framebuffer[${mover[indx]}]} == "$TILE_WOODS" ]] && mover[indx]=$last_pos

    # reset last tile if movement
    [[ $last_pos != "${mover[indx]}" ]] && framebuffer[last_pos]=${tile_map[last_pos]}

    # draw item on framebuffer
    framebuffer[mover[indx]]=${mover[icon]}

    # [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')     $TILE_WOLF ${mover[id]} @ $last_pos -> ${mover[indx]}:${tile_map[mover[indx]]}" >>"log.txt"

  done

}
function moveKnife {
  # Function to move item in ARG1 (array) toward ARG2 (index)

  # use nameref to access array
  local -n array_name_list=$1

  # for each array in array
  for eachitem in "${array_name_list[@]}"; do

    # use nameref to access array
    local -n mover=$eachitem

    # save last position
    local last_pos="${mover[indx]}"

    # determine movement
    [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')   moveKnife: ${mover[icon]} #${mover[id]}:${mover[indx]} -> T:$2" >>"log.txt"

    # convert indices to x,y for comparison
    local -i mover_new_idx=0
    local -i mover_x=$((mover[indx] % DIMS))
    local -i mover_y=$((mover[indx] / DIMS))
    local -i tar_x=$(($2 % DIMS))
    local -i tar_y=$(($2 / DIMS))
    local -i init_i=${mover[indx]}
    local -i init_x=$((mover[indx] % DIMS)) # readability
    local -i init_y=$((mover[indx] / DIMS)) # readability

    # mover horizontal movement; convert to index
    [[ "$mover_x" -lt "$tar_x" ]] && ((mover_x++))
    [[ "$mover_x" -gt "$tar_x" ]] && ((mover_x--))
    mover_new_idx=$((mover_y * DIMS + mover_x))

    # mover horizontal movement - stop entry into some tiles
    if ! [[ "${tile_map[mover_new_idx]}" == "$TILE_CABIN" ]]; then
      # approve movement
      mover[indx]=$mover_new_idx
    else
      # revert x movement
      mover_x=$init_x
      mover_new_idx=$((mover_y * DIMS + mover_x))
    fi

    # mover vertical movement; convert to index
    [[ "$mover_y" -lt "$tar_y" ]] && ((mover_y++))
    [[ "$mover_y" -gt "$tar_y" ]] && ((mover_y--))
    mover_new_idx=$((mover_y * DIMS + mover_x))

    # mover vertical movement - stop entry into some tiles
    if ! [[ "${tile_map[mover_new_idx]}" == "$TILE_CABIN" ]]; then
      # approve move
      mover[indx]=$mover_new_idx
    else
      # revert y movement
      mover_y=$init_y
      mover_new_idx=$((mover_y * DIMS + mover_x))
    fi

    # teleport when stuck
    [[ $init_i == "$mover_new_idx" ]] && ((mover[tele]++))
    [[ ${mover[tele]} -gt 3 ]] && mover[tele]=0 && moveTeleport "$eachitem"

    # reset last tile if movement
    [[ $last_pos != "${mover[indx]}" ]] && framebuffer[last_pos]=${tile_map[last_pos]}

    # draw item on framebuffer
    framebuffer[mover[indx]]=${mover[icon]}

    [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')     moveKnife: ${mover[icon]} #${mover[id]} @ (${init_i}:${tile_map[init_i]}) -> ${mover[indx]}:${tile_map[mover[indx]]} ${mover[tele]}" >>"log.txt"

  done

}

# PLAYER MOVEMENT
function movePlayer {
  # Function to move player to new tile; test new tile; revert or approve move

  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')   MOVE PLAYER ($hmn_idx)" >>log.txt

  # wait for any input key
  read -rsn1 -t${GAMESPEED} keypress

  # directional movement - grid logic
  [[ $keypress == s ]] && ((hmn_idx += DIMS))
  [[ $keypress == w ]] && ((hmn_idx -= DIMS))
  [[ $keypress == a ]] && ((hmn_idx -= 1))
  [[ $keypress == d ]] && ((hmn_idx += 1))
  [[ $keypress == m ]] && drawScreen tile_map && read -rsn1
  [[ $keypress == 0 ]] && debugMenu
  [[ $keypress == '-' ]] && ((VIEWSIZE -= 2))
  [[ $keypress == '=' ]] && ((VIEWSIZE += 2))

  [[ -z $keypress ]] && return

  # player can't enter some tiles
  moveDeny "$TILE_TREES" "$keypress" "$hmn_last_icon" # can't enter tree
  moveDeny "$TILE_CABIN" "$keypress" "$hmn_last_icon" # can't enter cabin
  moveDeny "$TILE_WOODS" "$keypress" "$hmn_last_icon" # can't enter woods from cabin
  moveDeny "$TILE_KNIFE" "$keypress" "$hmn_last_icon" # can't enter enemy
  moveDeny "$TILE_FIELD" "$keypress" "$hmn_last_icon" # can't enter field from cabin
  moveDeny "$TILE_WOLF" "$keypress" "$hmn_last_icon"  # can't enter field from cabin

}
function moveDeny {
  # Function to deny illegal movement; reverts position

  # arg 1 illegal tile to test
  # arg 2 movement direction for reversion
  # arg 3 last approved tile index

  # if movement is to denied tile type, undo movement
  if [[ ${framebuffer[hmn_idx]} == "$1" ]]; then # if destination = bad tile

    # UNESS... - EXCEPTION LIST - allow entry TO some tiles FROM others:

    # DEBUG
    [[ "$3" == "$TILE_KNIFE" ]] && [[ $1 == "$TILE_WOODS" ]] && return # for debugging

    # ...from cabin to
    [[ "$3" == "$TILE_CABIN" ]] && [[ $1 == "$TILE_CABIN" ]] && return

    # ...from doors to
    [[ "$3" == "$TILE_DOOR" ]] && [[ $1 == "$TILE_WOODS" ]] && return
    [[ "$3" == "$TILE_DOOR" ]] && [[ $1 == "$TILE_CABIN" ]] && return
    [[ "$3" == "$TILE_DOOR" ]] && [[ $1 == "$TILE_FIELD" ]] && return

    # ...from woods to
    [[ "$3" == "$TILE_WOODS" ]] && [[ $1 == "$TILE_WOODS" ]] && return
    [[ "$3" == "$TILE_WOODS" ]] && [[ $1 == "$TILE_FIELD" ]] && return
    [[ "$3" == "$TILE_WOODS" ]] && [[ $1 == "$TILE_WOLF" ]] && return

    # ...from fields to
    [[ "$3" == "$TILE_FIELD" ]] && [[ $1 == "$TILE_WOODS" ]] && return

    # debug
    [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')   DENY MOVE [$2]: $3 -> $1 ?" >>log.txt
    [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//')     to: $3 -> ${framebuffer[$hmn_idx]}" >>log.txt

    # revert movement
    [[ "$2" == "w" ]] && ((hmn_idx += DIMS))
    [[ "$2" == "s" ]] && ((hmn_idx -= DIMS))
    [[ "$2" == "d" ]] && ((hmn_idx -= 1))
    [[ "$2" == "a" ]] && ((hmn_idx += 1))

    # send message based on tile
    [[ $1 == "$TILE_TREES" ]] && message1="There's a huge tree!"
    [[ $1 == "$TILE_CABIN" ]] && message1="There's no way in!"
    [[ $1 == "$TILE_WOODS" ]] && message1="There's no way out!"

  fi

}
function mainLoop {

  local keypress

  while ! [[ $keypress == "q" ]]; do

    [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') MAIN LOOP (#$gametime)" >>log.txt

    ((gametime++))

    # save movers tiles' init emoji value
    declare -g hmn_last_icon=${framebuffer[hmn_idx]}

    # save initial value of index location
    declare -g hmn_last_idx=$hmn_idx

    # put moving items into framebuffer
    framebuffer[hmn_idx]="$TILE_HUMAN"

    # draw display
    # drawScreen framebuffer DIMS # to draw entire map each frame
    drawWindow # to draw view area
    drawConsole

    # test events
    isGameOver

    # move objects
    movePlayer
    moveKnife knife_list "$hmn_idx"
    moveWolf wolflist

    # UPDATE FRAMEBUFFER INCREMENTALLY - replace previous tile
    framebuffer[hmn_last_idx]=$hmn_last_icon # revert player's last tile at index

  done
}

# GAME LOOP
function startGame {
  # Function to launch main game
  [[ $DBUG == on ]] && echo "$(gdate +"%H:%M:%S.%N" | sed 's/000//') START GAME" >>log.txt

  # set global game vars
  initGameVars

  # make map
  makeCamp DIMS                        # generate map
  expand3x3 tilelist_cabin $TILE_CABIN # grow tiles to 3x3
  makeDoors tilelist_cabin $TILE_DOOR  # make doors
  expand3x3 tilelist_water $TILE_LAKE  # grow tiles to 3x3

  # make framebuffer from tile map
  framebuffer=("${tile_map[@]}")

  # make player @ bottom-left tile, inside border

  hmn_idx=$((DIMS * DIMS - VIEWRAD * DIMS + VIEWRAD - DIMS))

  # make enemies
  makeWolf 10
  makeKnife 20

  # go
  mainLoop

  # unset database
  unset gametime keypress framebuffer tile_map clock

}

################################################################################
# EXECUTION
################################################################################

# show debug
DBUG=on

# hide cursor
tput civis

initConstants

# auto-launch
startGame

# start main menu
# startMenu

# show cursor
tput cnorm

clear
cat log.txt
