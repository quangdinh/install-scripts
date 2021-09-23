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
  file = "/mnt/etc/pam.d/login"
  with open(file, "r") as f:
    lines = f.readlines()
    newLines = []
    for line in lines:
      line = line.strip()
      if "pam_gnome_keyring.so" in line:
        return
      if line.startswith("account"):
        newLines.append("auth	   optional     pam_gnome_keyring.so")
      newLines.append(line)
      if line.startswith("password"):
        newLines.append("session    optional     pam_gnome_keyring.so auto_start")
  with open(file, "w") as f:
    out = "\n".join(newLines)
    f.write(out)
  file = "/mnt/etc/pam.d/passwd"
  with open(file, "a") as f:
    f.write("password   optional    pam_gnome_keyring.so\n")


def request_input(prompt):
  r = input(prompt)
  return r.strip()

def request_input_secured(prompt):
  p = getpass.getpass(prompt=prompt)
  return p.strip()

def get_disk_info(disk):
  lines = os.popen('lsblk ' + disk + " -J 2> /dev/null").readlines()
  js = "".join(lines)
  o = json.loads(js)
  devices = o["blockdevices"]
  if len(devices) != 1:
    return {}, False
  return devices[0], True

def list_disk():
  clear()
  disks = "".join(os.popen('lsblk -J 2> /dev/null').readlines())
  valid_disks = []
  js = json.loads(disks)
  devices = js["blockdevices"]
  print("Disks found on your system")
  print("{:<2} {:<20} {:<10}".format("No", "Device", "Size"))
  for dev in devices:
    if dev["type"] == "disk" or dev["type"] == "loop":
      valid_disks.append(dev)
      print("{:<2} {:<20} {:<10}".format(len(valid_disks), "/dev/" + dev["name"], dev["size"]))

  print("x  Don't partition, I have already mounted everything at /mnt and will install bootloader myself")
  print()
  return valid_disks

def check_disk_input(valid_disks, disk_no):
  if disk_no.lower() == "x":
    return True

  ok = True
  if not disk_no.isnumeric():
    ok = False
  else:
    disk_num = int(disk_no) - 1
    if disk_num < 0 or disk_num >= len(valid_disks):
      ok = False
  return ok

def get_install_disk():
  valid_disks = list_disk()
  if len(valid_disks) == 0:
    print("No disk found")
    sys.exit(0)

  disk = valid_disks[0]
  ok = True
  if len(valid_disks) > 0:
    disk_no = request_input("Enter option [x]: ")
    if disk_no == "":
      return "None"
    ok = check_disk_input(valid_disks, disk_no)
    while not ok:
      list_disk()
      print(disk_no, "is not a valid disk")
      disk_no = request_input("Enter option [x]: ")
      ok = check_disk_input(valid_disks, disk_no)

  if disk_no.lower() == "x":
    return "None"

  disk = valid_disks[int(disk_no) - 1]
  if "children" in disk:
    children = disk["children"]
    if len(children) > 0:
      confirm = request_input("/dev/" + disk["name"] + " contains partitions. ALL DATA WILL BE ERASED!\nAre you sure to use this disk? Type 'YES' to confirm: ")
      if confirm != "YES":
        print("Exiting")
        sys.exit(0)
  
  return "/dev/" + disk["name"]

def string_bool(b):
  if b:
    return "Yes"
  return "No"

def ask_username():
  u = request_input("Username: ")
  if re.match(r'^[a-z_][a-z0-9_-]*\$?$', u) and len(u) <= 32:
    return u
  print("Invalid username")
  return ask_username()

def ask_filesystem():
  fs = request_input("Choose filesystem ([ext4], btrfs, xfs): ")
  if fs.lower() == "btrfs" or fs.lower() == "xfs" or fs.lower() == "" or fs.lower() == "ext4":
    return fs
  print("Invalid option\n")
  return ask_filesystem()

def ask_use_encryption():
  encrypt = request_input("Do you want to use encryption? Yes/[No] ")
  if encrypt.lower() == "yes" or encrypt.lower() == "y":
    return True
  return False

def ask_encryption_password():
  encrypt_password = request_input_secured("Enter encryption passphrase: ")
  if len(encrypt_password) < 8:
    print("Passphrase is too short. Please choose passphrase > 8 characters\n")
    return ask_encryption_password()
  encrypt_password_ver = request_input_secured("Re-enter encryption passphrase: ")
  if encrypt_password_ver != encrypt_password:
    print("Passphrase does not match\n")
    return ask_encryption_password()
  return encrypt_password

def ask_password():
  password = request_input_secured("Enter password: ")
  if len(password) < 8:
    print("Password is too short. Please choose password > 8 characters\n")
    return ask_password()
  password_ver = request_input_secured("Re-enter password: ")
  if password_ver != password:
    print("Password does not match\n")
    return ask_password()
  return password

def ask_timezone():
  t = request_input("Enter your timezone: ")
  if os.path.isfile('/usr/share/zoneinfo/' + t):
    return t
  else:
    print(t, "is not a valid timezone")
    print()
    return ask_timezone()

def ask_locale():
  l = request_input("Enter locales [en_US]: ")
  if l == "":
    l = "en_US"
  lc = l.split(",")
  locales = []
  for locale in lc:
    locales.append(locale.strip())
  print("Will generate the following locales")
  for locale in locales:
    print(locale + ".UTF8 UTF8")
    print(locale + " ISO-8859-1")
  confirm = request_input("Is this correct? [Yes]: ")
  if confirm.lower() == "yes" or confirm.lower() == "y" or confirm == "":
    return locales
  print()
  return ask_locale()

def detect_bluetooth():
  b = os.popen("lsusb | grep -om1 Bluetooth").readline().strip()
  return b == "Bluetooth"

def ask_hostname():
  h = request_input("Enter hostname [Arch]: ")
  if h.strip() == "":
    h = "Arch"
  return h

