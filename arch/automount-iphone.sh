#!/usr/bin/env sh
function imount {
  mkdir -p ~/iPhone
  ifuse ~/iPhone
}

function check_pair {
  var_success=$(idevicepair validate | egrep -ohm1 "SUCCESS")
  if [ $var_success == "SUCCESS" ]; then
    imount
  fi
}

function pair {
  idevicepair pair
  sleep 2
  check_pair
}

check_pair

if [ -e $var_success ]; then 
  pair
fi
