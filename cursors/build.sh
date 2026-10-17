#!/bin/sh
# Gera o tema de cursor "Circle": círculo vazado no ponteiro normal e
# preenchido no que é clicável (links, botões). O cursor de texto também é o
# círculo vazado, para não virar um "I" sobre o terminal. Os outros
# (redimensionar, espera) vêm do Adwaita pelo Inherits do index.theme.
# Precisa de imagemagick e xcursorgen. Rode de novo depois de mudar o desenho.
set -e
cd "$(dirname "$0")/Circle"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# desenha um círculo de tamanho $1; $2 = fill ou ring
draw() {
	size=$1; c=$((size / 2)); r=$((size * 5 / 16)); w=$((size / 12 + 1))
	if [ "$2" = fill ]; then
		# cinza médio: aparece cheio tanto em fundo claro quanto escuro
		convert -size ${size}x${size} xc:none -fill "#a0a0a0" -stroke black -strokewidth $((size / 48 + 1)) \
			-draw "circle $c,$c $c,$((c - r))" "$tmp/$2-$size.png"
	else
		# anel branco com contorno preto por dentro e por fora, visível em qualquer fundo
		convert -size ${size}x${size} xc:none -fill none \
			-stroke black -strokewidth $((w + 2)) -draw "circle $c,$c $c,$((c - r))" \
			-stroke white -strokewidth $w -draw "circle $c,$c $c,$((c - r))" "$tmp/$2-$size.png"
	fi
}

for kind in ring fill; do
	: > "$tmp/$kind.cfg"
	for size in 24 32 48 64; do
		draw $size $kind
		echo "$size $((size / 2)) $((size / 2)) $tmp/$kind-$size.png" >> "$tmp/$kind.cfg"
	done
done

rm -rf cursors && mkdir cursors
xcursorgen "$tmp/ring.cfg" cursors/left_ptr
xcursorgen "$tmp/fill.cfg" cursors/pointer
cd cursors
for name in default arrow top_left_arrow left_arrow text xterm ibeam; do ln -s left_ptr $name; done
for name in hand1 hand2 pointing_hand 9d800788f1b08800ae810202380a0822 e29285e634086352946a0e7090d73106; do
	ln -s pointer $name
done
