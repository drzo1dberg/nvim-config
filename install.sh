#!/usr/bin/env bash
# Richtet diese nvim-Config auf einer neuen Maschine ein.
# Zielzustand: dieses Repo ist ~/.config/nvim, direkt ausgecheckt oder per Symlink.
set -euo pipefail

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
