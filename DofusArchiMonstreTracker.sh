#!/bin/sh
printf '\033c\033]0;%s\a' DofusArchiMonstreTracker
base_path="$(dirname "$(realpath "$0")")"
"$base_path/DofusArchiMonstreTracker.x86_64" "$@"