def ask_swap():
  mem_in_kb = 0
  with open('/proc/meminfo') as file:
    for line in file:
        if 'MemTotal' in line:
            mem_in_kb = line.split()[1]
            break
  if not mem_in_kb.isnumeric():
    mem_in_kb = 0
  mem_in_gb = int(int(mem_in_kb) / 1000000)
  mem = request_input("Enter amount of swap in GiB [" + str(mem_in_gb * 2) + "]: ")
  
  if mem.strip() == "":
    return mem_in_gb * 2

  if mem.isnumeric():
    return mem
  print("Invalid swap amount")
  return ask_swap()

def detect_cpu():
  c = os.popen('cat /proc/cpuinfo | grep -o -m1 "AMD\|Intel"').readline().strip()
  if c == "AMD":
    return "AMD"
  if c == "Intel":
    return "Intel"
  return "None"

def run_command(*args):
  cmd = " ".join(args)
  r = os.WEXITSTATUS(os.system("sh -c '" + cmd + "' >> /mnt/install_log.txt 2>&1"))
  if r != 0:
    print("\n\nError running:", cmd)
    sys.exit(0)

def run_chrootuser(user, *args):
  cmd = " ".join(args)
  chroot_cmd = "/usr/bin/arch-chroot /mnt su " + user + " sh -c '" + cmd + "'"
  r = os.WEXITSTATUS(os.system(chroot_cmd + " >> /mnt/install_log.txt 2>&1"))
  if r != 0:
    print("\n\nError running:", chroot_cmd)
    sys.exit(0)

def run_chroot(*args):
  chroot_cmd = ["/usr/bin/arch-chroot", "/mnt", *args]
  cmd = " ".join(args)
  chroot_cmd = "/usr/bin/arch-chroot /mnt sh -c '" + cmd + "'"
  r = os.WEXITSTATUS(os.system(chroot_cmd + " >> /mnt/install_log.txt 2>&1"))
  if r != 0:
    print("\n\nError running:", chroot_cmd)
    sys.exit(0)

def print_task(task):
  print("{:<40}{:<1}".format(task, ": "), end='', flush=True)

def ask_zsh():
  zsh = request_input("Do you want to switch shell to ZSH? [Yes]/No ")
  if zsh.lower() == "yes" or zsh.lower() == "y" or zsh == "":
    return True
  return False

def parse_efi(efi_part):
  m = re.findall("p[0-9]+", efi_part)
  if len(m) > 0:
    part = m[-1]
    dev = efi_part[:len(efi_part)-len(m[-1])]
    part = part.replace("p", "")
  else:
    m = re.findall("[0-9]+", efi_part)
    if len(m) > 0:
      part = m[-1]
      dev = efi_part[:len(efi_part)-len(m[-1])]
    else:
      print("Unable to parse EFI partition")
      sys.exit(0)
  return dev, part

def ask_hide_grub():
  h = request_input("Do you want to hide Grub menu? [Yes]/No ")
  if h.lower() == "yes" or h.lower() == "y" or h == "":
    return True
  return False

def parse_hooks_encrypt_lvm(encrypt, plymouth):
  current_hooks = os.popen("cat /mnt/etc/mkinitcpio.conf | grep -oP '^HOOKS=(\(.*\))$'").readline().strip()
  objects = re.search('\((.*)\)', current_hooks)
  hooks = []
  if objects:
    hooks = objects.group(1).split(' ')
  results = []
  keyboardHook = "autodetect"
  if keyboardHook not in current_hooks:
    keyboardHook = "udev"

  for hook in hooks:
    if hook == "udev" and hook != keyboardHook:
      if plymouth:
        results.append("udev")
        results.append("plymouth")
        if encrypt:
          results.append("plymouth-encrypt")
        continue

    if hook == keyboardHook:
      results.append(hook)
      results.append("keyboard")
      if plymouth and hook == "udev":
        results.append("plymouth")
        if encrypt:
          results.append("plymouth-encrypt")
      continue

    if hook == "keyboard" or hook == "encrypt" or hook == "plymouth" or hook == "plymouth-encrypt" or hook == "lvm2":
      continue

    if hook == "filesystems":
      if encrypt:
        if not plymouth:
          results.append("encrypt")
        results.append("lvm2")
      results.append("resume")
      results.append(hook)
      continue

    results.append(hook)
    
  return " ".join(results)

def detect_vga():
  vga = os.popen("lspci -v | grep -A1 -e VGA -e 3D | grep -o -m1 'NVIDIA\|Intel\|AMD\|ATI\|Radeon'").readline().strip()
  if vga == "":
    return 'Generic'
  if vga == "AMD" or vga == "ATI" or vga == "Radeon":
    return "AMD"
  return vga

def get_crypt_uuid(disk):
  partition = os.popen('blkid ' + disk +'* | grep -oP \'/dev/[a-z0-9]*:.*PARTLABEL="cryptlvm"\' | grep -o \'/dev/[a-z0-9]*\'').readline().strip()
  if partition == "":
    print("Error! Cryptlvm not found")
    sys.exit(0)
  uuid = os.popen('lsblk -no uuid ' + partition + " | tail -n 1").readline().strip()
  return uuid

def get_swap_uuid(encrypt):
  if encrypt:
    partition = "/dev/mapper/VolGroup0-lvSwap"
  else:
    partition = os.popen('blkid ' + disk +'* | grep -oP \'/dev/[a-z0-9]*:.*PARTLABEL="swap"\' | grep -o \'/dev/[a-z0-9]*\'').readline().strip()
  
  if partition == "":
    print("Error! swap not found")
    sys.exit(0)
  uuid = os.popen('lsblk -no uuid ' + partition + " | tail -n 1").readline().strip()
  return uuid

def get_crypt_dev(disk):
  partition = os.popen('blkid ' + disk +'* | grep -oP \'/dev/[a-z0-9]*:.*PARTLABEL="cryptlvm"\' | grep -o \'/dev/[a-z0-9]*\'').readline().strip()
  if partition == "":
    print("Error! Cryptlvm not found")
    sys.exit(0)
  return partition

def get_root_uuid():
  uuid = os.popen("findmnt /mnt -o uuid | tail -n 1").readline().strip()
  return uuid

