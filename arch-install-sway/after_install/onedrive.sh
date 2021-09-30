#!/usr/bin/env bash

set -e



  yay -S --noconfirm onedriver
  # create the mountpoint and determine the service name
    export MOUNTPOINT=~/OneDrive
    mkdir -p $MOUNTPOINT
    export SERVICE_NAME=$(systemd-escape --template onedriver@.service --path $MOUNTPOINT)

    # mount onedrive
    systemctl --user daemon-reload
    systemctl --user start $SERVICE_NAME

    # automatically mount onedrive when you login
    systemctl --user enable $SERVICE_NAME

