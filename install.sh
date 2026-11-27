#!/usr/bin/env bash
# ============================================================================
#  linux-mint-rice — one-shot installer
#
#  Installs every dependency plus the fonts/cursor/theme assets, then deploys
#  the rice into ~/.config.  Works on Debian/Ubuntu/Mint (apt), Fedora/RHEL
#  (dnf) and Arch/Manjaro (pacman).  On a fresh machine:
#
#      git clone https://github.com/thehopeoftheuniverse/linux-mint-rice
#      cd linux-mint-rice && ./install.sh
#
#  Flags:
#      --theme <name>   tokyonight | catppuccin | gruvbox | kanagawa
#      --no-deploy      install packages + assets only, leave ~/.config alone
#      --shell          also make zsh your login shell
#      --skip-packages  skip the package step (already installed)
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
ok()   { printf '   %s[ok]%s %s\n' "$G" "$N" "$*"; }
warn() { printf '   %s[!]%s  %s\n' "$Y" "$N" "$*"; }
die()  { printf '\n%s[x] %s%s\n' "$R" "$*" "$N" >&2; exit 1; }

usage() {
    cat <<'USAGE'
linux-mint-rice — one-shot installer

  ./install.sh [--theme NAME] [--no-deploy] [--shell] [--skip-packages] [--force]

  Supported: Debian/Ubuntu/Mint (apt), Fedora/RHEL (dnf), Arch/Manjaro (pacman).
  Package lists live in packages/<family>.txt.

  --theme NAME      tokyonight (default) | catppuccin | gruvbox | kanagawa
  --no-deploy       install packages + assets only, leave ~/.config alone
  --shell           also make zsh your login shell
  --skip-packages   skip the package step (alias: --skip-apt)
  --force           continue on an unsupported (older) distro release
  -h, --help        this text

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
        --skip-apt|--skip-packages) SKIP_APT=1; shift ;;
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

detect_family() {
    case "$DISTRO_ID" in
        ubuntu|linuxmint|debian|pop|zorin|elementary|kali|neon|raspbian|mx|devuan)
            echo debian ;;
        fedora|rhel|centos|rocky|almalinux|ol)
            echo fedora ;;
        arch|manjaro|endeavouros|garuda|artix|arcolinux|catchy|reborn)
            echo arch ;;
        *)
            case "${ID_LIKE:-}" in
                *debian*|*ubuntu*) echo debian ;;
                *fedora*|*rhel*)   echo fedora ;;
                *arch*)            echo arch ;;
                *)                 echo unknown ;;
            esac ;;
    esac
}
FAMILY="$(detect_family)"
[[ $FAMILY != unknown ]] || die "$DISTRO_NAME is not a Debian, Fedora or Arch derivative"
ok "$DISTRO_NAME (family: $FAMILY)"

# Only the Debian family carries old releases that matter: Ubuntu 24.04 / Mint 22
# are the first with alacritty 0.13 (TOML config), polybar 3.7 and picom 10.
# Fedora and Arch are current by construction, so no gate there.
if [[ $FAMILY == debian ]]; then
    major="${DISTRO_VER%%.*}"
    supported=1
    if [[ $DISTRO_ID == linuxmint ]]; then
        (( major >= 22 )) || supported=0
    else
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
fi

case $FAMILY in
    debian) PM=apt-get ;;
    fedora) PM=dnf ;;
    arch)   PM=pacman ;;
esac
command -v "$PM" >/dev/null || die "$PM not found on $DISTRO_NAME"
# a fresh clone should push its own commits, same as the dev checkout
if [[ -d "$REPO_DIR/.git" ]]; then
    git -C "$REPO_DIR" config core.hooksPath .githooks 2>/dev/null || true
fi

command -v sudo >/dev/null || (( EUID == 0 )) || die "sudo is required (or run as root)"
[[ -f "$REPO_DIR/apply.sh" ]] || die "run this from the repo root (apply.sh not found)"

