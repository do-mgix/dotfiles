#!/bin/sh
# Notifica quando o i3 é reiniciado ($mod+Shift+r). Roda via exec_always, que
# também dispara no login; o restart do i3 reexecuta o mesmo processo, então o
# PID igual ao salvo na última execução indica que foi um restart.
ESTADO="${XDG_RUNTIME_DIR:-/tmp}/i3-pid"
pid=$(pidof -s i3)
[ "$(cat "$ESTADO" 2>/dev/null)" = "$pid" ] && dunstify -a i3 -t 2000 "i3 reiniciado"
echo "$pid" > "$ESTADO"
