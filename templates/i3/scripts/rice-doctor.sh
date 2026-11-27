#!/usr/bin/env bash
# Health check for the installed rice. Run it after an update or when the
# bar/WM misbehaves:  ~/.config/i3/scripts/rice-doctor.sh
set -u
ok()   { printf '  [ok]  %s\n' "$*"; }
bad()  { printf '  [!!]  %s\n' "$*"; }
info() { printf '  %-22s %s\n' "$1" "$2"; }

echo "── binaries"
for b in i3 polybar picom rofi dunst alacritty feh xdotool xclip maim playerctl pamixer jq \
         fastfetch btop cava zsh; do
    if command -v "$b" >/dev/null; then info "$b" "$("$b" --version 2>/dev/null | head -1 | cut -c1-46)"; else bad "$b missing"; fi
done

echo
echo "── fonts"
fam="$(fc-match -f '%{family}' 'JetBrainsMono Nerd Font' 2>/dev/null)"
[[ $fam == *"JetBrainsMono Nerd Font"* ]] && ok "Nerd Font resolves" || bad "Nerd Font missing — fc-cache -f"

echo
echo "── config"
i3 -C -c "$HOME/.config/i3/config" >/dev/null 2>&1 && ok "i3 config parses" || bad "i3 config has errors"
[[ -f $HOME/.config/polybar/config.ini ]] && ok "polybar config present" || bad "polybar config missing"
[[ -f $HOME/.config/alacritty/alacritty.toml || -f $HOME/.config/alacritty/alacritty.yml ]] \
    && ok "alacritty config present" || bad "alacritty config missing"
rofi -theme "$HOME/.config/rofi/themes/theme.rasi" -dump-theme >/dev/null 2>&1 \
    && ok "rofi theme parses" || bad "rofi theme has errors"

echo
echo "── session"
info "theme" "$(cat "$HOME/.config/ricing/current-theme" 2>/dev/null || echo unknown)"
info "effects" "$(cat "$HOME/.config/ricing/effects" 2>/dev/null || echo safe)"
info "xrandr mode" "$(xrandr 2>/dev/null | grep -m1 '\*' | awk '{print $1}')"
info "wallpaper" "$(basename "$(cat "$HOME/.local/share/wallpapers/current" 2>/dev/null)" 2>/dev/null)"
grep -q "i3.desktop" /usr/share/xsessions/i3.desktop 2>/dev/null && ok "i3 session registered" || bad "i3 session file missing"
