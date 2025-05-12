#!/usr/bin/env bash

# Author: Jesse Mirabel (@sejjy)
# GitHub: https://github.com/sejjy/mechabar

# Rofi config
config="$HOME/.config/waybar/rofi/wifi-menu.rasi"

options=$(
  echo "Manual Entry"
  echo "Disable Wi-Fi"
)
option_disabled="Enable Wi-Fi"

# Rofi window override
override_ssid="entry { placeholder: \"Enter SSID\"; } listview { enabled: false; }"
override_password="entry { placeholder: \"Enter password\"; } listview { enabled: false; }"
override_disabled="inputbar { enabled: false; } listview { lines: 1; padding: 6px; }"

# Prompt for password
get_password() {
  rofi -dmenu -password -config "${config}" -theme-str "${override_password}" -p " "
}

while true; do
  wifi_list() {
    nmcli --fields "SECURITY,SSID" device wifi list |
      tail -n +2 |               # Skip header line
      sed 's/  */ /g' |          # Multiple spaces to single space
      sed -E "s/WPA*.?\S/󰤪 /g" | # Replace WPA* with wifi lock icon
      sed "s/^--/󰤨 /g" |         # Replace '--' (open networks) with wifi icon
      sed "s/󰤪  󰤪/󰤪/g" |         # Remove duplicate icons
      sed "/--/d"                # Remove lines containing '--'
  }

  # Get Wi-Fi status
  wifi_status=$(nmcli -fields WIFI g)

  case "$wifi_status" in
  *"enabled"*)
    selected_option=$(echo "$options"$'\n'"$(wifi_list)" |
      rofi -dmenu -i -selected-row 1 -config "${config}" -p " ")
    ;;
  *"disabled"*)
    selected_option=$(echo "$option_disabled" |
      rofi -dmenu -i -config "${config}" -theme-str "${override_disabled}")
    ;;
  esac

  # Extract selected SSID
  read -r selected_ssid <<<"${selected_option:3}"

  # Actions based on selected option
  case "$selected_option" in
  "")
    exit
    ;;
  "Enable Wi-Fi")
    notify-send "Scanning for networks..."
    nmcli radio wifi on
    nmcli device wifi rescan
    sleep 3
    ;;
  "Disable Wi-Fi")
    notify-send "Wi-Fi Disabled"
    nmcli radio wifi off
    sleep 1
    ;;
  "Manual Entry")
    # Prompt for SSID
    manual_ssid=$(rofi -dmenu -config "${config}" -theme-str "${override_ssid}" -p " ")

    # Exit if no option is selected
    if [ -z "$manual_ssid" ]; then
      exit
    fi

    wifi_password=$(get_password)

    if [ -z "$wifi_password" ]; then
      nmcli device wifi connect "$manual_ssid"
    else
      nmcli dev wifi con "$manual_ssid" password "$wifi_password"
    fi

    nmcli device wifi connect "$manual_ssid" password "$wifi_password" | grep "successfully" && notify-send "Connected to \"$manual_ssid\"."
    ;;
  *)
    # Get saved connections
    saved_connections=$(nmcli -g NAME connection)

    if echo "$saved_connections" | grep -qw "$selected_ssid"; then
      nmcli connection up id "$selected_ssid" | grep "successfully" && notify-send "Connected to \"$selected_ssid\"."
    else
      # Handle secure network connection
      if [[ "$selected_option" =~ ^"󰤪" ]]; then
        wifi_password=$(get_password)
      fi

      nmcli device wifi connect "$selected_ssid" password "$wifi_password" | grep "successfully" && notify-send "Connected to \"$selected_ssid\"."
    fi
    ;;
  esac
done
