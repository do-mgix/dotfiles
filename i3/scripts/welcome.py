#!/usr/bin/env python3
"""Aviso centralizado na tela com o visual do dunst (fundo preto, texto branco
em negrito). O dunst 1.9 só tem uma posição global, então não dá para centralizar
uma notificação só; esta janela popup faz esse papel e some sozinha.

Uso: welcome.py [texto] [duração_ms]
"""
import sys

import gi

gi.require_version("Gdk", "3.0")
gi.require_version("Gtk", "3.0")
from gi.repository import Gdk, GLib, Gtk  # noqa: E402

texto = sys.argv[1] if len(sys.argv) > 1 else "Welcome!"
duracao = int(sys.argv[2]) if len(sys.argv) > 2 else 2000

css = Gtk.CssProvider()
css.load_from_data(b"""
window { background-color: #000000; }
label { color: #ffffff; font: bold 11pt "Noto Sans"; padding: 5px 8px; }
""")
Gtk.StyleContext.add_provider_for_screen(
    Gdk.Screen.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

# POPUP é override-redirect: o i3 não gerencia, não rouba o foco nem a encaixa
janela = Gtk.Window(type=Gtk.WindowType.POPUP)
janela.add(Gtk.Label(label=texto))
janela.set_position(Gtk.WindowPosition.CENTER)
janela.show_all()

GLib.timeout_add(duracao, Gtk.main_quit)
Gtk.main()
