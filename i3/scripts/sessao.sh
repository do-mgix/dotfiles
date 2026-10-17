#!/bin/sh
# Menu de sessão no rofi ($mod+l): bloquear a tela ou sair do i3
choice=$(printf 'bloquear\nsair da sessão\n' | rofi -dmenu -i -p sessão) || exit 0

case "$choice" in
	bloquear) i3lock --color=000000 ;;
	"sair da sessão") i3-msg exit ;;
esac
