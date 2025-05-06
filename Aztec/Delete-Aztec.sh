#!/bin/bash

function printGreen {
  echo -e "\e[1m\e[32m${1}\e[0m"
}

function logo() {
  bash <(curl -s https://raw.githubusercontent.com/CPITMschool/Scripts/main/logo.sh)
}

function delete() {
docker stop aztec-sequencer && docker rm aztec-sequencer
    rm -rf "$HOME/aztec-sequencer"
}

logo
delete

printGreen "Aztec node видалено"
