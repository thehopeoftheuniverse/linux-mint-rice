#!/usr/bin/env bash
set -euo pipefail

# One-shot installer for Linux Mint, Debian, Ubuntu, LMDE, Pop!_OS & Debian derivatives
# Combines full dev/terminal stack + UI Studio + manifest backup/revert + GTK/cursor theming

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_THEME="catppuccin-mocha"
SKIP_APT=0
DO_SHELL=0
ROLE="desktop"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --theme) DEFAULT_THEME="${2:?missing theme}"; shift 2 ;;
    --role) ROLE="${2:?missing role}"; shift 2 ;;
    --shell) DO_SHELL=1; shift ;;
    --skip-apt|--skip-packages) SKIP_APT=1; shift ;;
    -h|--help)
      cat <<EOF
Usage: ./install-debian.sh [OPTIONS]
  --theme <catppuccin-mocha|ultra-instinct|ultra-instinct-omen|tokyo-night|rose-pine>
  --role <desktop|server>
  --shell         Set Zsh as your login shell
  --skip-apt      Skip apt package installation
EOF
      exit 0
      ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

log()  { printf '\033[1;36m[dotfiles]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  log "Detected OS: ${PRETTY_NAME:-${ID:-linux}}"
  if [[ "${ID:-}" != "debian" && "${ID:-}" != "ubuntu" && "${ID:-}" != "linuxmint" && "${ID:-}" != "pop" && "${ID:-}" != "kali" && "${ID_LIKE:-}" != *debian* && "${ID_LIKE:-}" != *ubuntu* ]]; then
    warn "This script targets Debian/Linux Mint/Ubuntu derivatives; continuing anyway."
  fi
fi

install_apt_available() {
  local pkg
  local to_install=()
  for pkg in "$@"; do
    if apt-cache show "$pkg" >/dev/null 2>&1; then
      to_install+=("$pkg")
    else
      warn "Package '$pkg' not found in apt repos (skipping)."
    fi
  done
  if (( ${#to_install[@]} > 0 )); then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${to_install[@]}"
  fi
}

if [[ "$SKIP_APT" -eq 0 ]] && command -v apt-get >/dev/null 2>&1; then
  log "Updating apt package index..."
  sudo apt-get update

  COMMON_PKGS=(
    git zsh curl wget unzip jq ca-certificates fontconfig python3
    fzf ripgrep fd-find bat btop tmux neovim ncdu trash-cli
  )
  install_apt_available "${COMMON_PKGS[@]}"

  if [[ "$ROLE" == "desktop" ]]; then
    DESKTOP_PKGS=(
      i3 i3lock polybar rofi picom dunst feh kitty
      x11-xserver-utils xinput xss-lock xautolock dex xsettingsd
      maim xdotool xclip xfce4-clipman scrot imagemagick
      brightnessctl playerctl pamixer pavucontrol pulseaudio-utils
      libnotify-bin inotify-tools lm-sensors network-manager-gnome
      papirus-icon-theme blueman rofi-calc cava thunar numlockx
    )
    install_apt_available "${DESKTOP_PKGS[@]}"

    for polkit_pkg in policykit-1-gnome mate-polkit lxqt-policykit; do
      if apt-cache show "$polkit_pkg" >/dev/null 2>&1; then
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$polkit_pkg"
        break
      fi
    done
  fi
fi

# Create Debian/Mint binary shims in ~/.local/bin
mkdir -p "$HOME/.local/bin"
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
fi
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi
export PATH="$HOME/.local/bin:$PATH"

# Install Nerd Fonts (JetBrainsMono & Iosevka)
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
install_nerd_font() {
  local font_name="$1"
  local check_pattern="$2"
  if fc-list 2>/dev/null | grep -qi "$check_pattern"; then
    log "Font already installed: $font_name"
    return
  fi
  log "Installing $font_name Nerd Font..."
  local tmp_zip="/tmp/${font_name}.zip"
  local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_name}.zip"
  if curl -fLo "$tmp_zip" "$url"; then
    unzip -oq "$tmp_zip" "*.ttf" "*.otf" -d "$FONT_DIR/${font_name}" 2>/dev/null || unzip -oq "$tmp_zip" -d "$FONT_DIR/${font_name}"
    rm -f "$tmp_zip"
  else
    warn "Failed to download $font_name (check internet connection)."
  fi
}

if [[ "$ROLE" == "desktop" ]]; then
  install_nerd_font "JetBrainsMono" "JetBrainsMono"
  install_nerd_font "Iosevka" "Iosevka"
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$FONT_DIR"

  # Install Bibata-Modern-Ice cursor theme
  if [[ ! -d "$HOME/.icons/Bibata-Modern-Ice" ]]; then
    log "Installing Bibata-Modern-Ice cursor..."
    tmp_cur="$(mktemp -d)"
    if curl -fsSL -o "$tmp_cur/bibata.tar.xz" \
      https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.xz; then
      mkdir -p "$HOME/.icons"
      tar -xf "$tmp_cur/bibata.tar.xz" -C "$HOME/.icons"
    else
      warn "Could not download Bibata-Modern-Ice cursor."
    fi
    rm -rf "$tmp_cur"
  fi

  # Install Tokyonight-Dark GTK theme if absent
  if [[ ! -d "$HOME/.themes/Tokyonight-Dark" && ! -d /usr/share/themes/Tokyonight-Dark ]]; then
    log "Installing Tokyonight-Dark GTK theme..."
    tmp_gtk="$(mktemp -d)"
    if git clone --depth 1 -q https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme "$tmp_gtk/tng" 2>/dev/null; then
      ( cd "$tmp_gtk/tng/themes" && THEME_VARIANTS='' COLOR_VARIANTS='-Dark' SIZE_VARIANTS='' \
        bash install.sh </dev/null >/dev/null 2>&1 ) || true
    else
      warn "Could not install Tokyonight-Dark GTK theme."
    fi
    rm -rf "$tmp_gtk"
  fi
fi

# Install optional modern CLI tools if missing
if ! command -v fastfetch >/dev/null 2>&1; then
  if apt-cache show fastfetch >/dev/null 2>&1; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y fastfetch || true
  elif [[ "$(dpkg --print-architecture 2>/dev/null || true)" == "amd64" ]]; then
    log "Installing fastfetch .deb from GitHub..."
    ff_url="$(curl -fsSL https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest 2>/dev/null \
      | grep -m1 'browser_download_url.*linux-amd64\.deb' | cut -d '"' -f 4 || true)"
    if [[ -n "$ff_url" ]]; then
      curl -fsSL "$ff_url" -o /tmp/fastfetch_amd64.deb && sudo dpkg -i /tmp/fastfetch_amd64.deb || true
      rm -f /tmp/fastfetch_amd64.deb
    fi
  fi
fi

if ! command -v starship >/dev/null 2>&1; then
  log "Installing starship prompt..."
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" || warn "Could not install starship."
fi

if ! command -v zoxide >/dev/null 2>&1; then
  log "Installing zoxide..."
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh || warn "Could not install zoxide."
fi

if ! command -v chezmoi >/dev/null 2>&1; then
  log "Installing chezmoi..."
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

# Snapshot existing user configs before applying so revert.sh can roll back cleanly
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$SCRIPT_DIR/backups/$STAMP"
mkdir -p "$BACKUP_DIR/.config"
: > "$BACKUP_DIR/.manifest"

BACKUP_CFG_DIRS=(
  i3 polybar picom rofi dunst kitty btop nvim tmux yazi zsh
  gtk-3.0 gtk-4.0 xsettingsd fastfetch starship atuin
)
BACKUP_HOME_FILES=(.Xresources .bashrc .zshrc .zshenv .gitconfig)

for d in "${BACKUP_CFG_DIRS[@]}"; do
  if [[ -e "$HOME/.config/$d" ]]; then
    cp -a "$HOME/.config/$d" "$BACKUP_DIR/.config/$d"
    echo "existing:.config/$d" >> "$BACKUP_DIR/.manifest"
  else
    echo "created:.config/$d" >> "$BACKUP_DIR/.manifest"
  fi
done
for f in "${BACKUP_HOME_FILES[@]}"; do
  if [[ -e "$HOME/$f" ]]; then
    cp -a "$HOME/$f" "$BACKUP_DIR/$f"
    echo "existing:$f" >> "$BACKUP_DIR/.manifest"
  else
    echo "created:$f" >> "$BACKUP_DIR/.manifest"
  fi
done
log "Backup saved to $BACKUP_DIR (undo anytime with ./revert.sh)"

# Initialize and apply dotfiles via chezmoi
log "Applying dotfiles with chezmoi..."
git -C "$SCRIPT_DIR" config core.hooksPath .githooks 2>/dev/null || true
chezmoi init --source "$SCRIPT_DIR" --apply

if [[ "$ROLE" == "desktop" ]]; then
  if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-Dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font 10' 2>/dev/null || true
  fi
  if [[ -x "$HOME/.config/scripts/ui/theme-switch.sh" ]]; then
    log "Applying UI theme: $DEFAULT_THEME"
    "$HOME/.config/scripts/ui/theme-switch.sh" --theme "$DEFAULT_THEME" || true
  fi
fi

chmod +x "$HOME/.config/i3/scripts/"*.sh "$HOME/.config/i3/scripts/"*.py \
  "$HOME/.config/polybar/launch.sh" \
  "$HOME/.config/polybar/forest/scripts/"*.sh \
  "$HOME/.config/scripts/ui/"*.sh 2>/dev/null || true

if [[ "$DO_SHELL" -eq 1 ]] && command -v zsh >/dev/null 2>&1; then
  log "Setting Zsh as login shell..."
  chsh -s "$(command -v zsh)" || warn "chsh failed; run manually: chsh -s $(command -v zsh)"
fi

log "Running dotfiles health check..."
"$HOME/.config/scripts/ui/doctor.sh" || true

log "Done! Log out and select 'i3' at your login screen (run ./revert.sh anytime to roll back)."
