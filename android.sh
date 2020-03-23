#!/usr/bin/env bash

ANDROID_PLATFORM_VERSION=29
ANDROID_BUILD_TOOLS_VERSION=29.0.3

. ./functions/base.sh

print_green "This script will install required tools for Android Development:\n"
print_bold "- Homebrew\n"
print_bold "- Java (OpenJDK): Version 1.8.x\n"
print_bold "- Android SDK\n"
print_bold "- Android build-tools: $ANDROID_BUILD_TOOLS_VERSION\n"
print_bold "- Android platforms: $ANDROID_PLATFORM_VERSION\n"
print_bold "- Gradle\n"
printf "You may be asked for your password.\n"
ask_to_continue

# Needs homebrew
check_homebrew_install
check_java_install

# Android SDK - Quick smoke test with sdkmanager
print_bold "> Checking if Android SDK is installed: "
if [ -x "$(command -v sdkmanager)" ]; then
  print_green "installed\n"
else
  print_red "not installed\n"
  brew cask install android-sdk
fi

SDK_ROOT="$HOME/Library/Android/sdk"
# Checking env setting $ANDROID_SDK_ROOT
if [[ -z $ANDROID_SDK_ROOT ]]; then
  PROFILE_FILE="$HOME/.profile"
  if [[ $SHELL == *"zsh"* ]]; then
    PROFILE_FILE="$HOME/.zprofile"
  fi
  if [[ -f $PROFILE_FILE ]]; then
    grep -qxF "export ANDROID_SDK_ROOT=\"$SDK_ROOT\"" $PROFILE_FILE || echo "export ANDROID_SDK_ROOT=\"$SDK_ROOT\"" >> $PROFILE_FILE
  else
    echo "export ANDROID_SDK_ROOT=\"$SDK_ROOT\"" >> $PROFILE_FILE
  fi
fi
export ANDROID_SDK_ROOT="$SDK_ROOT"

# Installing Android build-tools & platforms
print_yellow "=> Installing platforms: android-$ANDROID_PLATFORM_VERSION\n"
sdkmanager "platforms;android-$ANDROID_PLATFORM_VERSION"
print_yellow "=> Installing build-tools: $ANDROID_BUILD_TOOLS_VERSION\n"
sdkmanager "build-tools;$ANDROID_BUILD_TOOLS_VERSION"

# Gradle
print_bold "> Checking if Gradle is installed: "
if [ -x "$(command -v gradle)" ]; then
  print_green "installed\n"
else
  print_red "not installed\n"
  brew install gradle
fi