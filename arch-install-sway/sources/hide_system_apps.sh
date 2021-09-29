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