# linux-mint-rice

A complete, lightweight X11 desktop rice for **Linux Mint 22 / Ubuntu 24.04** (and any
derivative): i3 + Polybar + Picom + Rofi + Dunst + Alacritty, driven by one palette file.

Built and verified in a VMware VM (4 vCPU, 4.6 GB RAM) — so it is tuned to stay fast on
modest hardware rather than just looking good on a screenshot.

| | |
| --- | --- |
| **WM** | i3 4.23 — gaps, smart gaps, 2px accent borders |
| **Bar** | Polybar 3.7 — workspaces · title · CPU/RAM/disk/volume/IP/clock/tray/power |
| **Compositor** | Picom 10.2 — `xrender` by default, `glx` (blur + rounded corners) on demand |
| **Launcher** | Rofi 1.7.5 — apps, run, windows, live keybind cheatsheet |
| **Terminal** | Alacritty + zsh (autosuggestions, syntax highlighting, fzf, zoxide) |
| **Notifications** | Dunst — rounded, palette-matched frames |
| **Palettes** | Tokyonight Storm · Catppuccin Mocha · Gruvbox Dark · Kanagawa Wave |

![desktop](screenshots/tokyonight-desktop.png)
![workload](screenshots/tokyonight-main.png)

*Both shots are the real session booted on an X server, not a mockup — see
[`lib/preview.sh`](lib/preview.sh).*

---

## Install

```bash
git clone https://github.com/thehopeoftheuniverse/linux-mint-rice
cd linux-mint-rice
./install.sh
```

Or without cloning first:

```bash
curl -fsSL https://raw.githubusercontent.com/thehopeoftheuniverse/linux-mint-rice/main/bootstrap.sh | bash
```

`install.sh` installs every apt package, the Nerd Font, Bibata cursor, fastfetch, the
Tokyonight GTK theme, generates the wallpapers, then deploys the rice into `~/.config`.

| Flag | Effect |
| --- | --- |
| `--theme <name>` | `tokyonight` (default), `catppuccin`, `gruvbox`, `kanagawa` |
| `--no-deploy` | install packages + assets only, leave `~/.config` untouched |
| `--shell` | also make zsh your login shell |
| `--skip-apt` | skip the package step (already installed) |
| `--force` | continue on an older distro release |

After it finishes: **log out**, then pick **i3** on the login screen. Your old desktop
stays installed and stays in that list — that alone is a full rollback.

### Requirements

Ubuntu 24.04 / Mint 22 or newer, `git`, `sudo`, and network access for the font/cursor/
theme downloads. Older releases (22.04, Mint 21) ship alacritty 0.10 with the YAML config
format, polybar 3.6 and picom 9 — the installer refuses unless you pass `--force`, and
some features will degrade.

---

## Undo

```bash
./revert.sh            # restore the newest backup, delete what the rice created
```

Every apply copies the files it is about to replace into `backups/<timestamp>/` with a
manifest of what existed beforehand. `revert.sh` replays it in reverse. Combined with
"just pick XFCE at login", there are two independent ways back.

---

## Keybindings (Super = Windows key)

| Combo | Action |
| --- | --- |
| `Super + Return` | terminal (alacritty + fastfetch) |
| `Super + Shift + Return` | fastfetch window that stays open |
| `Super + d` | app launcher (rofi) |
| `Super + Tab` | window switcher |
| `Super + Shift + d` | run command |
| `Super + e` | file manager |
| `Super + F1` | keybind cheatsheet (parsed live from the config) |
| `Super + q` | close window |
| `Super + f` | fullscreen |
| `Super + space` | toggle floating |
| `Super + Shift + space` | toggle focus between tiled/floating |
| ``Super + ` `` | scratchpad |
| `Super + s / w` | stacking / tabbed layout |
| `Super + r` | resize mode (`h j k l`, then `Esc`) |
| `Super + h j k l` | focus |
| `Super + Shift + h j k l` | move window |
| `Super + 1…0` | switch workspace |
| `Super + Shift + 1…0` | move window to workspace |
| `Print` | screenshot region → clipboard + `~/Pictures/Screenshots` |
| `Shift + Print` | screenshot whole screen |
| `Super + Print` | screenshot focused window |
| `Super + Escape` | lock (blurred wallpaper) |
| `Super + Shift + x` | power menu |
| `Super + Shift + w` | random wallpaper |
| `Super + Shift + i` | btop |
| `Super + c` | cava |
| `Super + Shift + c / r` | reload / restart i3 |
| `Super + Shift + e` | log out |
| `XF86Audio*` | volume / mute / play / next / prev |

---

## Switching palette

```bash
~/.config/i3/scripts/theme-switch.sh            # list themes
~/.config/i3/scripts/theme-switch.sh gruvbox    # apply + live reload
```

Re-renders every config, reloads i3, restarts polybar, reloads dunst, nudges picom and
swaps the wallpaper if `<theme>.png` exists.

| Tokyonight | Gruvbox |
| --- | --- |
| ![](screenshots/tokyonight-main.png) | ![](screenshots/gruvbox-main.png) |

## Effects

```bash
~/.config/i3/scripts/effects.sh toggle   # xrender <-> glx
```

`xrender` is the default: on VMware's SVGA adapter everything renders on the CPU, and it
is the difference between a responsive desktop and a slideshow. The `glx` profile adds
`blur-background` (dual-kawase 5) and `corner-radius 12`.

## Efficiency

```bash
./tune.sh                   # dry run — prints what it would change
sudo ./tune.sh --apply      # zram (zstd, 50% RAM), swappiness 180, journald capped,
                            # cups/ModemManager/avahi/bluetooth disabled
