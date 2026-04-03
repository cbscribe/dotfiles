#!/usr/bin/env bash

for monitor in $(aerospace list-monitors); do
  for sid in $(aerospace list-workspaces --monitor "$monitor" --empty no); do
    apps=$(aerospace list-windows --workspace "$sid" | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')

    sketchybar --set space.$sid drawing=on

    icon_strip=" "
    if [ "${apps}" != "" ]; then
      while read -r app; do
        icon_strip+=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
      done <<<"${apps}"
    else
      icon_strip=""
    fi
    sketchybar --set space.$sid label="$icon_strip"
  done
done
