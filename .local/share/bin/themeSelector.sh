selected=$(ls ~/Templates | rofi -dmenu -p "Run: ")

sh ~/.local/share/bin/changeTheme.sh ~/Templates/$selected
