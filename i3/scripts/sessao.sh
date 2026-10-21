#!/bin/sh
# Menu de sessão no rofi ($mod+l): apagar a tela, bloquear ou sair do i3, sempre com "bye" antes
choice=$(printf 'apagar a tela\nbloquear\nsair da sessão\n' | rofi -dmenu -i -p sessão) || exit 0
bye="$(dirname "$(readlink -f "$0")")/bye.sh"

case "$choice" in
	"apagar a tela") "$bye" apagar ;;
	bloquear) "$bye" bloquear ;;
	"sair da sessão") "$bye" sair ;;
esac
