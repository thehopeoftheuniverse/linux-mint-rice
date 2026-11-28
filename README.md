# Linux Mint / Debian Dotfiles (Unified Power-User Rice)

A complete X11 workstation & rice managed with [chezmoi](https://www.chezmoi.io/), combining a full developer/terminal stack (**LazyVim, Kitty, Tmux, Yazi, Zsh/Oh My Zsh, Starship, Atuin**) with hardened **Linux Mint / Debian / Ubuntu** compatibility, reversible backups, and a live **UI Studio**.

## Highlights

- **Unified UI Studio (`Super + T` or Polybar Palette Icon)**
  - **Themes** (synced live across i3, Polybar, Rofi, Kitty, Dunst, btop, i3lock & wallpapers via [theme-switch.sh](dot_config/scripts/ui/executable_theme-switch.sh)):
    - `catppuccin-mocha` — Default pastel dark
    - `ultra-instinct` — Dragon Ball **Ultra Instinct** Black UI (`#050508` obsidian void, silver-white `#f4f7ff`, icy cyan `#7df9ff` & aura violet `#c084fc`, custom wallpaper)
    - `ultra-instinct-omen` — Deep void black + electric sapphire
    - `tokyo-night` — Midnight neon blue
    - `rose-pine` — Rosé Pine twilight glass (`sakura-gate.jpg` wallpaper)
  - **4 Polybar Layouts**: `sleek` (full-width translucent top bar with CPU/RAM stats), `floating` (detached pill bar with accent border), `minimal` (clean floating island with CPU/RAM), `telemetry` (top bar + bottom CPU/GPU bar)
  - **Rofi Launcher & Powermenu Style Pickers** across bundled templates
  - **Visual Thumbnail Wallpaper Picker** (`Super + Shift + W`)
  - **Picom Compositor Profiles** (`full`, `minimal`, `off`) — auto-adapts across Picom v9/v10 (Debian 12 / Mint 21–22), Picom v12+ (animations), and VMs (`xrender` fallback)
- **Workspace Keybinds (`Alt + 1..9, 0`)**
  - Switch workspaces with `Alt + 1..0` (`Alt + -` / `Alt + =` for 11–12)
  - Move focused window with `Alt + Shift + 1..0`
- **Hardened for Linux Mint, Debian & Any Debian Derivative**
  - Auto-detects Polybar `< 3.7` (rewrites `internal/tray` to legacy tray keys on Debian 12 / Mint 21), monitor outputs, network interfaces, batteries (`BAT0`/`BAT1`), backlights, CPU/GPU sensors, Polkit agents, installed browsers, `bat`/`batcat`, and `fd`/`fdfind`
  - Built-in zero-dependency Python i3 IPC autotiler ([autotiling.py](dot_config/i3/scripts/executable_autotiling.py)) when `i3-autolayout` isn't installed
  - GTK-3.0, GTK-4.0, `xsettingsd`, `Tokyonight-Dark` GTK theme, and `Bibata-Modern-Ice` cursor setup
  - Safe manifest backup on install + one-command rollback (`./revert.sh`), optional VM/low-RAM tuning (`./tune.sh`), and machine-local overrides (`~/.config/i3/local.conf`)

## Quick Install (Linux Mint / Debian / Ubuntu / Pop!_OS)

```bash
git clone https://github.com/thehopeoftheuniverse/linux-mint-rice.git ~/dotfiles
cd ~/dotfiles
chmod +x install-debian.sh revert.sh tune.sh check.sh
./install-debian.sh
```

Install directly with **Dragon Ball Ultra Instinct** black UI and Zsh as login shell:

```bash
./install-debian.sh --theme ultra-instinct --shell
```

To roll back to your exact pre-install configs:

```bash
./revert.sh
```

## Keybinds Quick Reference

| Action | Keybind |
| --- | --- |
| Switch workspace 1–10 | `Alt + 1..0` |
| Move window to workspace 1–10 | `Alt + Shift + 1..0` |
| Open UI Studio (Themes / Layouts / Effects) | `Super + T` |
| Visual Wallpaper Picker (thumbnails) | `Super + Shift + W` |
| Live Keybind Cheatsheet | `Super + F1` |
| Dotfiles Health Check (`doctor.sh`) | `Super + F2` |
| Notification History (Dunst) | `Super + Shift + N` |
| Toggle Gaps / Toggle Polybar | `Super + Shift + G` / `Super + Shift + B` |
| App Launcher / Terminal / Files / Browser | `Super + Space` / `Super + Enter` / `Super + F` / `Super + B` |
| Power Menu / Screenshot | `Super + P` / `Print` |
| Focus / Move Window / Kill | `Super + H/J/K/L` / `Super + Shift + H/J/K/L` / `Super + Q` |

## Maintenance & Checks

- `~/.config/scripts/ui/doctor.sh` — verify binaries, fonts, symlinks, and `i3 -C`
- `./check.sh` — static syntax & config validation across the repo
- `./tune.sh` (`--apply` / `--undo`) — optional zram, sysctl, and journald tuning
