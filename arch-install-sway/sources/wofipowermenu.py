#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os

def run_menu():
  keys = (
    "\uf023   Log Out",
    "\uf186   Suspend",
    "\uf2dc   Hibernate",
    "\uf021   Reboot",
    "\uf011   Shutdown",
  )

  actions = (
    "swaymsg exit",
    "systemctl suspend",
    "systemctl hibernate",
    "systemctl reboot",
    "systemctl poweroff"
  )

  options = "\n".join(keys)
  choice = os.popen("echo -e '" + options + "' | wofi --dmenu --insensitive --prompt 'Power Menu' --style /etc/wofi/styles.css --width 200 --height 175 --cache-file /dev/null").readline().strip()
  if choice in keys:
    os.popen(actions[keys.index(choice)])

run_menu()