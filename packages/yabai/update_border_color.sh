#!/usr/bin/env bash

n=$(yabai -m query --spaces --space | jq '.windows | length')
if [ $n = 1 ]; then
    borders active_color=0x00000000
else
    borders active_color=0xffcccccc
fi