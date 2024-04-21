#!/usr/bin/env bash

this_script_path=$(cd "$(dirname "$0")" && pwd) # Relative, Absolutized and normalized
if [ -z "$this_script_path" ]; then # Error, for some reason, the path is not accessible to the script (e.g. permissions re-evalued after suid)
  exit 1
fi

cd "$this_script_path" || exit 1

pactl load-module module-native-protocol-unix socket=/tmp/pulseaudio_lutris.socket
chmod 700 /tmp/pulseaudio_lutris.socket

sudo docker compose run --rm --name lutris lutris
