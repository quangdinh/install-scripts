#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import getpass
import os
import json
import signal
import sys
import re
import time

def clear():
  os.system("clear")

def signal_handler(sig, frame):
    print('')
    print('Cancelled')
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

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
  l = request_input("Enter locales [en_US, nl_NL]: ")
  if l == "":
    l = "en_US, nl_NL"
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

def parse_hooks_encrypt_lvm(encrypt):
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
    if hook == keyboardHook:
      results.append(hook)
      results.append("keyboard")

    if hook == "keyboard" or hook == "encrypt" or hook == "lvm2":
      continue

    if hook == "filesystems":
      if encrypt:
        results.append("encrypt")
        results.append("lvm2")
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

def hide_system_apps():
  shell_script = """
#!/usr/bin/env bash

sys_apps=( avahi-discover bssh bvnc nm-connection-editor qv4l2 qvidcap lstopo )
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
  with open("/tmp/hide_sys", "a") as f:
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

clear()
use_zsh = ask_zsh()

clear()
print("Setup your user account, this account will have sudo access")
user_name = ask_username()
user_label = request_input("User Fullname: ")
user_password = ask_password()

clear()
yubi_key = True
q = request_input("Do you want to use Yubikey? [Yes]/No ")
if q.lower() == "no" or q.lower() == "n":
  yubi_key = False


gnome = True
q = request_input("Do you want to install Gnome? [Yes]/No ")
if q.lower() == "no" or q.lower() == "n":
  gnome = False

pipewire = gnome
if gnome:
  q = request_input("Do you want to install Pipewire? [Yes]/No ")
  if q.lower() == "no" or q.lower() == "n":
    pipewire = False

gnome_utils = gnome
if gnome:
  q = request_input("Do you want to install Gnome utilities? [Yes]/No ")
  if q.lower() == "no" or q.lower() == "n":
    gnome_utils = False

gnome_multimedia = gnome
if gnome:
  q = request_input("Do you want to install Gnome multimedia applications? [Yes]/No ")
  if q.lower() == "no" or q.lower() == "n":
    gnome_multimedia = False

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
print("{:>35}{:<1} {:<50}".format("Bluetooth", ":", string_bool(bluetooth)))
print("{:>35}{:<1} {:<50}".format("Yubikey (opensc & pam-u2f)", ":", string_bool(yubi_key)))
print("{:>35}{:<1} {:<50}".format("Gnome", ":", string_bool(gnome)))
if gnome:
  print("{:>35}{:<1} {:<50}".format("Pipewire", ":", string_bool(pipewire)))
  print("{:>35}{:<1} {:<50}".format("Gnome utilities", ":", string_bool(gnome_utils)))
  print("{:>35}{:<1} {:<50}".format("Gnome multimedia applications", ":", string_bool(gnome_multimedia)))

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
  run_chroot("/usr/bin/pacman", "-S --noconfirm", "zsh fzf zoxide")
  run_chroot("/usr/bin/chsh", "-s", "/usr/bin/zsh")
  run_chroot("/usr/bin/sed", "-i -e", '"s/SHELL=.*/\SHELL=\/usr\/bin\/zsh/g"', "/etc/default/useradd")
  print("Done")

print_task("Installing Sudo")
run_chroot("/usr/bin/pacman", "-S --noconfirm", "sudo")
run_chroot("echo \"%wheel ALL=(ALL) ALL\" >> /etc/sudoers")
print("Done")

print_task("Setup user account")
run_chroot("/usr/bin/useradd", "-G wheel,input,lp -m -c \"" + user_label  + "\"", user_name)
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

if disk != "None" and encrypt:
  print_task("Install LVM2 and configure encryption")
  run_chroot("/usr/bin/pacman", "-S --noconfirm", "lvm2")
  print("Done")

hooks = parse_hooks_encrypt_lvm(encrypt)

if vga == "intel":
  run_chroot("/usr/bin/sed", "-i -e", "\"s/MODULES=(.*)/MODULES=(i915)/g\"", "/etc/mkinitcpio.conf")

if vga == "amd":
  run_chroot("/usr/bin/sed", "-i -e", "\"s/MODULES=(.*)/MODULES=(amdgpu)/g\"", "/etc/mkinitcpio.conf")

if encrypt:
  run_chroot("/usr/bin/sed", "-i -e", "\"s/HOOKS=(.*)/HOOKS=(" + hooks + ")/g\"", "/etc/mkinitcpio.conf")

run_chroot("/usr/bin/mkinitcpio", "-P")

if disk != "None":
  rootuuid = get_root_uuid()
  cmdLineExtra = ""
  if vga == "intel":
    cmdLineExtra = ' i915.fastboot=1'

  cpucode = get_cpu_code(cpu)
  cmdLine = 'root=UUID=' + rootuuid + ' rw ' + cpucode + 'initrd=/initramfs-linux-lts.img'

  if encrypt:
    cryptuuid = get_crypt_uuid(disk)
    cmdLine = 'cryptdevice=UUID=' + cryptuuid + ':cryptlvm root=UUID=' + rootuuid + ' rw ' + cpucode + 'initrd=/initramfs-linux-lts.img'
  
  cmdLine = '"' + cmdLine + ' quiet loglevel=3 splash rd.systemd.show_status=auto rd.udev.log_priority=3 module_blacklist=iTCO_wdt,iTCO_vendor_support fbcon=nodefer'+ cmdLineExtra + '"'

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

print_task("Installing System Utilities")
run_chroot("/usr/bin/pacman", "-S --noconfirm", "yadm neovim bottom bat procs exa python-neovim fd wget ripgrep python-pip")
print("Done")

if yubi_key:
  print_task("Install Yubikey opensc")
  run_chroot("/usr/bin/pacman", "-S --noconfirm", "ccid opensc")
  run_chroot("/usr/bin/systemctl", "enable", "pcscd.service")
  print("Done")

if bluetooth:
  print_task("Installing Bluetooth")
  run_chroot("/usr/bin/pacman", "-S --noconfirm", "bluez bluez-utils")
  run_chroot("/usr/bin/systemctl", "enable", "bluetooth")
  print("Done")

if gnome:
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
  print_task("Installing Gnome")


  run_chroot("/usr/bin/pacman", "-S --noconfirm", "gnome-shell gnome-backgrounds gdm xdg-utils xdg-user-dirs-gtk alacritty gnome-control-center gnome-keyring mutter gnome-menus sof-firmware gnome-themes-extra wl-clipboard libappindicator-gtk3")

  run_chroot("/usr/bin/systemctl", "enable", "gdm")
  print("Done")

  if pipewire:
    print_task("Installing Pipewire")
    run_chroot("/usr/bin/pacman", "-S --noconfirm", "pipewire wireplumber xdg-desktop-portal-gnome xdg-desktop-portal")
    print("Done")

  if gnome_utils:
    print_task("Installing Gnome utilities")
    run_chroot("/usr/bin/pacman", "-S --noconfirm", "eog gnome-calendar evince file-roller gnome-screenshot gnome-shell-extensions gnome-system-monitor nautilus sushi gnome-tweaks noto-fonts noto-fonts-emoji gnome-calculator gvfs gvfs-smb gvfs-nfs gvfs-mtp gvfs-afc")
    print("Done")
  if gnome_multimedia:
    print_task("Installing Gnome multimedia applications")
    run_chroot("/usr/bin/pacman", "-S --noconfirm", "xvidcore x264 ffmpeg gst-libav totem rhythmbox")
    print("Done")
  hide_system_apps()

if git_base:
  print_task("Installing development packages")
  run_chroot("/usr/bin/pacman", "-S --noconfirm", "git git-delta lazygit rustup base-devel go")
  print("Done")


if yay:
  print_task("Installing yay")
  if not git_base:
    run_chroot("/usr/bin/pacman", "-S --noconfirm", "git base-devel go")

  run_chrootuser(user_name, "git", "clone", "https://aur.archlinux.org/yay.git", "~/yay")
  run_chrootuser(user_name, "cd ~/yay", "&&", "makepkg -s --noconfirm")
  run_chroot("/usr/bin/pacman", "-U --noconfirm", "/home/" + user_name + "/yay/yay*.pkg.tar.zst")
  run_chrootuser(user_name, "rm -rf ~/yay")
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
