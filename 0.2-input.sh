#!/bin/bash

function movePlayer() {
  # Function to translate keyboard into directional movement

  local -i x=0
  local -i y=0
  local -i time=0
  local keystroke

  while [[ $keystroke != q ]]; do

    clear
    ((time++))

    # info
    echo "Move with WSAD."
    echo "  x value: $x"
    echo "  y value: $y"
    echo "  t value: $time"

    # wait for any input key
    read -rsn1 -t1 keystroke

    [[ $keystroke == "w" ]] && ((y = y + 1)) # directional movement north
    [[ $keystroke == "a" ]] && ((x = x - 1)) # directional movement west
    [[ $keystroke == "s" ]] && ((y = y - 1)) # directional movement south
    [[ $keystroke == "d" ]] && ((x = x + 1)) # directional movement east

  done

}

movePlayer
