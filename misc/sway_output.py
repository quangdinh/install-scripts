#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import json
import sys

def get_output(outputs, name):
  for output in outputs:
    if output["name"] == name:
      return output
  return None

def get_outputs(name):
  outputs_json = "".join(os.popen("swaymsg -r -t get_outputs").readlines())
  outputs = json.loads(outputs_json)
  output = get_output(outputs, name)

  if output:
    return True, output["active"]

  return False, False

def print_usage():
  print("Usage: sway_output.py [name] [on/off/toggle]")

if len(sys.argv) != 3:
  print_usage()
  sys.exit(0)


output = sys.argv[1]
command = sys.argv[2].lower()

if command != "on" and command != "off" and command != "toggle":
  print_usage()
  sys.exit(0)


(valid, active) = get_outputs(output)

if not valid:
  print("Output \"" + output + "\" is not valid")
  sys.exit(0)

if command == "on":
  action = "enable"
if command == "off":
  action = "disable"
if command == "toggle":
  action = "disable" if active else "enable"

print("Turning " + ("on" if action == "enable" else "off") + " output " + output)
os.system("swaymsg output " +  output + " " +  action)

