#!/usr/bin/env bash
# ============================================================================
#  linux-mint-rice — one-shot installer
#
#  Installs every dependency plus the fonts/cursor/theme assets, then deploys
#  the rice into ~/.config.  On a fresh Ubuntu 24.04 / Linux Mint 22 machine:
#
#      git clone https://github.com/thehopeoftheuniverse/linux-mint-rice
#      cd linux-mint-rice && ./install.sh
#
#  Flags:
#      --theme <name>   tokyonight | catppuccin | gruvbox | kanagawa
#      --no-deploy      install packages + assets only, leave ~/.config alone
#      --shell          also make zsh your login shell
#      --skip-apt       skip the package step (already installed)
#      --force          continue on an unsupported (older) distro release
#      -h, --help       this text
# ============================================================================
set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME="tokyonight"
DO_DEPLOY=1
DO_SHELL=0
SKIP_APT=0
FORCE=0

if [[ -t 1 ]]; then
    B=$'\e[1;34m'; G=$'\e[1;32m'; Y=$'\e[1;33m'; R=$'\e[1;31m'; N=$'\e[0m'
else
    B=""; G=""; Y=""; R=""; N=""
fi
step() { printf '\n%s── %s%s\n' "$B" "$*" "$N"; }
ok()   { printf '   %s+%s %s\n' "$G" "$N" "$*"; }
warn() { printf '   %s!%s %s\n' "$Y" "$N" "$*"; }
die()  { printf '\n%sx %s%s\n' "$R" "$*" "$N" >&2; exit 1; }

usage() {
    cat <<'USAGE'
linux-mint-rice — one-shot installer

  ./install.sh [--theme NAME] [--no-deploy] [--shell] [--skip-apt] [--force]

  --theme NAME   tokyonight (default) | catppuccin | gruvbox | kanagawa
  --no-deploy    install packages + assets only, leave ~/.config alone
  --shell        also make zsh your login shell
  --skip-apt     skip the package step (already installed)
  --force        continue on an unsupported (older) distro release
  -h, --help     this text

  A fresh machine needs nothing but git and sudo:
    git clone https://github.com/thehopeoftheuniverse/linux-mint-rice
    cd linux-mint-rice && ./install.sh
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --theme)     THEME="${2:-}"; shift 2 ;;
        --no-deploy) DO_DEPLOY=0; shift ;;
        --shell)     DO_SHELL=1; shift ;;
        --skip-apt)  SKIP_APT=1; shift ;;
        --force)     FORCE=1; shift ;;
        -h|--help)   usage; exit 0 ;;
        *)           die "unknown option: $1 (try --help)" ;;
    esac
done

[[ -f "$REPO_DIR/themes/$THEME.theme" ]] || die "no such theme: $THEME (look in $REPO_DIR/themes)"

# ── 1. preflight ────────────────────────────────────────────────────────────
step "preflight"

[[ -f /etc/os-release ]] || die "this does not look like Linux"
# shellcheck disable=SC1091
. /etc/os-release
DISTRO_ID="${ID:-unknown}"
DISTRO_NAME="${PRETTY_NAME:-$DISTRO_ID}"
DISTRO_VER="${VERSION_ID:-0}"

command -v apt-get >/dev/null || die "$DISTRO_NAME has no apt-get — this rice targets Debian/Ubuntu derivatives"
ok "$DISTRO_NAME"

# The configs need i3 4.23 gaps, polybar 3.7 modules and alacritty 0.13's TOML
# format. Those ship in Ubuntu 24.04 / Mint 22. Older releases need --force.
major="${DISTRO_VER%%.*}"
supported=1
if [[ "$DISTRO_ID" == "linuxmint" ]]; then
    (( major >= 22 )) || supported=0
elif [[ "$DISTRO_ID" == "ubuntu" ]]; then
    (( major >= 24 )) || supported=0
elif [[ "${ID_LIKE:-}" == *ubuntu* ]]; then
    (( major >= 24 )) || supported=0
fi

if (( supported == 0 )); then
    warn "detected $DISTRO_NAME — the rice targets Ubuntu 24.04 / Mint 22+"
    warn "older releases ship alacritty 0.10 (YAML), polybar 3.6 and picom 9"
    (( FORCE )) || die "re-run with --force to install anyway, or upgrade the distro"
    warn "--force given: continuing on an unsupported release"
else
    ok "release $DISTRO_VER supported"
fi

command -v sudo >/dev/null || (( EUID == 0 )) || die "sudo is required (or run as root)"
command -v git >/dev/null || die "git is required — sudo apt install git"
[[ -f "$REPO_DIR/apply.sh" ]] || die "run this from the repo root (apply.sh not found)"

export DEBIAN_FRONTEND=noninteractive
SUDO=""; (( EUID != 0 )) && SUDO="sudo"

