#!/bin/sh
source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/state.sh"

activate_space() {
if [ -z "${SID+x}" ] || [ -z "${SID}" ] || [ -z "${NAME+x}" ] || [ -z "${NAME}" ]; then
  return
fi
if [ "$(hget spaces $SID)" = "true" ]; then
  sketchybar --set  $NAME     icon.highlight=true                       \
                              icon.padding_left=5                       \
                              icon.padding_right=-2                     \
                              \
                              label.color=$BAR_ACTIVE_ICON              \
                              label.width="dynamic"                     \
                              \
                              background.border_width=0                \
                              background.border_color=$BAR_ACTIVE_ICON  \
                              drawing=on
else
  sketchybar --set  $NAME     icon.highlight=true                       \
                              icon.padding_left=7                       \
                              icon.padding_right=-6                     \
                              \
                              label.color=$BAR_ACTIVE_ICON              \
                              label.width="dynamic"                     \
                              \
                              background.border_width=0                 \
                              background.border_color=$BAR_ACTIVE_ICON  \
                              drawing=on
fi
}

deactivate_space() {
if [ -z "${SID+x}" ] || [ -z "${SID}" ] || [ -z "${NAME+x}" ] || [ -z "${NAME}" ]; then
  return
fi

if [ "$(hget spaces $SID)" = "true" ]; then
  sketchybar --set   $NAME    icon.highlight=false            \
                              icon.padding_left=5             \
                              icon.padding_right=-2           \
                              \
                              label.color=$BAR_INACTIVE_ICON  \
                              label.width="dynamic"           \
                              \
                              background.border_width=0       \
                              drawing=on
else
  sketchybar --set  $NAME     icon.highlight=false            \
                              \
                              label.color=$BAR_INACTIVE_ICON  \
                              label.width="dynamic"           \
                              \
                              background.border_width=0       \
                              drawing=off
fi
}

refresh_current_workspace() {
  echo "Start refresh current workspace : Current spaces: $current_spaces"
  current_space=${2:-$(aerospace get active-space)}
  args=()

  for space in $(aerospace list); do
    icon_strip=" "
    apps=$(aerospace list | awk -v space="$space" '$1 == space {print $3}' | sort | uniq)
    if [ -n "$apps" ]; then
      while IFS= read -r app; do
        icon_strip+=" $($HOME/.config/sketchybar/plugins/icon_map.sh "$app")"
      done <<< "$apps"
      args+=(--set space.$space label="$icon_strip" drawing=on icon.padding_left=5 icon.padding_right=-2)
      hput spaces "$space" true
    else
      args+=(--set space.$space label="$icon_strip" drawing=on icon.padding_left=7 icon.padding_right=-6)
      hput spaces "$space" false
    fi
  done

  sketchybar -m "${args[@]}"
  echo "End refresh current workspace : Current spaces: $current_spaces"
}

refresh_workspaces() {
  echo "Start refresh workspaces : Current spaces: $current_spaces"
  # Get a list of all workspaces
  current_spaces=$(aerospace list-workspaces --all | awk '{print $1}')

  # Get the currently active workspace
  current_space=$(aerospace list-workspaces --focused | awk '{print $1}')

  # Initialize an empty array to store sketchybar arguments
  args=()

  # Iterate through each space
  for space in $current_spaces; do
    # Initialize an empty icon strip for this space
    icon_strip=" "

    # Get a list of windows in the current workspace
    apps=$(aerospace list-windows --workspace $space | awk '{print $3}' | sort | uniq)

    # If there are apps in this space
    if [ -n "$apps" ]; then
      # For each app in the space
      while IFS= read -r app; do
        # Add the app's icon to the icon strip
        icon_strip+=" $($HOME/.config/sketchybar/plugins/icon_map.sh "$app")"
      done <<< "$apps"

      # Add sketchybar arguments for a space with apps
      args+=(--set space.$space label="$icon_strip" drawing=on icon.padding_left=5 icon.padding_right=-2)

      # Mark this space as having apps
      echo "true" > /tmp/hashmap.spaces/$space
    else
      # If this is the current active space
      if [ "$current_space" = "$space" ]; then
        # Add sketchybar arguments for the current empty space
        args+=(--set space.$space label="$icon_strip" drawing=on icon.padding_left=7 icon.padding_right=-6)
      else
        # Add sketchybar arguments for other empty spaces
        args+=(--set space.$space label="$icon_strip" drawing=off icon.padding_left=7 icon.padding_right=-6)
      fi

      # Mark this space as not having apps
      echo "false" > /tmp/hashmap.spaces/$space
    fi
  done


  echo "End refresh workspaces : Current spaces: $current_spaces"
  echo "Current active space: $current_space"
  echo "Spaces refreshed"
  # Apply all the accumulated arguments to sketchybar
  sketchybar -m "${args[@]}"
}

case "$SENDER" in
  "refresh_current_workspace") refresh_current_workspace
    exit 0;
  ;;
  "refresh_workspaces") refresh_workspaces
    exit 0;
  ;;
esac

if [ "$SELECTED" = "true" ]; then
  activate_space
else
  deactivate_space
fi