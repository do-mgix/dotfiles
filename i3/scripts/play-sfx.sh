#!/bin/bash
# Uso: ./play-sfx-logic.sh <arquivo_audio> <fator_0_100> <static_true_false>
# Exemplo 1 (Dinâmico): ./play-sfx-logic.sh som.mp3 50 false  -> 50% do volume ATUAL do sistema
# Exemplo 2 (Estático): ./play-sfx-logic.sh som.mp3 50 true   -> 50% do volume MÁXIMO (ignora volume atual)


FILE="$1"
FACTOR="${2:-50}"       # Padrão 50 se não informado
STATIC="${3:-false}"    # Padrão false (dinâmico) se não informado

# Função para tocar e ajustar volume
play_with_volume() {
    local target_vol="$1"
    
    # Inicia reprodução em background
    paplay "$FILE" &
    PID=$!
    
    # Aguarda o fluxo ser criado (ajuste fino se necessário)
    sleep 1
    
    # Pega o índice do último sink-input criado
    local INDEX=$(pactl list sink-inputs short | tail -n 1 | cut -f1)
    
    if [ -n "$INDEX" ]; then
        # Aplica o volume calculado
        pactl set-sink-input-volume "$INDEX" "${target_vol}%"
    fi
    
    wait $PID
}

if [ "$STATIC" = "true" ]; then
    # MODO ESTÁTICO: O fator é o volume direto (0-100%)
    # Ex: Factor 50 -> 50%
    play_with_volume "$FACTOR"
else
    # MODO DINÂMICO: O fator é uma porcentagem do volume ATUAL do sistema
    # Ex: Sistema em 80%, Factor 50 -> Resultado 40%
    
    # Obtém volume atual do sink padrão (ex: "65%")
    CURRENT_VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | head -1 | tr -d '%')
    
    # Calcula: (Atual * Fator) / 100
    # Usa bc para suportar decimais se necessário, mas pactl aceita inteiros
    TARGET_VOL=$(echo "($CURRENT_VOL * $FACTOR) / 100" | bc)
    
    # Garante que não seja 0 (silêncio) se o cálculo for muito baixo
    if [ "$TARGET_VOL" -lt 1 ]; then TARGET_VOL=1; fi
    
    play_with_volume "$TARGET_VOL"
fi   
