#!/usr/bin/env bash
# Richtet diese nvim-Config auf einer neuen Maschine ein.
# Zielzustand: dieses Repo ist ~/.config/nvim, direkt ausgecheckt oder per Symlink.
#
# Optionen:
#   --obsidian-location <pfad>  legt den Obsidian-Vault an diesem Pfad an,
#                               inklusive Zettelkasten-Ordnerstruktur, und
#                               schreibt ihn nach ~/.config/obsidian-vault.
#                               Diese Datei lesen nvim UND die Shell-Aliases
#                               vl und vault, eine Wahrheit fuer beide.
#
# Richtet ausserdem den woechentlichen Zettelkasten-Archiver ein, montags 09:00,
# als systemd-User-Timer mit Persistent=true: verpasste Montage werden beim
# naechsten Start der Distro nachgeholt, wichtig unter WSL. Ohne systemd
# faellt es auf einen crontab-Eintrag zurueck. Braucht zk-archive.sh aus dem
# Repo bash-tools-and-scripts.
set -euo pipefail

vault=""
while [ $# -gt 0 ]; do
  case "$1" in
    --obsidian-location)
      shift
      vault="${1:?--obsidian-location braucht einen Pfad}"
      ;;
    --obsidian-location=*)
      vault="${1#*=}"
      ;;
    -h|--help)
      sed -n '2,17p' "$0"
      exit 0
      ;;
    *)
      echo "Unbekannte Option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="$HOME/.config/nvim"

if [ "$repo" = "$target" ]; then
  echo "Repo liegt bereits unter $target, nichts zu verlinken."
else
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    backup="$HOME/.config/nvim-backup-$(date +%F-%H%M%S)"
    mv "$target" "$backup"
    echo "Bestehende Config gesichert: $backup"
  fi
  mkdir -p "$HOME/.config"
  ln -sfn "$repo" "$target"
  echo "Symlink gesetzt: $target -> $repo"
fi

if [ -n "$vault" ]; then
  vault="${vault/#\~/$HOME}"
  case "$vault" in /*) ;; *) vault="$PWD/$vault" ;; esac
  # dieselbe Ordnerstruktur wie im Work-Vault, note_path_func erwartet sie
  mkdir -p "$vault/Zettelkasten" "$vault/Vorlagen" "$vault/Architektur Decision Record"
  mkdir -p "$HOME/.config"
  printf '%s\n' "$vault" > "$HOME/.config/obsidian-vault"
  echo
  echo "Obsidian-Vault: $vault"
  echo "Pfad gespeichert in ~/.config/obsidian-vault, gilt fuer nvim und die vl/vault-Aliases."
fi

# --- Zettelkasten-Archiver woechentlich am Montag -----------------------------
zk="$HOME/.local/bin/zk-archive"
if [ ! -e "$zk" ]; then
  zk_src="$HOME/github-repos/drzo1dberg/bash-tools-and-scripts/zk-archive.sh"
  if [ -f "$zk_src" ]; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$zk_src" "$zk"
    echo "zk-archive nach ~/.local/bin verlinkt."
  fi
fi

echo
if [ -e "$zk" ]; then
  mkdir -p "$HOME/.config/systemd/user"
  cat > "$HOME/.config/systemd/user/zk-archive.service" <<'UNIT'
[Unit]
Description=Zettelkasten-Archiver, verschiebt alte Notizen in Wochenordner

[Service]
Type=oneshot
ExecStart=%h/.local/bin/zk-archive --apply
UNIT
  cat > "$HOME/.config/systemd/user/zk-archive.timer" <<'UNIT'
[Unit]
Description=Zettelkasten-Archiver woechentlich am Montag

[Timer]
OnCalendar=Mon *-*-* 09:00
Persistent=true

[Install]
WantedBy=timers.target
UNIT
  if systemctl --user daemon-reload 2>/dev/null \
     && systemctl --user enable --now zk-archive.timer 2>/dev/null; then
    echo "Archiv-Timer aktiv: montags 09:00, verpasste Laeufe werden nachgeholt."
  elif command -v crontab >/dev/null 2>&1; then
    ( crontab -l 2>/dev/null | grep -v 'zk-archive'; echo "0 9 * * 1 $zk --apply" ) | crontab -
    echo "Kein systemd-User-Manager, Archiver laeuft stattdessen per crontab montags 09:00."
    echo "Achtung: cron holt verpasste Laeufe nicht nach, wenn die Maschine aus war."
  else
    echo "Weder systemd-User-Manager noch crontab verfuegbar, Archiver bitte manuell einplanen."
  fi
else
  echo "zk-archive.sh nicht gefunden, Archiv-Timer uebersprungen."
  echo "Repo bash-tools-and-scripts clonen und install.sh erneut ausfuehren."
fi

echo
echo "Abhaengigkeiten:"
missing=0
need() {
  if command -v "$1" >/dev/null 2>&1; then
    printf '  ok      %s\n' "$1"
  else
    printf '  FEHLT   %-12s -> %s\n' "$1" "$2"
    missing=1
  fi
}

need nvim "Release-Binary von github.com/neovim/neovim, Version 0.11+"
need git "sudo apt install git"
need make "sudo apt install make"
need gcc "sudo apt install gcc"
need rg "sudo apt install ripgrep"
need unzip "sudo apt install unzip"
need tree-sitter "cargo install tree-sitter-cli  oder  npm install -g tree-sitter-cli"
need xclip "sudo apt install xclip"

# Debian liefert fd als fdfind; die Config erwartet fd im PATH
if command -v fd >/dev/null 2>&1; then
  printf '  ok      %s\n' "fd"
elif command -v fdfind >/dev/null 2>&1; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  printf '  ok      %s\n' "fd, Symlink auf fdfind in ~/.local/bin angelegt"
else
  printf '  FEHLT   %-12s -> %s\n' "fd" "sudo apt install fd-find"
  missing=1
fi

echo
if [ "$missing" -eq 0 ]; then
  echo "Alles da. Erster Start: nvim, lazy.nvim installiert die Plugins anhand der lazy-lock.json."
else
  echo "Erst die fehlenden Abhaengigkeiten installieren, dann nvim starten."
fi
exit 0
