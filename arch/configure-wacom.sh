#!/usr/bin/env sh

for i in $(seq 10); do
    if xsetwacom list devices | grep -q Wacom; then
        break
    fi
    sleep 1
done

touch_device=$(xsetwacom list | egrep -ohm1 "(.*)touch")
stylus_device=$(xsetwacom list | egrep -ohm1 "(.*)stylus")

xsetwacom --set "$touch_device" touch off
xsetwacom --set "$stylus_device" Button 3 "pan"
xsetwacom --set "$stylus_device" Button 2 "Button 3"
xsetwacom --set "$stylus_device" "PanScrollThreshold" 200