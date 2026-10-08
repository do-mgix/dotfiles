#!/usr/bin/env bash
# Volume com OSD do dunst e efeito sonoro.
# Uso: volume.sh up|down|toggle [tema_de_som]
#
# Segurar a tecla dispara uma execução por repetição. Com a RAM apertada elas
# se acumulam e continuam mudando o volume depois de soltar a tecla; o flock -n
# descarta quem chega enquanto outra execução ainda está rodando.

MAX=100
APP_ID="VolumeOSD"
SFX="$(dirname "$(readlink -f "$0")")/../sounds/${2:-playstation}/normal_volume.mp3"
SFX_PID="${XDG_RUNTIME_DIR:-/tmp}/volume-sfx.pid"

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/volume-osd.lock"
flock -n 9 || exit 0

vol() { pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | head -1 | tr -d '%'; }

# Passo por faixa: 0-10 de 1 em 1, 10-50 de 5 em 5, 50-100 de 10 em 10.
# Subindo, o limite pertence à faixa de cima (10 -> 15); descendo, à de baixo
# (10 -> 9). Valores fora da grade encaixam no múltiplo seguinte (23 -> 25).
proximo() {
    local v=$1 p
    if [ "$2" = up ]; then
        if   (( v < 10 )); then p=1
        elif (( v < 50 )); then p=5
        else p=10; fi
        v=$(( (v / p + 1) * p ))
        (( v > MAX )) && v=$MAX
    else
        if   (( v <= 10 )); then p=1
        elif (( v <= 50 )); then p=5
        else p=10; fi
        v=$(( (v + p - 1) / p * p - p ))
        (( v < 0 )) && v=0
    fi
    echo "$v"
}

tocar_sfx() {
    [ -f "$SFX" ] || return
    # Interrompe o efeito anterior para não empilhar sons ao segurar a tecla
    [ -f "$SFX_PID" ] && kill "$(cat "$SFX_PID")" 2>/dev/null
    mpg123 -q "$SFX" 9>&- &
    echo $! > "$SFX_PID"
}

case "$1" in
    up|down)
        pactl set-sink-volume @DEFAULT_SINK@ "$(proximo "$(vol)" "$1")%"
        tocar_sfx
        ;;
    toggle)
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        ;;
esac

if [ "$(pactl get-sink-mute @DEFAULT_SINK@)" = "Mute: yes" ]; then
    valor=0
    msg="Mudo"
else
    valor=$(vol)
    msg="${valor}"
fi

dunstify -a "$APP_ID" -r 9999 -h int:value:"$valor" -t 1000 "$msg"