# ── 2. packages ─────────────────────────────────────────────────────────────
APT_PKGS=(
    i3-wm i3status i3lock xss-lock numlockx x11-xserver-utils xinput
    picom polybar rofi dunst feh libnotify-bin
    alacritty zsh zsh-autosuggestions zsh-syntax-highlighting tmux
    thunar papirus-icon-theme lxappearance materia-gtk-theme arc-theme
    gnome-themes-extra sassc fontconfig
    xdotool xclip maim slop imagemagick yad arandr pavucontrol
    pulseaudio-utils network-manager-gnome playerctl pamixer
    bat eza fzf zoxide ripgrep fd-find tree ncdu btop cava jq curl unzip
    python3-numpy python3-pil
    xserver-xephyr
)
# optional: not every derivative ships these, nothing breaks without them
OPT_PKGS=(blueman xfce4-power-manager)

if (( SKIP_APT == 0 )); then
    step "packages"
    $SUDO apt-get update -qq || warn "apt update failed — continuing with existing lists"

    FAILED=()
    if ! $SUDO apt-get install -y -qq --no-install-recommends "${APT_PKGS[@]}" \
            >/tmp/rice-apt.log 2>&1; then
        warn "bulk install hit a problem — retrying package by package"
        for p in "${APT_PKGS[@]}"; do
            $SUDO apt-get install -y -qq --no-install-recommends "$p" \
                >>/tmp/rice-apt.log 2>&1 || FAILED+=("$p")
        done
    fi
    for p in "${OPT_PKGS[@]}"; do
        $SUDO apt-get install -y -qq --no-install-recommends "$p" >>/tmp/rice-apt.log 2>&1 || true
    done

    if (( ${#FAILED[@]} )); then
        warn "could not install: ${FAILED[*]}"
        warn "the rice still runs; see /tmp/rice-apt.log"
    else
        ok "apt packages installed"
    fi
else
    step "packages (skipped)"
fi

for bin in i3 polybar rofi picom alacritty dunst feh; do
    command -v "$bin" >/dev/null || die "$bin is missing — re-run without --skip-apt"
done
ok "core binaries present"

# ── 3. assets ───────────────────────────────────────────────────────────────
step "fonts"
if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
    ok "JetBrainsMono Nerd Font already installed"
else
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/jb.tar.xz" \
        https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.tar.xz \
        || die "font download failed (no network?)"
    mkdir -p "$HOME/.local/share/fonts"
    tar -xf "$tmp/jb.tar.xz" -C "$HOME/.local/share/fonts"
    fc-cache -f >/dev/null 2>&1
    rm -rf "$tmp"
    ok "JetBrainsMono Nerd Font installed"
fi

step "cursor"
if [[ -d "$HOME/.icons/Bibata-Modern-Ice" ]]; then
    ok "Bibata-Modern-Ice already installed"
else
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/bibata.tar.xz" \
        https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz \
        || die "cursor download failed (no network?)"
    mkdir -p "$HOME/.icons"
    tar -xf "$tmp/bibata.tar.xz" -C "$HOME/.icons"
    rm -rf "$tmp"
    ok "Bibata-Modern-Ice installed"
fi

step "fastfetch"
if command -v fastfetch >/dev/null; then
    ok "already installed"
else
    tmp="$(mktemp -d)"
    if curl -fsSL -o "$tmp/ff.deb" \
        https://github.com/fastfetch-cli/fastfetch/releases/download/2.71.0/fastfetch-linux-amd64.deb \
        && $SUDO dpkg -i "$tmp/ff.deb" >/dev/null 2>&1; then
        ok "fastfetch installed"
    else
        warn "fastfetch could not be installed — the terminal opens without it"
    fi
    rm -rf "$tmp"
fi

step "GTK theme"
if [[ -d "$HOME/.themes/Tokyonight-Dark" ]]; then
    ok "Tokyonight-Dark already installed"
else
    tmp="$(mktemp -d)"
    if git clone --depth 1 -q https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme "$tmp/tng" 2>/dev/null; then
        ( cd "$tmp/tng/themes" && THEME_VARIANTS='' COLOR_VARIANTS='-Dark' SIZE_VARIANTS='' \
            bash install.sh </dev/null >/dev/null 2>&1 ) || true
        if [[ -d "$HOME/.themes/Tokyonight-Dark" ]]; then
            ok "Tokyonight-Dark built"
        else
            warn "GTK theme build failed — falling back to Materia-dark"
        fi
    else
        warn "could not clone the GTK theme — using Materia-dark"
    fi
    rm -rf "$tmp"
fi

step "wallpapers"
if ls "$REPO_DIR/assets/wallpapers/"*.png >/dev/null 2>&1; then
    ok "wallpapers present ($(ls "$REPO_DIR/assets/wallpapers/"*.png | wc -l) images)"
elif [[ -x "$REPO_DIR/assets/make-wallpapers.sh" ]]; then
    if "$REPO_DIR/assets/make-wallpapers.sh" >/dev/null 2>&1; then
        ok "wallpapers generated"
    else
        warn "wallpaper generation failed (needs python3-numpy + imagemagick)"
    fi
fi

# ── 4. deploy ───────────────────────────────────────────────────────────────
if (( DO_DEPLOY )); then
    step "deploying the rice"
    args=(--theme "$THEME" --yes)
    (( DO_SHELL )) && args+=(--shell)
    "$REPO_DIR/apply.sh" "${args[@]}"
else
    step "deploy (skipped)"
    printf '   run: %s/apply.sh --theme %s\n' "$REPO_DIR" "$THEME"
fi