def get_cpu_code(cpu):
  if cpu == "Intel":
    return "initrd=/intel-ucode.img "
  if cpu == "AMD":
    return "initrd=/amd-ucode.img "
  return ""

def format_root(partition, fs):
  if fs == "btrfs":
    run_command("/usr/bin/mkfs.btrfs", "-L", "ArchRoot", partition)
  elif fs == "xfs":
    run_command("/usr/bin/mkfs.xfs", partition)
  else:
    run_command("/usr/bin/mkfs.ext4", partition)

def install_brightness():
  script = """
bindsym XF86MonBrightnessDown exec brightnessctl set 2%-
bindsym XF86MonBrightnessUp exec brightnessctl set +2%
"""
  directory = "/mnt/etc/sway/config.d"
  if not os.path.exists(directory):
    os.makedirs(directory)
  with open(directory+"/brightness.conf", "w") as f:
    f.write(script)

def install_screenshot():
  script = """
bindsym Print exec grim $(xdg-user-dir PICTURES)/$(date +'Screenshot_%Y-%m-%d_%H%M%S.png')
bindsym Alt+Print exec grim -g "$(swaymsg -t get_tree | jq -j '.. | select(.type?) | select(.focused).rect | "\(.x),\(.y) \(.width)x\(.height)"')" $(xdg-user-dir PICTURES)/$(date +'Screenshot_%Y-%m-%d_%H%M%S.png')
bindsym Shift+Print exec grim -g "$(slurp)" $(xdg-user-dir PICTURES)/$(date +'Screenshot_%Y-%m-%d_%H%M%S.png')

bindsym Control+Print exec grim - | wl-copy
bindsym Control+Alt+Print exec grim -g "$(swaymsg -t get_tree | jq -j '.. | select(.type?) | select(.focused).rect | "\(.x),\(.y) \(.width)x\(.height)"')" - | wl-copy
bindsym Control+Shift+Print exec grim -g "$(slurp)" - | wl-copy 
"""
  directory = "/mnt/etc/sway/config.d"
  if not os.path.exists(directory):
    os.makedirs(directory)
  with open(directory+"/screenshot.conf", "w") as f:
    f.write(script)

def install_audio():
  script = """
bindsym XF86AudioStop exec playerctl stop
bindsym XF86AudioPlay exec playerctl play-pause
bindsym XF86AudioNext exec playerctl next
bindsym XF86AudioPrev exec playerctl previous

bindsym XF86AudioRaiseVolume exec volumectl up
bindsym XF86AudioLowerVolume exec volumectl down
bindsym XF86AudioMute exec volumectl toggle
bindsym XF86AudioMicMute exec pactl set-source-mute @DEFAULT_SOURCE@ toggle
"""
  directory = "/mnt/etc/sway/config.d"
  if not os.path.exists(directory):
    os.makedirs(directory)
  with open(directory+"/audio.conf", "w") as f:
    f.write(script)

def install_powermenu():
  script = """#!/usr/bin/env python3
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

  options = "\\n".join(keys)
  choice = os.popen("echo -e '" + options + "' | wofi --dmenu --insensitive --prompt 'Power Menu' --style /etc/wofi/styles.css --width 200 --height 175 --cache-file /dev/null").readline().strip()
  if choice in keys:
    os.popen(actions[keys.index(choice)])

run_menu()
"""
  directory = "/mnt/etc/wofi"
  if not os.path.exists(directory):
    os.makedirs(directory)
  with open(directory+"/powermenu.py", "w") as f:
    f.write(script)
  run_command("chmod", "+x", directory+"/powermenu.py")

def install_gammastep():
  script = """#!/bin/sh

pid=$(pgrep gammastep)

if [[ $1 = "toggle" ]]; then
	if pgrep -x "gammastep" > /dev/null; then
		kill -9 $(pgrep -x "gammastep");
	else
		gammastep -O ${GAMMASTEP_NIGHT:-3500} &
	fi
fi

if pgrep -x "gammastep" > /dev/null; then
	echo ""
	echo "Nightlight is on"
else
	echo ""
	echo "Nightlight is off"
fi
"""
  directory = "/mnt/etc/sway"
  if not os.path.exists(directory):
    os.makedirs(directory)
  with open(directory+"/gammastep.sh", "w") as f:
    f.write(script)
  run_command("chmod", "+x", "/mnt/etc/sway/gammastep.sh")


def install_gsettings():
  script = """#!/bin/sh

# usage: import-gsettings
config="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini"
if [ ! -f "$config" ]; then exit 1; fi

gnome_schema="org.gnome.desktop.interface"
gtk_theme="$(grep 'gtk-theme-name' "$config" | sed 's/.*\s*=\s*//')"
icon_theme="$(grep 'gtk-icon-theme-name' "$config" | sed 's/.*\s*=\s*//')"
cursor_theme="$(grep 'gtk-cursor-theme-name' "$config" | sed 's/.*\s*=\s*//')"
font_name="$(grep 'gtk-font-name' "$config" | sed 's/.*\s*=\s*//')"
gsettings set "$gnome_schema" gtk-theme "$gtk_theme"
gsettings set "$gnome_schema" icon-theme "$icon_theme"
gsettings set "$gnome_schema" cursor-theme "$cursor_theme"
gsettings set "$gnome_schema" font-name "$font_name"
"""
  directory = "/mnt/etc/sway"
  if not os.path.exists(directory):
    os.makedirs(directory)
  with open(directory+"/gsettings", "w") as f:
    f.write(script)
  run_command("chmod", "+x", "/mnt/etc/sway/gsettings")