export DEBIAN_FRONTEND=noninteractive
SUDO=""; (( EUID != 0 )) && SUDO="sudo"

# ── 2. packages ─────────────────────────────────────────────────────────────
# The list lives in packages/<family>.txt; entries ending in '?' are optional.
LIST="$REPO_DIR/packages/$FAMILY.txt"
[[ -f $LIST ]] || die "missing package list: $LIST"

clean_list() { sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$LIST" | grep -v '^$'; }
mapfile -t PKGS < <(clean_list | grep -v '?$')
mapfile -t OPT_PKGS < <(clean_list | grep '?$' | sed 's/?$//')

refresh_repos() {
    case $FAMILY in
        debian) $SUDO apt-get update -qq ;;
        fedora) $SUDO dnf -q makecache ;;
        arch)   $SUDO pacman -Sy --noconfirm ;;
    esac
}

install_pkgs() {
    case $FAMILY in
        debian) $SUDO apt-get install -y -qq --no-install-recommends "$@" ;;
        fedora) $SUDO dnf install -y -q --setopt=install_weak_deps=False "$@" ;;
        arch)   $SUDO pacman -S --needed --noconfirm "$@" ;;
    esac
}

if (( SKIP_APT == 0 )); then
    step "packages ($FAMILY)"
    [[ $FAMILY == arch ]] && warn "Arch does not support partial upgrades — run 'sudo pacman -Syu' first if this fails"
    refresh_repos || warn "repo refresh failed — continuing with existing metadata"

    FAILED=()
    if ! install_pkgs "${PKGS[@]}" >/tmp/rice-pkg.log 2>&1; then
        warn "bulk install hit a problem — retrying package by package"
        for p in "${PKGS[@]}"; do
            install_pkgs "$p" >>/tmp/rice-pkg.log 2>&1 || FAILED+=("$p")
        done
    fi
    for p in "${OPT_PKGS[@]}"; do
        install_pkgs "$p" >>/tmp/rice-pkg.log 2>&1 || true
    done

    if (( ${#FAILED[@]} )); then
        warn "could not install: ${FAILED[*]}"
        warn "the rice still runs without them; see /tmp/rice-pkg.log"
    else
        ok "$((${#PKGS[@]} + ${#OPT_PKGS[@]})) packages installed"
    fi
else
    step "packages (skipped)"
fi

for bin in i3 polybar rofi picom alacritty dunst feh; do
    command -v "$bin" >/dev/null || die "$bin is missing — re-run without --skip-packages"
done
ok "core binaries present"

# ── 3. assets ───────────────────────────────────────────────────────────────
step "fonts"
font_family="$(fc-match -f '%{family}' 'JetBrainsMono Nerd Font' 2>/dev/null || true)"
if [[ $font_family == *"JetBrainsMono Nerd Font"* ]]; then
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
    if [[ $FAMILY != debian ]]; then
        if install_pkgs fastfetch >>/tmp/rice-pkg.log 2>&1; then
            ok "fastfetch installed from the distro repo"
        else
            warn "fastfetch unavailable — the terminal opens without it"
        fi
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
fi

step "GTK theme"
# the upstream builder writes to ~/.themes as a user and /usr/share/themes as root
theme_installed() { [[ -d "$HOME/.themes/Tokyonight-Dark" || -d /usr/share/themes/Tokyonight-Dark ]]; }
if theme_installed; then
    ok "Tokyonight-Dark already installed"
else
    tmp="$(mktemp -d)"
    if git clone --depth 1 -q https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme "$tmp/tng" 2>/dev/null; then
        ( cd "$tmp/tng/themes" && THEME_VARIANTS='' COLOR_VARIANTS='-Dark' SIZE_VARIANTS='' \
            bash install.sh </dev/null >/dev/null 2>&1 ) || true
        if theme_installed; then
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
