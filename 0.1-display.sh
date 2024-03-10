#!/bin/bash

function drawScreen {
  # Function to draw display data to screen

  clear

  # line counter
  local -i line=0

  for _ in {1..100}; do
    ((line++))

    echo -n "🌲"

    #  new line & reset line counter
    [[ $line -eq 10 ]] && echo && line=0

  done

}

drawScreen
