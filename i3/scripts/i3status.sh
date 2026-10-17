#!/bin/sh
# i3status para a barra do i3, com o dia da semana em duas letras (Su Mo Tu We Th Fr Sa):
# o %a do bloco "tztime date" sai em inglês com três letras e o sed corta a última
export LC_TIME=C
exec i3status --config ~/.config/i3status/i3status.conf |
	sed -u -E 's/("instance":"date"[^}]*"full_text":")(Su|Mo|Tu|We|Th|Fr|Sa)[a-z]/\1\2/'
