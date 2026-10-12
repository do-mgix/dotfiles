#!/usr/bin/env python3
"""Salva e restaura a disposição de janelas do workspace atual do i3.

Uso: layout.py save | load <id> | delete | flush | move | install

Cada layout guarda a árvore do workspace (splits, abas, tamanhos e janelas
flutuantes) e, para cada janela, o comando que a abre e o diretório onde
rodava. Terminais (Alacritty) guardam o diretório do shell.

Os comandos aparecem no rofi (drun) como entradas .desktop: "Save Workspace
Layout", "Delete Workspace Layout" e um "Load Layout: <nome> (#id)" por
layout salvo. Também há "Flush Workspace", que fecha todas as janelas do
workspace atual, e "Move Workspace", que esvazia o workspace escolhido e leva
para ele o atual, com a mesma disposição.

Para carregar, o i3 cria placeholders com append_layout e os programas são
abertos um de cada vez, na ordem da árvore: o i3 encaixa cada janela nova no
primeiro placeholder compatível, então abrir em sequência mantém cada
terminal na sua posição.
"""

import json
import os
import re
import shlex
import subprocess
import sys
import tempfile
import time
from pathlib import Path

HOME = Path.home()
DADOS = Path(os.environ.get("XDG_DATA_HOME", HOME / ".local/share"))
LAYOUTS = DADOS / "i3-layouts"
APLICATIVOS = DADOS / "applications"
SCRIPT = Path(__file__).resolve()

TERMINAL_CLASSES = {"alacritty", "gnome-terminal"}
ESPERA_JANELA = 20   # segundos para cada programa abrir a janela
ESPERA_FECHAR = 10   # segundos para as janelas do workspace fecharem


# --- i3 -----------------------------------------------------------------

def i3(*args):
    return subprocess.run(["i3-msg", *args], capture_output=True, text=True).stdout


def nome_focado():
    return next(w["name"] for w in json.loads(i3("-t", "get_workspaces")) if w["focused"])


def workspace(nome):

    def achar(no):
        if no.get("type") == "workspace" and no["name"] == nome:
            return no
        for filho in no.get("nodes", []):
            achado = achar(filho)
            if achado:
                return achado

    return achar(json.loads(i3("-t", "get_tree")))


def folhas(no):
    """Janelas e placeholders do workspace, na ordem em que o i3 os percorre."""
    if not no.get("nodes") and not no.get("floating_nodes") and no.get("type") != "workspace":
        yield no
    for filho in no.get("nodes", []) + no.get("floating_nodes", []):
        yield from folhas(filho)


def placeholders(ws):
    # O placeholder também tem uma janela X (desenhada pelo i3), mas sem
    # window_properties; o swallows é esvaziado quando a janela real chega
    return [f for f in folhas(ws) if f.get("swallows")]


def janela_real(no):
    return bool(no.get("window") and no.get("window_properties") and not no.get("swallows"))


# --- descobrir como reabrir cada janela -----------------------------------

def pid_da_janela(janela):
    saida = subprocess.run(["xprop", "-id", str(janela), "_NET_WM_PID"],
                           capture_output=True, text=True).stdout
    m = re.search(r"= (\d+)", saida)
    return int(m.group(1)) if m else None


def filhos(pid):
    ids = []
    for tarefa in Path(f"/proc/{pid}/task").glob("*"):
        try:
            ids += (tarefa / "children").read_text().split()
        except OSError:
            pass
    return [int(i) for i in ids]


def cwd(pid):
    try:
        return os.readlink(f"/proc/{pid}/cwd")
    except (OSError, TypeError):
        return str(HOME)