def install_sway_config():
  script = """
include /etc/sway/config.d/*.conf

### Variables
  # Logo key. Use Mod1 for Alt.
  set $mod Mod4

  # Home row direction keys, like vim
  set $left h
  set $down j
  set $up k
  set $right l

  # Terminal emulator
  set $term alacritty

  # Launcher
  set $menu wofi --show drun --prompt "Search" --allow-images --style /etc/wofi/styles.css --width 600 --height 400 | xargs swaymsg exec --

### Output configuration
  # Default wallpaper (more resolutions are available in /usr/share/backgrounds/sway/)
  output * bg $(if [ -f $HOME/.config/wallpaper ]; then echo $HOME/.config/wallpaper; else echo "/usr/share/backgrounds/sway/Sway_Wallpaper_Blue_1920x1080.png"; fi) fill

### Input configuration
  # Keyboard
  input "type:keyboard" {           
    xkb_options ctrl:nocaps 
  }

  # Touchpad
  input "type:touchpad" {
    dwt enabled
    tap enabled
  }
  

### Key bindings
  # Start a terminal
  bindsym $mod+Return exec $term

  # Kill focused window
  bindsym $mod+Shift+q kill

  # Start your launcher
  bindsym $mod+d exec $menu

  # Drag floating windows by holding down $mod and left mouse button.
  # Resize them with right mouse button + $mod.
  # Despite the name, also works for non-floating windows.
  # Change normal to inverse to use left mouse button for resizing and right
  # mouse button for dragging.
  floating_modifier $mod normal

  # Reload the configuration file
  bindsym $mod+Shift+c reload

  # Exit sway (logs you out of your Wayland session)
  bindsym $mod+Shift+e exec /etc/wofi/powermenu.py

  # Lock screen
  bindsym $mod+Alt+l exec $locknow

  # Moving around:
    # Move your focus around
    bindsym $mod+$left focus left
    bindsym $mod+$down focus down
    bindsym $mod+$up focus up
    bindsym $mod+$right focus right
    # Or use $mod+[up|down|left|right]
    bindsym $mod+Left focus left
    bindsym $mod+Down focus down
    bindsym $mod+Up focus up
    bindsym $mod+Right focus right

    # Move the focused window with the same, but add Shift
    bindsym $mod+Shift+$left move left
    bindsym $mod+Shift+$down move down
    bindsym $mod+Shift+$up move up
    bindsym $mod+Shift+$right move right
    # Ditto, with arrow keys
    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right

  # Workspaces:
    # Switch to workspace
    bindsym $mod+1 workspace number 1
    bindsym $mod+2 workspace number 2
    bindsym $mod+3 workspace number 3
    bindsym $mod+4 workspace number 4
    bindsym $mod+5 workspace number 5
    bindsym $mod+6 workspace number 6
    bindsym $mod+7 workspace number 7
    bindsym $mod+8 workspace number 8
    bindsym $mod+9 workspace number 9
    bindsym $mod+0 workspace number 10
    # Move focused container to workspace
    bindsym $mod+Shift+1 move container to workspace number 1
    bindsym $mod+Shift+2 move container to workspace number 2
    bindsym $mod+Shift+3 move container to workspace number 3
    bindsym $mod+Shift+4 move container to workspace number 4
    bindsym $mod+Shift+5 move container to workspace number 5
    bindsym $mod+Shift+6 move container to workspace number 6
    bindsym $mod+Shift+7 move container to workspace number 7
    bindsym $mod+Shift+8 move container to workspace number 8
    bindsym $mod+Shift+9 move container to workspace number 9
    bindsym $mod+Shift+0 move container to workspace number 10

  # Layout stuff:
    # You can "split" the current object of your focus with
    # $mod+b or $mod+v, for horizontal and vertical splits
    # respectively.
    bindsym $mod+b splith
    bindsym $mod+v splitv

    # Switch the current container between different layout styles
    bindsym $mod+s layout stacking
    bindsym $mod+w layout tabbed
    bindsym $mod+e layout toggle split

    # Make the current focus fullscreen
    bindsym $mod+f fullscreen

    # Toggle the current focus between tiling and floating mode
    bindsym $mod+Shift+space floating toggle

    # Swap focus between the tiling area and the floating area
    bindsym $mod+space focus mode_toggle

    # Move focus to the parent container
    bindsym $mod+a focus parent

  # Scratchpad:
    # Sway has a "scratchpad", which is a bag of holding for windows.
    # You can send windows there and get them back later.

    # Move the currently focused window to the scratchpad
    bindsym $mod+Shift+minus move scratchpad

    # Show the next scratchpad window or hide the focused scratchpad window.
    # If there are multiple scratchpad windows, this command cycles through them.
    bindsym $mod+minus scratchpad show

  # Resizing containers:

    mode "resize" {
      # left will shrink the containers width
      # right will grow the containers width
      # up will shrink the containers height
      # down will grow the containers height
      bindsym $left resize shrink width 10px
      bindsym $down resize grow height 10px
      bindsym $up resize shrink height 10px
      bindsym $right resize grow width 10px

      # Ditto, with arrow keys
      bindsym Left resize shrink width 10px
      bindsym Down resize grow height 10px
      bindsym Up resize shrink height 10px
      bindsym Right resize grow width 10px

      # Return to default mode
      bindsym Return mode "default"
      bindsym Escape mode "default"
    }
    bindsym $mod+r mode "resize"


### Bar
  bar {
    swaybar_command waybar
  }


### Styling
gaps inner 10
gaps outer 0
smart_gaps on

default_border pixel 2 
for_window [class=".*"] border pixel 2 

# Class           Border    BG        text      indicator child border
client.focused		#78B6E6		#132C3E		#ffffff		#FFFF7D		#78B6E6
client.unfocused  #132C3E		#132C3E		#ffffff		#FFFF7D		#132C3E


### Options
focus_follows_mouse no

### Autostart
exec_always "pkill mako; mako"
exec_always /etc/sway/gsettings
exec_always "pkill kanshi; kanshi"

"""
  directory = "/mnt/etc/sway"
  if not os.path.exists(directory):
    os.makedirs(directory)
  with open(directory+"/config", "w") as f:
    f.write(script)


