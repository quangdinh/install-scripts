#!/usr/bin/env bash

. ./functions/base.sh

print_green "This script will install Java 1.8.x:\n"
print_bold "- Homebrew\n"
print_bold "- Java (OpenJDK): Version 1.8.x\n"
printf "You may be asked for your password.\n"
ask_to_continue

# Needs homebrew
check_homebrew_install

# Java -> adoptopenjdk8
check_java_install
