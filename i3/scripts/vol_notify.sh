#!/bin/bash
# Configurações
MAX_VOL=100
STEP=1
APP_ID="VolumeOSD"

case "$1" in
    up)
        CURRENT=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | head -1 | tr -d '%')
        NEW_VOL=$((CURRENT + STEP))
        [ "$NEW_VOL" -gt "$MAX_VOL" ] && NEW_VOL=$MAX_VOL
        pactl set-sink-volume @DEFAULT_SINK@ "${NEW_VOL}%"
        ;;
    down)
        pactl set-sink-volume @DEFAULT_SINK@ -${STEP}%
        ;;
    toggle)
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        ;;
esac

# Captura estado
VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | head -1 | tr -d '%')
MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -o 'yes\|no')

# Lógica Simples: Se mudo, barra 0. Se não, barra = volume.
if [ "$MUTE" = "yes" ]; then
    BAR_VALUE=0
    MSG="Mudo"
else
    BAR_VALUE=$VOL
    MSG="${VOL}"
fi

# Notificação minimalista (sem ícone, sem urgência variável)
# A barra branca será desenhada baseada em BAR_VALUE
dunstify -a "$APP_ID" -r 9999 -h int:value:"$BAR_VALUE" -t 1000 "$MSG"   
