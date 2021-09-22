#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import json

def handle_dualhead(one, two):
  print("Dual head active")

def handle_internal(internal):
  print("Internal only")
  

def handle_external(external):
  print("External only")

def get_output(outputs, name):
  for output in outputs:
    if output["name"] == name and output["active"]:
      return output
  return None

def detect_screens():
  outputs_json = "".join(os.popen("swaymsg -r -t get_outputs").readlines())
  outputs = json.loads(outputs_json)
  internal_screen = get_output(outputs, "eDP-1")
  external_screen = get_output(outputs, "DP-1")
  if internal_screen and external_screen:
    return handle_dualhead(internal_screen, external_screen)

  if internal_screen:
    return handle_internal(internal_screen)
  
  if external_screen:
    return handle_external(external_screen)
  
  print("No known screens")


detect_screens()