#!/usr/bin/env bash

mkdir -p ~/.config/Yubico
hostname=$(hostnamectl --static)
pamu2fcfg -o pam://$hostname -i pam://$hostname > ~/.config/Yubico/u2f_keys