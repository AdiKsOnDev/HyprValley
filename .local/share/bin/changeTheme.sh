#!/usr/bin/env sh

scrDir=`dirname "$(realpath "$0")"`

# Check if argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <Theme_Path>"
    exit 1
fi

# Assigning arguments to variables
theme_path=$1
wallpapers_path="$HOME/Pictures/Wallpapers"
waybar_colors="$HOME/.config/waybar/colors.css"
rofi_colors="$HOME/.config/rofi/colors.rasi"
sway_colors="$HOME/.config/swaylock/config"
obsidian_conf="$HOME/Documents/Second Brain/.obsidian/appearance.json"
system_theme_config="$HOME/.config/hypr/theme/theme.conf"

# Replace wallpapers
if [ -d "$theme_path/Wallpapers" ]; then
    rm -rf "$wallpapers_path/"
    mkdir $wallpapers_path
    mkdir "$wallpapers_path/tmp"
    cp -r "$theme_path/Wallpapers"/* "$wallpapers_path"
    echo "Wallpapers replaced successfully."
else
    echo "Wallpapers folder not found in the provided path."
fi

# Replace waybar colors
if [ -f "$theme_path/colors.css" ]; then
    cp "$theme_path/colors.css" "$waybar_colors"
    echo "Waybar colors replaced successfully."
else
    echo "colors.css not found in the provided path."
fi

# Replace rofi colors
if [ -f "$theme_path/colors.rasi" ]; then
    cp "$theme_path/colors.rasi" "$rofi_colors"
    echo "Rofi colors replaced successfully."
else
    echo "colors.rasi not found in the provided path."
fi

# Replace rofi colors
if [ -f "$theme_path/sway-config" ]; then
    cp "$theme_path/sway-config" "$sway_colors"
    echo "Swaylock colors replaced successfully."
else
    echo "sway-config not found in the provided path."
fi

if [ -f "$theme_path/appearance.json" ]; then
    cp "$theme_path/appearance.json" "$obsidian_conf"
    echo "Obsidian copied successfully"
else
    echo "obsidian_conf not found in the provided path."
fi

if [ -f "$theme_path/theme.conf" ]; then
    cp "$theme_path/theme.conf" "$system_theme_config"
else
    echo "theme config not found in the provided path."
fi

sh $HOME/.local/share/bin/swwwallpaper.sh -n
killall waybar
waybar
hyprctl reload
