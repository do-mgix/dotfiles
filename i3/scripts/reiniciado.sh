#!/bin/sh
# Mostra "Welcome!" no centro da tela quando o i3 é reiniciado ($mod+Shift+r).
# Roda via exec_always, que também dispara no login; o restart do i3 reexecuta o mesmo processo, então o
# PID igual ao salvo na última execução indica que foi um restart.
ESTADO="${XDG_RUNTIME_DIR:-/tmp}/i3-pid"
pid=$(pidof -s i3)
[ "$(cat "$ESTADO" 2>/dev/null)" = "$pid" ] && "$(dirname "$(readlink -f "$0")")/welcome.py" "Welcome!" &
echo "$pid" > "$ESTADO"