def install_wofi_styles():
  script = """
window {
  font-family: "Droid Sans", "Font Awesome 5 Free", Helvetica, Arial, sans-serif;
  margin: 0px;
  border: 1px solid #000813;
  background-color: #282a36;
}

#input {
  margin: 5px;
  border: none;
  color: #f8f8f2;
  background-color: #44475a;
}

#inner-box {
  margin: 5px;
  border: none;
  background-color: #282a36;
}

#outer-box {
  margin: 5px;
  border: none;
  background-color: #282a36;
}

#scroll {
  margin: 0px;
  border: none;
}

#text {
  margin: 5px;
  border: none;
  color: #f8f8f2;
}

#entry:selected {
  background-color: #44475a;
}
"""
  directory = "/mnt/etc/wofi"
  if not os.path.exists(directory):
    os.makedirs(directory)
  with open(directory+"/styles.css", "w") as f:
    f.write(script)

def install_swaylock():
  script = """
exec swayidle -w timeout 300 'swaylock -f -C /etc/sway/swaylock.conf' timeout 301 'swaymsg "output * dpms off"' resume 'swaymsg "output * dpms on"' before-sleep 'swaylock -f -C /etc/sway/swaylock.conf'

set $locknow swaylock -f -C /etc/sway/swaylock.conf
"""
  directory = "/mnt/etc/sway/config.d"
  if not os.path.exists(directory):
    os.makedirs(directory)
  with open(directory+"/swayidle.conf", "w") as f:
    f.write(script)
  
  script = """
ignore-empty-password

color=040A0F
indicator-idle-visible
indicator-radius=150
indicator-thickness=30

inside-color=040A0F
inside-clear-color=040A0F
inside-ver-color=040A0F
inside-wrong-color=040A0F

key-hl-color=78B5E6AA
bs-hl-color=AA3F39AA

separator-color=040A0F

line-color=132C3E
line-uses-ring

text-color=46779C
text-clear-color=46779C
text-caps-lock-color=46779C
text-ver-color=78B6E6
text-wrong-color=AA3F39

ring-color=132C3E55
ring-ver-color=78B6E6
ring-clear-color=132C3E11
ring-wrong-color=AA3F39
"""
  directory = "/mnt/etc/sway"
  if not os.path.exists(directory):
    os.makedirs(directory)
  with open(directory+"/swaylock.conf", "w") as f:
    f.write(script)


def hide_system_apps():
  shell_script = """
#!/usr/bin/env bash

sys_apps=( avahi-discover bssh bvnc nm-connection-editor qv4l2 qvidcap lstopo xfce4-about)
dir="/mnt/usr/share/applications"
for app in ${sys_apps[@]}; do
  file_name="$dir/$app.desktop"
  echo -ne "Checking $app: "
  if [ -f $file_name ]; then
    var_hidden=$(cat $file_name | egrep -ohm1 "Hidden=(true|false)")
    if [ -z $var_hidden ]; then
      echo 'Hidden=true' >> $file_name
      echo -ne "Set Hidden=true\\n"
    else
      sed -i -e 's/Hidden=.*/Hidden=true/g' $file_name
      echo -ne "Update Hidden=true\\n"
    fi
  else
    echo -ne "Skipping\\n"
  fi
done
  """
  with open("/tmp/hide_sys", "w") as f:
    f.write(shell_script)
  run_command("sh", "/tmp/hide_sys")
  os.remove("/tmp/hide_sys")

cpu = detect_cpu()
vga = detect_vga().lower()

clear()
hostname = ask_hostname()

clear()
disk = get_install_disk()
encrypt = False
swap = 0
encrypt_password = ""
timezone = ""
cryptroot = ""
volume_group = "VolGroup0"
clear()
efi_partition = ""
efi_part_no = 1
if disk != "None":
  encrypt = ask_use_encryption()
  if encrypt:
    encrypt_password = ask_encryption_password()
    cryptroot = "/dev/mapper/cryptlvm"
  clear()
  swap = ask_swap()
  clear()
  filesystem = ask_filesystem()

clear()

timezone = ask_timezone()
clear()
locales = ask_locale()
lang = locales[0] + ".UTF-8"
bluetooth = detect_bluetooth()
use_zsh = True

# clear()
# use_zsh = ask_zsh()

clear()
print("Setup your user account, this account will have sudo access")
user_name = ask_username()
user_label = request_input("User Fullname: ")
user_password = ask_password()

plymouth = False

# clear()
# plymouth = True
# q = request_input("Do you want to use Plymouth? [Yes]/No ")
# if q.lower() == "no" or q.lower() == "n":
#   plymouth = False

clear()
yubi_key = True
q = request_input("Do you want to use Yubikey? [Yes]/No ")
if q.lower() == "no" or q.lower() == "n":
  yubi_key = False


xwm = True
q = request_input("Do you want to install SwayVM? [Yes]/No ")
if q.lower() == "no" or q.lower() == "n":
  xwm = False


x_utils = xwm
if xwm:
  q = request_input("Do you want to install X utilities? [Yes]/No ")
  if q.lower() == "no" or q.lower() == "n":
    x_utils = False

x_multimedia = xwm
if xwm:
  q = request_input("Do you want to install X multimedia applications? [Yes]/No ")
  if q.lower() == "no" or q.lower() == "n":
    x_multimedia = False

git_base = True
q = request_input("Do you want to install development packages? [Yes]/No ")
if q.lower() == "no" or q.lower() == "n":
  git_base = False

yay = True
q = request_input("Do you want to install yay? [Yes]/No ")
if q.lower() == "no" or q.lower() == "n":
  yay = False

clear()
print("This script will install Arch Linux as follow:")

print("{:>35}{:<1} {:<50}".format("Hostname", ":", hostname))
print("{:>35}{:<1} {:<50}".format("CPU", ":", cpu))
print("{:>35}{:<1} {:<50}".format("VGA", ":", vga))

if disk == "None":
  print("{:>35}{:<1} {:<50}".format("Disk", ":", "No partitioning. Already mounted at /mnt"))
else:
  print("{:>35}{:<1} {:<50}".format("Disk", ":", disk + " (Will be partitioned & formatted)"))
  print("{:>35}{:<1} {:<50}".format("Filesystem", ":", filesystem))
  print("{:>35}{:<1} {:<50}".format("Swap", ":", str(swap) + " GiB"))
  print("{:>35}{:<1} {:<50}".format("Encryption", ":", string_bool(encrypt)))

