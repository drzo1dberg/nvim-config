# nvim-config

Meine Neovim-Konfiguration, kickstart-basiert mit lazy.nvim, gepflegt auf WSL2 Debian und gedacht für jede weitere Debian-Maschine. Dieses Repo ist auf der Hauptmaschine direkt als `~/.config/nvim` ausgecheckt: Config editieren heißt Repo editieren, committen, pushen, fertig. Kein Sync-Schritt.

## Installation auf einer neuen Maschine

Der direkte Weg, empfohlen:

```bash
git clone git@github-private:drzo1dberg/nvim-config.git ~/.config/nvim
~/.config/nvim/install.sh
nvim
```

Liegt der Clone woanders, setzt `install.sh` stattdessen einen Symlink von `~/.config/nvim` auf den Clone und sichert eine eventuell vorhandene Config vorher in ein Zeitstempel-Backup.

Beim ersten Start installiert lazy.nvim alle Plugins anhand der versionierten `lazy-lock.json` selbst, danach `:checkhealth` laufen lassen.

## Abhängigkeiten

`install.sh` prüft alles und sagt, was fehlt und wie es zu installieren ist:

- `nvim` ab 0.11, auf Debian am besten das Release-Binary statt apt
- `git`, `make`, `gcc` für telescope-fzf-native und LuaSnip
- `ripgrep` für live_grep, `fd` für find_files. Debian nennt das Paket `fd-find` und das Binary `fdfind`, das Script legt den `fd`-Symlink selbst an
- `tree-sitter` CLI, zwingend weil nvim-treesitter auf dem main-Branch läuft. Installation über `cargo install tree-sitter-cli` oder npm
- `unzip` für Mason-Downloads
- `xclip` für das System-Clipboard. Unter WSL2 mit WSLg reicht es ebenfalls, nativ sowieso

Für die Icons im UI braucht das Terminal einen Nerd Font.

## Maschinen-Spezifisches

- **Obsidian lädt nur mit gemountetem Work-Vault.** Die Spec in `lua/custom/plugins/obsidian.lua` prüft per `cond`, ob der OneDrive-Pfad existiert. Auf dem Heim-Debian ohne den Mount bleibt das Plugin komplett aus, alle anderen Plugins laufen normal. Die Obsidian-Wrapper-Kommandos wie `ObsidianThisWeek` stehen dann nicht zur Verfügung.
- **Clipboard unter WSL:** funktioniert über xclip und WSLg in beide Richtungen, getestet. Einzige bekannte Schwäche: yank und sofortiges `:q` kann den Inhalt verlieren, weil der xclip-Kindprozess beim Beenden stirbt, bevor WSLg synct. Falls das nervt, liegt im Setup-Guide im Repo `bash-skript-sammlung` ein `g:clipboard`-Snippet auf clip.exe-Basis als Fallback.