def dirs_desktop():
    dirs = [DADOS] + [Path(d) for d in os.environ.get(
        "XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":") if d]
    dirs += [HOME / ".local/share/flatpak/exports/share", Path("/var/lib/flatpak/exports/share")]
    return [d / "applications" for d in dirs]


def ler_desktop(arquivo):
    campos = {}
    secao = None
    for linha in arquivo.read_text(errors="ignore").splitlines():
        if linha.startswith("["):
            secao = linha.strip()
        elif secao == "[Desktop Entry]" and "=" in linha:
            chave, valor = linha.split("=", 1)
            campos.setdefault(chave.strip(), valor.strip())
    return campos


def comando_desktop(classe, instancia):
    """Exec do .desktop cujo StartupWMClass (ou nome do arquivo) bate com a janela."""
    alvos = {classe.lower(), instancia.lower()} - {""}
    candidatos = []
    for d in dirs_desktop():
        for arquivo in d.glob("*.desktop"):
            if arquivo.name.startswith("i3-layout-"):
                continue
            try:
                campos = ler_desktop(arquivo)
            except OSError:
                continue
            if "Exec" not in campos or campos.get("Hidden") == "true":
                continue
            wm = campos.get("StartupWMClass", "").lower()
            if wm in alvos:
                return campos["Exec"]
            if arquivo.stem.lower() in alvos or arquivo.stem.lower().split(".")[-1] in alvos:
                candidatos.append(campos["Exec"])
    return candidatos[0] if candidatos else None


def limpar_exec(exec_):
    # Remove os códigos de campo (%u, %F...) e os marcadores do flatpak (@@u ... @@)
    return [a for a in shlex.split(exec_) if not re.fullmatch(r"%[a-zA-Z]|@@[uf]?", a)]


def descrever(no):
    """Comando, diretório e classe para reabrir a janela, ou None se não der."""
    props = no.get("window_properties", {})
    classe = props.get("class") or ""
    instancia = props.get("instance") or ""
    pid = pid_da_janela(no["window"])

    if classe.lower() in TERMINAL_CLASSES:
        # No gnome-terminal todas as janelas são um processo só e não dá para
        # saber o diretório de cada uma; ele volta como Alacritty na home.
        dir_ = str(HOME)
        if classe.lower() == "alacritty" and pid:
            shells = filhos(pid)
            dir_ = cwd(shells[0]) if shells else cwd(pid)
        return {"cmd": ["alacritty", "--working-directory", dir_],
                "cwd": dir_, "class": "Alacritty"}

    exec_ = comando_desktop(classe, instancia)
    if exec_:
        cmd = limpar_exec(exec_)
    elif pid:
        try:
            cmd = [a for a in Path(f"/proc/{pid}/cmdline").read_text().split("\0") if a]
        except OSError:
            return None
    else:
        return None
    return {"cmd": cmd, "cwd": cwd(pid) if pid else str(HOME), "class": classe}


# --- serialização ---------------------------------------------------------

def serializar(no, apps):
    """Converte um nó da árvore do i3 no formato do append_layout."""
    percent = no.get("percent") or 1
    if no.get("window"):
        if not janela_real(no):
            return None
        app = descrever(no)
        if not app:
            return None
        apps.append(app)
        return {"type": "con", "percent": percent,
                "swallows": [{"class": f"^{re.escape(app['class'])}$"}]}

    nos = [n for n in (serializar(f, apps) for f in no.get("nodes", [])) if n]
    if not nos:
        return None
    if len(nos) == 1:
        return {**nos[0], "percent": percent}
    total = sum(n["percent"] for n in nos)
    for n in nos:
        n["percent"] /= total   # reparte o espaço de janelas que ficaram de fora
    return {"type": "con", "layout": no["layout"], "percent": percent, "nodes": nos}


def serializar_workspace(ws):
    apps = []
    raiz = serializar({"layout": ws["layout"], "nodes": ws["nodes"]}, apps)
    arvore = [raiz] if raiz else []
    for flutuante in ws.get("floating_nodes", []):
        janela = next((f for f in folhas(flutuante) if janela_real(f)), None)
        no = serializar(janela, apps) if janela else None
        if no:
            arvore.append({"type": "floating_con", "floating": "user_on",
                           "rect": flutuante["rect"], "nodes": [no]})
    return arvore, apps


# --- rofi, notificações e entradas .desktop -----------------------------

def rofi(prompt, opcoes=()):
    r = subprocess.run(["rofi", "-dmenu", "-i", "-p", prompt, "-l", str(len(opcoes))],
                       input="\n".join(opcoes), capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else ""


def avisar(msg):
    subprocess.run(["dunstify", "-a", "Layouts", "-t", "3000", "Layout", msg])


def escrever_desktop(nome_arquivo, nome, args):
    APLICATIVOS.mkdir(parents=True, exist_ok=True)
    (APLICATIVOS / nome_arquivo).write_text(
        "[Desktop Entry]\nType=Application\nTerminal=false\nIcon=view-grid\n"
        f"Name={nome}\nExec={shlex.quote(str(SCRIPT))} {args}\n")


def instalar():
    escrever_desktop("i3-layout-save.desktop", "Save Workspace Layout", "save")
    escrever_desktop("i3-layout-delete.desktop", "Delete Workspace Layout", "delete")
    escrever_desktop("i3-layout-flush.desktop", "Flush Workspace", "flush")
    escrever_desktop("i3-layout-move.desktop", "Move Workspace", "move")


def layouts_salvos():
    salvos = []
    for arquivo in LAYOUTS.glob("*.json"):
        try:
            salvos.append(json.loads(arquivo.read_text()))
        except (OSError, ValueError):
            pass
    return sorted(salvos, key=lambda l: l["id"])


# --- comandos -------------------------------------------------------------

def salvar():
    arvore, apps = serializar_workspace(workspace(nome_focado()))
    if not apps:
        avisar("Nenhuma janela para salvar neste workspace")
        return
    nome = " ".join(rofi("Nome do layout").split())
    if not nome:
        return

    LAYOUTS.mkdir(parents=True, exist_ok=True)
    id_ = max((l["id"] for l in layouts_salvos()), default=0) + 1
    layout = {"id": id_, "name": nome, "created": time.strftime("%Y-%m-%d %H:%M"),
              "tree": arvore, "apps": apps}
    (LAYOUTS / f"{id_}.json").write_text(json.dumps(layout, indent=2, ensure_ascii=False))
    escrever_desktop(f"i3-layout-{id_}.desktop", f"Load Layout: {nome} (#{id_})", f"load {id_}")
    instalar()
    avisar(f"Salvo: {nome} (#{id_}), {len(apps)} janela(s)")


def limpar(nome):
    """Fecha as janelas (e restos de placeholders) do workspace e espera sumirem."""
    ws = lambda: workspace(nome) or {"type": "workspace"}
    for f in folhas(ws()):
        i3(f"[con_id={f['id']}] kill")
    prazo = time.time() + ESPERA_FECHAR
    while list(folhas(ws())):
        if time.time() > prazo:
            return False
        time.sleep(0.2)
    return True


def esvaziar():
    nome = nome_focado()
    if not limpar(nome):
        avisar(f"Alguma janela do workspace {nome} não fechou")


def mover():
    origem = nome_focado()
    outros = [w["name"] for w in json.loads(i3("-t", "get_workspaces")) if w["name"] != origem]
    destino = rofi(f"Mover {origem} para", outros)
    if not destino or destino == origem:
        return
    if not limpar(destino):
        avisar(f"Alguma janela do workspace {destino} não fechou; nada foi movido")
        return
    ws = workspace(origem)
    alvo = destino.replace('"', '\\"')
    # Mover o próprio workspace faz o i3 embrulhar os filhos num container
    # e levar a disposição inteira; as flutuantes vão uma a uma
    if ws.get("nodes"):
        i3(f'[con_id={ws["id"]}] move container to workspace "{alvo}"')
    for flutuante in ws.get("floating_nodes", []):
        i3(f'[con_id={flutuante["id"]}] move container to workspace "{alvo}"')
    i3(f'workspace "{alvo}"')


def carregar(id_):
    arquivo = LAYOUTS / f"{id_}.json"
    if not arquivo.exists():
        avisar(f"Layout #{id_} não existe")
        return
    layout = json.loads(arquivo.read_text())
    # Fixa o workspace no início: trocar de workspace durante o carregamento
    # não pode fazer o script fechar janelas de outro
    nome = nome_focado()
    ws = lambda: workspace(nome) or {"type": "workspace"}

    if not limpar(nome):
        avisar("Alguma janela não fechou; layout não carregado")
        return

    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as tmp:
        tmp.write("\n".join(json.dumps(no) for no in layout["tree"]))
    i3(f'workspace "{nome}"; append_layout "{tmp.name}"')
    os.unlink(tmp.name)

    falhas = 0
    for app in layout["apps"]:
        antes = len(placeholders(ws()))
        dir_ = app["cwd"] if os.path.isdir(app["cwd"]) else str(HOME)
        try:
            subprocess.Popen(app["cmd"], cwd=dir_, start_new_session=True,
                             stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL)
        except OSError:
            falhas += 1
            continue
        prazo = time.time() + ESPERA_JANELA
        while len(placeholders(ws())) >= antes and time.time() < prazo:
            time.sleep(0.2)

    # Placeholders que ninguém ocupou ficariam como buracos vazios na tela
    for p in placeholders(ws()):
        falhas += 1
        i3(f"[con_id={p['id']}] kill")
    if falhas:
        avisar(f"{layout['name']}: {falhas} janela(s) não abriram")


def apagar():
    salvos = layouts_salvos()
    if not salvos:
        avisar("Nenhum layout salvo")
        return
    escolha = rofi("Apagar layout", [f"#{l['id']}  {l['name']}" for l in salvos])
    m = re.match(r"#(\d+)", escolha)
    if not m:
        return
    id_ = m.group(1)
    (LAYOUTS / f"{id_}.json").unlink(missing_ok=True)
    (APLICATIVOS / f"i3-layout-{id_}.desktop").unlink(missing_ok=True)
    avisar(f"Apagado: {escolha}")


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "save":
        salvar()
    elif cmd == "load" and len(sys.argv) > 2 and sys.argv[2].isdigit():
        carregar(sys.argv[2])
    elif cmd == "delete":
        apagar()
    elif cmd == "flush":
        esvaziar()
    elif cmd == "move":
        mover()
    elif cmd == "install":
        instalar()
    else:
        sys.exit(__doc__.split("\n\n")[1])


if __name__ == "__main__":
    main()