print("{:>35}{:<1} {:<50}".format("User Account", ":", user_name + " (" + user_label + ")"))
print("{:>35}{:<1} {:<50}".format("Timezone", ":", timezone))
print("{:>35}{:<1} {:<50}".format("Locales", ":", ", ".join(locales)))
print("{:>35}{:<1} {:<50}".format("Lang", ":", locales[0] + ".UTF-8"))
# print("{:>35}{:<1} {:<50}".format("Plymouth", ":", string_bool(plymouth)))
print("{:>35}{:<1} {:<50}".format("Bluetooth", ":", string_bool(bluetooth)))
print("{:>35}{:<1} {:<50}".format("Yubikey (opensc & pam-u2f)", ":", string_bool(yubi_key)))
print("{:>35}{:<1} {:<50}".format("SwayVM", ":", string_bool(xwm)))
if xwm:
  print("{:>35}{:<1} {:<50}".format("X utilities", ":", string_bool(x_utils)))
  print("{:>35}{:<1} {:<50}".format("X multimedia applications", ":", string_bool(x_multimedia)))

print("{:>35}{:<1} {:<50}".format("Development packages", ":", string_bool(git_base)))
print()
confirm = request_input("Do you want to continue? Type 'YES': ")
if confirm != "YES":
  print("Exiting")
  sys.exit(0)

print()
print("Installing Arch Linux")
# Partitioning
if disk != "None":
  print("Partitioning " + disk)
  print_task("Setup new partition scheme")
  run_command("/usr/bin/sgdisk", "--zap-all", disk)
  print("Done")
  print_task("Creating EPS partition")
  run_command("/usr/bin/sgdisk", "-n 0:0:+512M -t 0:ef00 -c 0:EPS", disk)
  print("Done")
  if encrypt:
    print_task("Creating LUKS partition")
    run_command("/usr/bin/sgdisk", "-n 0:0:0 -t 0:8309 -c 0:cryptlvm", disk)
    print("Done")
  else:
    if int(swap) > 0:
      print_task("Creating SWAP partition")
      run_command("/usr/bin/sgdisk", "-n 0:0:+" + str(swap) + "GiB -t 0:8200 -c 0:swap", disk)
      print("Done")
    print_task("Creating root partition")
    run_command("/usr/bin/sgdisk", "-n 0:0:0 -t 0:8300 -c 0:root", disk)
    print("Done")

  run_command("/usr/bin/partprobe", disk)

  if not encrypt and int(swap) > 0:
    print_task("Enabling Swap")
    partition = os.popen('blkid ' + disk +'* | grep -oP \'/dev/[a-z0-9]*:.*PARTLABEL="swap"\' | grep -o \'/dev/[a-z0-9]*\'').readline().strip()
    run_command("/usr/bin/mkswap", partition)
    run_command("/usr/bin/swapon", partition)
    print("Done")

  print_task("Formatting EPS partition")
  partition = os.popen('blkid ' + disk +'* | grep -oP \'/dev/[a-z0-9]*:.*PARTLABEL="EPS"\' | grep -o \'/dev/[a-z0-9]*\'').readline().strip()
  run_command("/usr/bin/mkfs.fat", "-F32", partition)
  print("Done")  

  if encrypt:
    cryptpartition = os.popen('blkid ' + disk +'* | grep -oP \'/dev/[a-z0-9]*:.*PARTLABEL="cryptlvm"\' | grep -o \'/dev/[a-z0-9]*\'').readline().strip()
    print_task("Encrypting LUKS partition to cryptlvm")
    run_command("echo \"" + encrypt_password + "\" |", "cryptsetup -q luksFormat", cryptpartition)
    print("Done")
    print_task("Opening LUKS partition to cryptlvm")
    run_command("echo \"" + encrypt_password + "\" |", "cryptsetup luksOpen", cryptpartition, "cryptlvm")
    print("Done")

    print_task("Creating LVM inside LUKS")
    run_command("/usr/bin/pvcreate", cryptroot)
    print("Done")
    print_task("Creating Volume Group")
    run_command("/usr/bin/vgcreate", volume_group, cryptroot)
    print("Done")

    if int(swap) > 0:
      print_task("Creating SWAP partition")
      run_command("/usr/bin/lvcreate", "-L" + str(swap) + "G -n lvSwap", volume_group)
      print("Done")
      print_task("Enabling Swap")
      partition = "/dev/mapper/" + volume_group + "-lvSwap"
      run_command("/usr/bin/mkswap", partition)
      run_command("/usr/bin/swapon", partition)
      print("Done")

    print_task("Creating root partition")
    run_command("/usr/bin/lvcreate", '-l 100%FREE -n lvRoot', volume_group)
    print("Done")
    print_task("Formatting root partition")
    partition = "/dev/mapper/" + volume_group + "-lvRoot"
    format_root(partition, filesystem)
    print("Done")
  else:
    print_task("Formatting root partition")
    partition = os.popen('blkid ' + disk +'* | grep -oP \'/dev/[a-z0-9]*:.*PARTLABEL="root"\' | grep -o \'/dev/[a-z0-9]*\'').readline().strip()
    format_root(partition, filesystem)
    print("Done")


  if encrypt:
    partition = "/dev/mapper/" + volume_group + "-lvRoot"
  else:
    partition = os.popen('blkid ' + disk +'* | grep -oP \'/dev/[a-z0-9]*:.*PARTLABEL="root"\' | grep -o \'/dev/[a-z0-9]*\'').readline().strip()
    
  print_task("Mounting root")
  run_command("/usr/bin/mount", partition, "/mnt")
  print("Done")
  partition = os.popen('blkid ' + disk +'* | grep -oP \'/dev/[a-z0-9]*:.*PARTLABEL="EPS"\' | grep -o \'/dev/[a-z0-9]*\'').readline().strip()
  print_task("Mounting EPS")
  run_command("/usr/bin/mkdir", "-p", "/mnt/boot")
  run_command("/usr/bin/mount", partition, "/mnt/boot")
  print("Done")

# Pacstrap
print_task("Bootstrapping")
run_command("/usr/bin/pacstrap", "/mnt", "base")
print("Done")

