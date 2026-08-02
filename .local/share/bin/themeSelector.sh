#!/usr/bin/env sh

themeDir="$HOME/Templates"
scrDir="$(dirname "$(realpath "$0")")"

# Generate list and pipe directly to rofi
selected=$(for theme in "$themeDir"/*/; do
    [ ! -d "$theme" ] && continue
    theme_name=$(basename "$theme")
    thumb=$(find "$theme/Wallpapers" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) -print -quit 2>/dev/null)
    [ -z "$thumb" ] && thumb=""
    printf "%s\t50\t%s\n" "$theme_name" "$thumb"
done | rofi -dmenu -p "Select Theme:" \
    -theme-str "element-icon { icon-size: 120px; }" \
    -theme-str "element-text { children: [ box-icon ]; }")

[ -z "$selected" ] && exit 0

theme_name=$(printf "%s" "$selected" | cut -f1)
[ -z "$theme_name" ] && exit 0

sh "$scrDir/changeTheme.sh" "$themeDir/$theme_name"
