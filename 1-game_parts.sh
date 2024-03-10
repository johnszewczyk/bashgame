#!/bin/bash
function init {
  declare -g keystroke=0
  declare -g -i p_index=$((gamesize * gamesize / 2))
  declare -g -i old_index=$p_index

  #  map vars
  declare -g -i gamesize=10
  declare -g -a game_map=()

  #  tile vars
  declare -g -r TILE1=🌲 # empty
  declare -g -r TILE2=🏃 # cursor

}

function drawScreen {
  # Function to draw display data to screen

  # line break var
  local -i line=0

  clear

  # draw array of screen
  for each in "${game_map[@]}"; do
    ((line++))
    echo -n "$each "

    [[ $line -ge "$gamesize" ]] && echo && line=0

  done

  # draw extra data
  echo
  echo "Player index: $p_index of ${#game_map[@]}"

}

function takeInput {
  # Function to poll for keyboar input

  # save old position
  declare -g old_index=$p_index

  local -i offset=0

  # hint
  echo
  echo "Use A S D W to move around. Q to quit."

  # take input
  read -rsn1 -t1 keystroke

  [[ $keystroke == "w" ]] && ((offset -= gamesize)) # directional movement north
  [[ $keystroke == "a" ]] && ((offset -= 1))        # directional movement west
  [[ $keystroke == "s" ]] && ((offset += gamesize)) # directional movement south
  [[ $keystroke == "d" ]] && ((offset += 1))        # directional movement east

  # keep in bounds
  [[ $p_index -gt $((gamesize * gamesize - 1)) ]] && offset=$((gamesize * gamesize))
  [[ $p_index -lt 0 ]] && offset=0

  # set new position
  ((p_index += offset))

}

function updateScreen {
  #  Function to update display data after movement

  # set old location
  game_map[old_index]=$TILE1

  # set new location
  game_map[p_index]=$TILE2

}

function makeGame {
  # Function to populate array used as "framebuffer" or display

  for ((i = 0; i < $((gamesize * gamesize)); i++)); do
    game_map+=("$TILE1")
  done

}

function startGame {
  # Function to run game main loop

  while ! [[ $keystroke == "q" ]]; do

    # write changes to display
    updateScreen

    # draw screen
    drawScreen

    # take input
    takeInput

  done

  # end game
  clear
  echo "GAME OVER"
  sleep 1
}

#  hide cursor
tput civis

# initialize
init

# make map
makeGame

# start main loop
startGame

# clean up
tput cnorm