print_task("Updating pacman")
run_chroot("/usr/bin/pacman", "-Syu")
print("Done")

if filesystem == "btrfs" or filesystem == "xfs":
  print_task("Installing filesystem utilities")
  fs_utility = "xfsprogs"
  if filesystem == "btrfs":
    fs_utility = "btrfs-progs"
  run_chroot("/usr/bin/pacman", "-S --noconfirm", fs_utility)
  print("Done")

print_task("Generating fstab")
run_command("/usr/bin/genfstab", "-U", "/mnt", ">>", "/mnt/etc/fstab")
print("Done")

print_task("Generating locales")
run_chroot("rm", "-rf", "/etc/locale.gen")
the_locales = []
for locale in locales:
  run_chroot("echo", locale + ".UTF-8 UTF-8", ">>", "/etc/locale.gen")
  run_chroot("echo", locale + " ISO-8859-1", ">>", "/etc/locale.gen")

run_chroot("echo", "-e", "LANG=" + lang , ">", "/etc/locale.conf")
run_chroot("/usr/bin/locale-gen")
print("Done")

print_task("Setup timezone")
run_chroot("/usr/bin/ln", "-sf", "/usr/share/zoneinfo/" + timezone, "/etc/localtime")
print("Done")

print_task("Setup hostname")
run_chroot("echo", hostname, ">", "/etc/hostname")
run_chroot("echo", "-e", '"127.0.0.1\\tlocalhost\\n::1\\tlocalhost\\n127.0.1.1\\t' + hostname + '.local ' + hostname, "\" >", "/etc/hosts")
print("Done")

if use_zsh:
  print_task("Setup zsh")
  run_chroot("/usr/bin/pacman", "-S --noconfirm", "zsh")
  run_chroot("/usr/bin/chsh", "-s", "/usr/bin/zsh")
  run_chroot("/usr/bin/sed", "-i -e", '"s/SHELL=.*/\SHELL=\/usr\/bin\/zsh/g"', "/etc/default/useradd")
  print("Done")

print_task("Installing Sudo")
run_chroot("/usr/bin/pacman", "-S --noconfirm", "sudo")
run_chroot("echo \"%wheel ALL=(ALL) ALL\" >> /etc/sudoers")
print("Done")

print_task("Setup user account")
run_chroot("/usr/bin/useradd", "-G wheel,input,lp,video -m -c \"" + user_label  + "\"", user_name)
run_chroot("echo \"" + user_name + ":" + user_password + "\" | chpasswd")
run_chroot("passwd -l root")
print("Done")

print_task("Installing kernel")
run_chroot("/usr/bin/pacman", "-S --noconfirm", "linux-lts linux-firmware")
print("Done")

if cpu == "AMD":
  print_task("Installing AMD microcode")
  run_chroot("/usr/bin/pacman", "-S --noconfirm", "amd-ucode")
  print("Done")

if cpu == "Intel":
  print_task("Installing Intel microcode")
  run_chroot("/usr/bin/pacman", "-S --noconfirm", "intel-ucode")
  print("Done")

if plymouth:
  print_task("Installing Plymouth")
  run_chroot("/usr/bin/curl", "-L", "https://github.com/quangdinh/install-scripts/raw/master/pkgs/plymouth-git.pkg.tar.zst", "-o", "/plymouth-git.pkg.tar.zst")
  run_chroot("/usr/bin/curl", "-L", "https://github.com/quangdinh/install-scripts/raw/master/pkgs/plymouth-theme-arch-glow.pkg.tar.zst", "-o", "/plymouth-theme-arch-glow.pkg.tar.zst")
  run_chroot("/usr/bin/pacman", "-U --noconfirm", "/*.pkg.tar.zst")
  run_chroot("rm", "-rf", "/*.pkg.tar.zst")
  run_chroot("/usr/bin/plymouth-set-default-theme", "-R", "arch-glow")
  print("Done")

if disk != "None" and encrypt:
  print_task("Install LVM2 and configure encryption")
  run_chroot("/usr/bin/pacman", "-S --noconfirm", "lvm2")
  print("Done")

hooks = parse_hooks_encrypt_lvm(encrypt, plymouth)

if vga == "intel":
  run_chroot("/usr/bin/sed", "-i -e", "\"s/MODULES=(.*)/MODULES=(i915)/g\"", "/etc/mkinitcpio.conf")

if vga == "amd":
  run_chroot("/usr/bin/sed", "-i -e", "\"s/MODULES=(.*)/MODULES=(amdgpu)/g\"", "/etc/mkinitcpio.conf")

if encrypt or plymouth:
  run_chroot("/usr/bin/sed", "-i -e", "\"s/HOOKS=(.*)/HOOKS=(" + hooks + ")/g\"", "/etc/mkinitcpio.conf")

run_chroot("/usr/bin/mkinitcpio", "-P")

if disk != "None":
  rootuuid = get_root_uuid()
  cmdLineExtra = ""
  if vga == "intel":
    cmdLineExtra = ' i915.fastboot=1'

  cpucode = get_cpu_code(cpu)
  cmdLine = 'root=UUID=' + rootuuid + ' ' + cpucode + 'initrd=/initramfs-linux-lts.img'

  if encrypt:
    cryptuuid = get_crypt_uuid(disk)
    cmdLine = 'cryptdevice=UUID=' + cryptuuid + ':cryptlvm root=UUID=' + rootuuid + ' rw ' + cpucode + 'initrd=/initramfs-linux-lts.img'
  
  swap_uuid = get_swap_uuid(encrypt)
  if swap_uuid != "":
    cmdLine = cmdLine + " resume=UUID=" + swap_uuid

  cmdLine = '"' + 'quiet loglevel=3 splash ' + cmdLine  + ' rw rd.systemd.show_status=auto rd.udev.log_priority=3 module_blacklist=iTCO_wdt,iTCO_vendor_support nmi_watchdog=0'+ cmdLineExtra + '"'

  print_task("Installing boot manager")
  run_chroot("/usr/bin/pacman", "-S --noconfirm", "efibootmgr")
  print("Done")
  print_task("Setup bootloader")
  efiboot = os.popen('efibootmgr | grep "Arch Linux" | grep -oP "[0-9]+"').readline().strip()
  if efiboot != "":
    run_chroot("/usr/bin/efibootmgr", "-Bb", efiboot)
  run_chroot("/usr/bin/efibootmgr", "--create", "--disk", disk, "--part 1", "--label \"Arch Linux\"", "--loader", "/vmlinuz-linux-lts", "--unicode",  cmdLine, "--verbose")
  print("Done")

