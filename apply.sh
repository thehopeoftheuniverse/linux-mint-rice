#!/usr/bin/env bash
# ============================================================================
#  Rice activation.  Copies the built config into place — nothing else.
#  Run with no arguments for a safe, backed-up apply.
# ============================================================================
set -euo pipefail

RICE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$HOME/.config"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$RICE/backups/$STAMP"
THEME="tokyonight"
DO_SHELL=0
ASSUME_YES=0

TARGETS=(i3 polybar picom rofi dunst alacritty btop cava fastfetch
         gtk-3.0 gtk-4.0 xsettingsd ricing)
FILES=(.Xresources .zshrc)

usage() { sed -n '2,6p' "$0"; echo; echo "  --theme <name>   palette to build (default tokyonight)"; echo "  --shell          also make zsh your login shell"; echo "  --yes            no prompts"; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --theme) THEME="$2"; shift 2 ;;
        --shell) DO_SHELL=1; shift ;;
        --yes|-y) ASSUME_YES=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown option: $1" >&2; usage; exit 2 ;;
    esac
done

[[ -f $RICE/themes/$THEME.theme ]] || { echo "unknown theme: $THEME" >&2; exit 1; }

echo "── dependencies ──────────────────────────────────────────────────────"
missing=(); optional=()
for bin in i3 picom polybar rofi alacritty dunst feh xdotool xclip; do
    command -v "$bin" >/dev/null || missing+=("$bin")
done
command -v magick >/dev/null || command -v convert >/dev/null || missing+=("imagemagick")
for bin in fastfetch zsh pamixer maim btop cava playerctl; do
    command -v "$bin" >/dev/null || optional+=("$bin")
done
if ((${#missing[@]})); then
    echo "missing required: ${missing[*]}"
    echo "run: $RICE/install.sh"
    exit 1
fi
((${#optional[@]})) && echo "optional, missing: ${optional[*]} (those features stay off)"
echo "dependencies ok"

echo
echo "── backup → $BACKUP"
mkdir -p "$BACKUP"
: > "$BACKUP/.manifest"
for d in "${TARGETS[@]}"; do
    if [[ -e $CONF/$d ]]; then
        mkdir -p "$BACKUP/.config"
        cp -a "$CONF/$d" "$BACKUP/.config/$d"
        echo "existing:.config/$d" >> "$BACKUP/.manifest"
    else
        echo "created:.config/$d" >> "$BACKUP/.manifest"
    fi
done
for f in "${FILES[@]}"; do
    if [[ -e $HOME/$f ]]; then
        cp -a "$HOME/$f" "$BACKUP/$f"
        echo "existing:$f" >> "$BACKUP/.manifest"
    else
        echo "created:$f" >> "$BACKUP/.manifest"
    fi
done
echo "backed up $(wc -l < "$BACKUP/.manifest") paths"

echo
echo "── render ($THEME)"
BUILD="$RICE/build/$THEME"
rm -rf "$BUILD"
python3 "$RICE/lib/render.py" "$RICE/themes/$THEME.theme" "$RICE/templates" "$BUILD"

echo
echo "── deploy"
for d in i3 polybar picom rofi dunst alacritty btop cava fastfetch \
         gtk-3.0 gtk-4.0 xsettingsd; do
    [[ -d $BUILD/$d ]] || continue
    mkdir -p "$CONF/$d"
    cp -a "$BUILD/$d/." "$CONF/$d/"
    echo "  ~/.config/$d"
done

# adapt alacritty/polybar config shape to the versions this machine actually has
python3 "$RICE/lib/compat.py" "$CONF" --verbose

mkdir -p "$CONF/ricing/themes"
cp -a "$BUILD/Xresources" "$HOME/.Xresources"
cp -a "$BUILD/palette.env" "$CONF/ricing/palette.env"
cp -a "$RICE/lib/render.py" "$RICE/lib/theme.sh" "$RICE/lib/compat.py" "$CONF/ricing/"
cp -a "$RICE/themes/." "$CONF/ricing/themes/"
mkdir -p "$CONF/ricing/templates"
cp -a "$RICE/templates/." "$CONF/ricing/templates/"
printf '%s\n' "$THEME" > "$CONF/ricing/current-theme"

mkdir -p "$CONF/i3/scripts" "$HOME/.local/share/wallpapers" "$HOME/Pictures/Screenshots"
cp -a "$RICE/assets/wallpapers/." "$HOME/.local/share/wallpapers/"
chmod +x "$CONF"/i3/scripts/*.sh "$CONF"/polybar/scripts/*.sh "$CONF"/ricing/*.sh 2>/dev/null || true

# shell config (never clobber silently — the original is in the backup)
if [[ -f $HOME/.zshrc && ! -f $HOME/.zshrc.pre-rice ]]; then
    cp -a "$HOME/.zshrc" "$HOME/.zshrc.pre-rice"
fi
cp -a "$RICE/templates/zsh/.zshrc" "$HOME/.zshrc"

# default wallpaper
if [[ ! -s $HOME/.local/share/wallpapers/current ]]; then
    wp="$(find "$HOME/.local/share/wallpapers" -maxdepth 1 -name "$THEME.*" | head -1)"
    [[ -n $wp ]] && printf '%s\n' "$wp" > "$HOME/.local/share/wallpapers/current"
fi

# personal overrides live outside the repo and are never overwritten
if [[ ! -f $CONF/i3/local.conf ]]; then
    cat > "$CONF/i3/local.conf" <<'LOCALEOF'
# Personal i3 overrides — apply.sh and theme switching never touch this file.
# Examples:
#   exec --no-startup-id nm-applet
#   bindsym $mod+p exec pavucontrol
LOCALEOF
    echo "  ~/.config/i3/local.conf (created)"
fi

echo
echo "── gtk / cursor defaults"
command -v gsettings >/dev/null && {
    gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-Dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 10' 2>/dev/null || true
}

if [[ $DO_SHELL -eq 1 ]]; then
    echo
    echo "── login shell → zsh"
    chsh -s "$(command -v zsh)" || echo "chsh failed (needs your password); run: chsh -s $(command -v zsh)"
fi

cat <<EOF

────────────────────────────────────────────────────────────────────────
 rice deployed · theme: $THEME
────────────────────────────────────────────────────────────────────────
 Next: log out, then pick the  i3  session on the login screen.
 (your current desktop stays installed — pick it at login to go back.)

 while inside i3:
   Super+Return   terminal          Super+d        app launcher
   Super+F1       keybind cheatsheet Super+Shift+x  power menu
   Super+Shift+w  next wallpaper     Super+Escape   lock

 change palette:   ~/.config/i3/scripts/theme-switch.sh
 effects on/off:   ~/.config/i3/scripts/effects.sh toggle
 undo everything:  $RICE/revert.sh

 backup of what was replaced: $BACKUP
EOF
