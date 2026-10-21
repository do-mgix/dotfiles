#!/bin/sh
# Mostra "bye" no centro da tela e então executa a ação de saída.
# Uso: bye.sh apagar|bloquear|sair
#   apagar   só desliga o monitor (DPMS); nada é bloqueado, qualquer tecla ou mouse acorda
#   bloquear i3lock com fundo preto
#   sair     encerra a sessão do i3
# O welcome.py bloqueia até o aviso sumir, o que também dá tempo de soltar as teclas
# do atalho antes de apagar a tela (senão o próprio key release a acordaria).
"$(dirname "$(readlink -f "$0")")/welcome.py" "bye" 1000

case "$1" in
	apagar) xset dpms force off ;;
	bloquear) i3lock --color=000000 ;;
	sair) i3-msg exit ;;
	*) echo "uso: $0 apagar|bloquear|sair" >&2; exit 1 ;;
esac
