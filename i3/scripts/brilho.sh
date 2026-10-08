#!/usr/bin/env bash
# Brilho em duas faixas: backlight (brightnessctl) e, abaixo do mínimo dele,
# o fator de software do xrandr (<= 1).
# Uso: brilho.sh down|up

SAIDA=eDP-1
GAMMA=1.1:1.0:0.85
PASSO_LUZ=5        # % do backlight
PASSO_FATOR=0.05
FATOR_MIN=0.05
APP_ID="BrilhoOSD"

# Descarta repetições da tecla enquanto outra execução ainda roda (ver volume.sh)
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/brilho-osd.lock"
flock -n 9 || exit 0

fator=$(xrandr --verbose | awk -v s="$SAIDA" '$1==s {achou=1} achou && /Brightness:/ {print $2; exit}')
fator=${fator:-1}
luz=$(brightnessctl get)
luz_max=$(brightnessctl max)
passo_luz=$(( luz_max * PASSO_LUZ / 100 ))

set_fator() {
    fator=$(awk -v n="$1" -v min="$FATOR_MIN" 'BEGIN {
        if (n < min) n = min
        if (n > 1) n = 1
        printf "%.2f", n
    }')
    xrandr --output "$SAIDA" --brightness "$fator" --gamma "$GAMMA"
}

fator_cheio() { awk -v f="$fator" 'BEGIN {exit !(f >= 1)}'; }

case "$1" in
    down)
        if (( luz > passo_luz )); then
            brightnessctl -q set "${PASSO_LUZ}%-"
        elif (( luz > 1 )); then
            brightnessctl -q set 1      # mínimo do backlight sem apagar a tela
        else
            set_fator "$(awk -v f="$fator" -v p="$PASSO_FATOR" 'BEGIN {print f - p}')"
        fi
        ;;
    up)
        if ! fator_cheio; then
            set_fator "$(awk -v f="$fator" -v p="$PASSO_FATOR" 'BEGIN {print f + p}')"
        else
            brightnessctl -q set "+${PASSO_LUZ}%"
        fi
        ;;
esac

# OSD no mesmo estilo do volume
if fator_cheio; then
    valor=$(( $(brightnessctl get) * 100 / luz_max ))
    msg="${valor}"
else
    valor=$(awk -v f="$fator" 'BEGIN {printf "%d", f * 100}')
    msg="Escuro ${valor}"
fi
dunstify -a "$APP_ID" -r 9998 -h int:value:"$valor" -t 1000 "$msg"
