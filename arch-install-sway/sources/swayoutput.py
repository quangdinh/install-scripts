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

def get_all_outputs():
  outputs_json = "".join(os.popen("swaymsg -r -t get_outputs").readlines())
  outputs = json.loads(outputs_json)
  return outputs

def get_outputs(name):
  output = get_output(get_all_outputs(), name)

  if output:
    return True, output["active"]

  return False, False

def print_usage():
  print("Usage: sway_output.py [name] [on/off/toggle]")


def auto_outputs(output_with_lid):
  outputs = get_all_outputs()
  if len(outputs) == 1:
    os.system("swaymsg output " + outputs[0]["name"] + " enable")
    sys.exit(0)
  
  for output in outputs:
    name = output["name"]
    action = "enable"
    if output_with_lid == name:
      lid_state = os.popen("cat /proc/acpi/button/lid/*/state | grep -o 'closed\|open'").readline().strip()
      action = "disable" if lid_state == "closed" else "enable"

    os.system("swaymsg output " + name + " " + action)


if len(sys.argv) >= 2 and sys.argv[1] == "auto":
  output_with_lid = sys.argv[2] if len(sys.argv) >= 3 else None
  auto_outputs(output_with_lid)
  sys.exit(0)

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
  print("Output "" + output + "" is not valid")
  sys.exit(0)

if command == "on":
  action = "enable"
if command == "off":
  action = "disable"
if command == "toggle":
  action = "disable" if active else "enable"

print("Turning " + ("on" if action == "enable" else "off") + " output " + output)
os.system("swaymsg output " +  output + " " +  action)