print_task("Installing NetworkManager")
run_chroot("/usr/bin/pacman", "-S --noconfirm", "networkmanager")
run_chroot("/usr/bin/systemctl", "enable", "NetworkManager")
print("Done")

print_task("Installing System utilities")
run_chroot("/usr/bin/pacman", "-S --noconfirm", "vim neofetch htop gnome-keyring brightnessctl")
add_gnome_keyring()
print("Done")

if yubi_key:
  print_task("Install Yubikey opensc & pam-u2f")
  run_chroot("/usr/bin/pacman", "-S --noconfirm", "ccid pam-u2f opensc")
  run_chroot("/usr/bin/systemctl", "enable", "pcscd.service")
  print("Done")

if bluetooth:
  print_task("Installing Bluetooth")
  run_chroot("/usr/bin/pacman", "-S --noconfirm", "bluez bluez-utils")
  run_chroot("/usr/bin/systemctl", "enable", "bluetooth")
  print("Done")

if xwm:
  print_task("Installing X.Org Server")
  run_chroot("/usr/bin/pacman", "-S --noconfirm", "xorg-server xorg-xinit xorg-xwayland gnome-themes-extra qt5-wayland qt5ct")
  print("Done")
  if vga == "intel":
    print_task("Installing Intel video drivers")
    run_chroot("/usr/bin/pacman", "-S --noconfirm", "mesa")
    print("Done")
  if vga == "nvidia":
    print_task("Installing Nvidia video drivers")
    run_chroot("/usr/bin/pacman", "-S --noconfirm", "nvidia-lts")
    print("Done")
  if vga == "amd":
    print_task("Installing AMD/ATI video drivers")
    run_chroot("/usr/bin/pacman", "-S --noconfirm", "xf86-video-amdgpu")
    print("Done")
  if vga == "generic":
    print_task("Installing Generic video drivers")
    run_chroot("/usr/bin/pacman", "-S --noconfirm", "xf86-video-fbdev xf86-video-vesa")
    print("Done")
  
  print_task("Installing SwayVM")
  run_chroot("/usr/bin/pacman", "-S --noconfirm", "sway waybar swaylock swayidle ttf-liberation ttf-dejavu ttf-droid ttf-font-awesome wofi mako xdg-user-dirs wl-clipboard grim jq slurp gammastep kanshi")
  install_brightness()
  install_swaylock()
  install_screenshot()
  install_wofi_styles()
  install_sway_config()
  install_gsettings()
  install_gammastep()
  install_powermenu()
  print("Done")

  if x_utils:
    print_task("Installing X utilities")
    run_chroot("/usr/bin/pacman", "-S --noconfirm", "alacritty firefox imv xdg-desktop-portal-wlr thunar thunar-volman thunar-archive-plugin file-roller xreader seahorse gvfs gvfs-smb gvfs-nfs gvfs-mtp gvfs-afc")
    print("Done")
  if x_multimedia:
    print_task("Installing X multimedia applications")
    run_chroot("/usr/bin/pacman", "-S --noconfirm", "mpv mpd ncmpcpp pulseaudio pavucontrol sof-firmware pulsemixer")
    run_chroot("/usr/bin/curl", "-L", "https://github.com/quangdinh/install-scripts/raw/master/pkgs/volumectl.pkg.tar.zst", "-o", "/volumectl.pkg.tar.zst")
    run_chroot("/usr/bin/pacman", "-U --noconfirm", "/*.pkg.tar.zst")
    run_chroot("rm", "-rf", "/*.pkg.tar.zst")
    install_audio()
    if bluetooth:
      run_chroot("/usr/bin/pacman", "-S --noconfirm", "pulseaudio-bluetooth")
    print("Done")
  
if git_base:
  print_task("Installing development packages")
  run_chroot("/usr/bin/pacman", "-S --noconfirm", "git base-devel go nodejs npm")
  print("Done")

hide_system_apps()

if yay:
  print_task("Installing yay")
  run_chroot("/usr/bin/curl", "-L", "https://github.com/quangdinh/install-scripts/raw/master/pkgs/yay.pkg.tar.zst", "-o", "/yay.pkg.tar.zst")
  run_chroot("/usr/bin/pacman", "-U --noconfirm", "/*.pkg.tar.zst")
  run_chroot("rm", "-rf", "/*.pkg.tar.zst")
  print("Done")

print_task("Copying after_install scripts")
run_command("cp -a", "./after_install", "/mnt/home/" + user_name)
run_chroot("chown -R", user_name+":"+user_name, "/home/" + user_name + "/after_install")
print("Done")

if disk != "None":
  if int(swap) > 0:
    if encrypt:
      partition = "/dev/mapper/" + volume_group + "-lvSwap"
    else:
      partition = os.popen('blkid ' + disk +'* | grep -oP \'/dev/[a-z0-9]*:.*PARTLABEL="swap"\' | grep -o \'/dev/[a-z0-9]*\'').readline().strip()
    run_command("/usr/bin/swapoff", partition)
  os.popen("/usr/bin/umount -R /mnt")
  time.sleep(1)
  if encrypt:
    time.sleep(1)
    os.popen("/usr/bin/cryptsetup luksClose VolGroup0-lvRoot")
    time.sleep(1)
    os.popen("/usr/bin/cryptsetup luksClose VolGroup0-lvSwap")
    time.sleep(1)
    os.popen("/usr/bin/cryptsetup luksClose cryptlvm")
print("==================================================================")
print("Arch installation is ready. Please reboot and remove the USB drive")
