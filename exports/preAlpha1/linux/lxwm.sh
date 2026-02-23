#!/bin/sh
printf '\033c\033]0;%s\a' laikX Workmode
base_path="$(dirname "$(realpath "$0")")"
"$base_path/lxwm.x86_64" "$@"
