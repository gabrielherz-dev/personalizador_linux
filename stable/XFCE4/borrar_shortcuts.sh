#!/bin/bash
for key in $(xfconf-query -c xfce4-keyboard-shortcuts -l | grep '^/xfwm4/custom/'); do
    xfconf-query -c xfce4-keyboard-shortcuts -p "$key" -r
done