sudo ./tune.sh --undo
```

Measured on the target VM: the XFCE desktop stack (session, settingsd, panel, desktop,
notifyd, power-manager) costs **145 MB**; the i3 stack (i3, polybar, dunst, picom,
xsettingsd) costs **66 MB**.

---

## Structure

```
linux-mint-rice/
├── install.sh                one-shot installer (packages + assets + deploy)
├── bootstrap.sh              clone-and-install one-liner
├── apply.sh                  render + deploy, with backup manifest
├── revert.sh                 undo everything
├── tune.sh                   VM tuning, dry run by default
├── templates/                configs with @TOKEN@ placeholders (pure ASCII)
│   ├── i3/config
│   ├── i3/scripts/           lock, powermenu, screenshot, volume, cheatsheet, wallpaper,
│   │                         network menu, effects toggle, theme switch, i3exit
│   ├── polybar/config.ini
│   ├── polybar/scripts/      launch.sh, network.sh
│   ├── picom/                picom.conf (xrender) + picom-glx.conf (blur/corners)
│   ├── rofi/                 config.rasi + themes/theme.rasi
│   ├── dunst/dunstrc
│   ├── alacritty/            alacritty.toml + colors.toml
│   ├── gtk-3.0, gtk-4.0, xsettingsd, Xresources
│   ├── fastfetch/            config.jsonc + logo.txt
│   └── btop/, cava/, zsh/
├── themes/                   4 palettes, one file each
├── lib/render.py             token renderer (emits Nerd Font glyphs from codepoints)
├── lib/theme.sh              runtime palette switcher
├── lib/preview.sh            boot the rice in a private X server, take screenshots
├── assets/make-wallpapers.sh procedural wallpapers (python mesh + ImageMagick abstracts)
└── build/                    rendered output (generated, gitignored)
```

**Why templates:** one palette file drives i3, polybar, rofi, dunst, alacritty, btop,
cava, Xresources and the zsh prompt. Change the palette, everything follows.

---

## Verified

- `i3 -C` validates the generated config for all four palettes.
- Full session (i3 + polybar + picom + dunst + rofi + alacritty + zsh + fastfetch) boots
  in Xvfb with zero config errors; every screenshot here came out of that run.
- Nerd Font glyph coverage checked against the actual TTF cmap — every icon used exists.
- Rofi theme parses (`rofi -dump-theme`), dunst loads, alacritty loads with no warnings.
- `apply.sh` → `revert.sh` tested on a throwaway HOME: originals restored, created paths
  removed.

Environment quirks already handled:

- VMware reports `operstate=unknown` on `ens33`, which makes polybar's `internal/network`
  claim "offline" — replaced with a script that reports the live IP.
- Polybar 3.7's `internal/memory` has no `%percentage%` token — replaced with a
  `custom/script` module.
- ImageMagick 6 ships `convert`, not `magick` — scripts detect both.

---

## Troubleshooting

**Bar missing after login** — `~/.config/polybar/scripts/launch.sh`, then read
`~/.cache/polybar.log`.

**No icons, boxes instead** — `fc-cache -f` and check
`fc-match "JetBrainsMono Nerd Font"` returns the patched file.

**Lag or tearing** — `~/.config/i3/scripts/effects.sh safe`.

**Notifications silent** — `dunst` must run inside the session's dbus;
`dunstctl history` shows what arrived.

**Everything is broken** — log out, pick XFCE at the login screen. Then `./revert.sh`.

## Credits

Palettes follow the upstream [Tokyonight](https://github.com/folke/tokyonight.nvim),
[Catppuccin](https://github.com/catppuccin/catppuccin),
[Gruvbox](https://github.com/morhetz/gruvbox) and
[Kanagawa](https://github.com/rebelot/kanagawa.nvim) schemes. Icons from
[Nerd Fonts](https://github.com/ryanoasis/nerd-fonts), GTK theme from
[Tokyonight-GTK-Theme](https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme),
cursor from [Bibata](https://github.com/ful1e5/Bibata_Cursor).

MIT — see [LICENSE](LICENSE).
