#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import getpass
import os
import json
import signal
import sys
import subprocess
import re
import time

def clear():
  os.system("clear")

def signal_handler(sig, frame):
    print('')
    print('Cancelled')
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

def add_gnome_keyring():
  file = "/etc/pam.d/login"
  with open(file, "r") as f:
    lines = f.readlines()
    newLines = []
    for line in lines:
      line = line.strip()
      if "pam_gnome_keyring.so" in line:
        return
      if line.startswith("account"):
        newLines.append("auth       optional     pam_gnome_keyring.so")
      if line.startswith("password"):
        newLines.append("session    optional     pam_gnome_keyring.so auto_start")
      newLines.append(line)
  with open(file, "w") as f:
    out = "\n".join(newLines)
    f.write(out)
  file = "/etc/pam.d/passwd"
  with open(file, "a") as f:
    f.write("password	optional	pam_gnome_keyring.so\n")

def run_command(*args):
  cmd = " ".join(args)
  r = os.WEXITSTATUS(os.system("sh -c '" + cmd + "'"))
  if r != 0:
    print("\n\nError running:", cmd)
    sys.exit(0)

run_command("/usr/bin/pacman", "-S", "--noconfirm", "gnome-keyring")
add_gnome_keyring()
