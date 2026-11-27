# ════════════════════════════════════════════════════════════════════════════
#  zsh · @THEME_NAME@ · linux-mint-rice
# ════════════════════════════════════════════════════════════════════════════

# ── palette (shared with the WM) ────────────────────────────────────────────
if [[ -r $HOME/.config/ricing/palette.env ]]; then
    source "$HOME/.config/ricing/palette.env"
else
    BG='#1a1b26'; BG_HL='#292e42'; FG='#c0caf5'; FG_DIM='#a9b1d6'
    MUTED='#565f89'; BLUE='#7aa2f7'; CYAN='#7dcfff'; PURPLE='#bb9af7'
    GREEN='#9ece6a'; TEAL='#73daca'; YELLOW='#e0af68'; RED='#f7768e'
fi

# ── history / options ───────────────────────────────────────────────────────
HISTFILE=$HOME/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS SHARE_HISTORY
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS EXTENDED_GLOB INTERACTIVE_COMMENTS
setopt NO_BEEP NO_FLOW_CONTROL

export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-nano}"
export PAGER=less
export LESS='-R'

# ── completion ──────────────────────────────────────────────────────────────
autoload -Uz compinit && compinit -u
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format "%F{$MUTED}── %d%f"

# ── key bindings ────────────────────────────────────────────────────────────
bindkey -e
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

# ── prompt ──────────────────────────────────────────────────────────────────
autoload -Uz add-zsh-hook vcs_info
setopt PROMPT_SUBST
zstyle ':vcs_info:git:*' formats       " %F{$MUTED}on%f %F{$PURPLE}%b%u%c%f"
zstyle ':vcs_info:git:*' actionformats " %F{$MUTED}on%f %F{$PURPLE}%b|%a%u%c%f"
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr   " %F{$YELLOW}●%f"
zstyle ':vcs_info:git:*' stagedstr     " %F{$GREEN}●%f"

_cmd_start=0
_prompt_preexec() { _cmd_start=$EPOCHSECONDS; }
_prompt_precmd() {
    local exit_code=$?
    local elapsed=""
    if (( _cmd_start > 0 )); then
        local dt=$(( EPOCHSECONDS - _cmd_start ))
        (( dt >= 3 )) && elapsed="%F{$YELLOW}${dt}s%f "
        _cmd_start=0
    fi
    vcs_info
    PROMPT="
%F{$BLUE}%n%f%F{$MUTED}@%f%F{$TEAL}%m%f %F{$CYAN}%3~%f${vcs_info_msg_0_}
%(?.%F{$BLUE}.%F{$RED})❯%f "
    RPROMPT="${elapsed}%F{$RED}%(?..[%?] )%f%F{$FG_DIM}%*%f"
    return $exit_code
}
zmodload zsh/datetime 2>/dev/null || true
add-zsh-hook preexec _prompt_preexec
add-zsh-hook precmd _prompt_precmd

# Show fastfetch once on top-level interactive shells (not inside tmux/subshells)
if [[ -o interactive && -z ${TMUX:-} && -z ${RICE_NO_FETCH:-} && ${SHLVL:-1} -le 2 ]]; then
    command -v fastfetch >/dev/null && fastfetch --config ~/.config/fastfetch/config.jsonc 2>/dev/null || true
fi

# ── tools (Debian / Fedora / Arch compatible paths) ─────────────────────────
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

if command -v fzf >/dev/null; then
    if fzf --zsh >/dev/null 2>&1; then
        eval "$(fzf --zsh)"
    else
        for f in /usr/share/doc/fzf/examples/key-bindings.zsh \
                 /usr/share/fzf/key-bindings.zsh \
                 /usr/share/fzf/shell/key-bindings.zsh; do
            [[ -f $f ]] && { source "$f"; break; }
        done
        for f in /usr/share/doc/fzf/examples/completion.zsh \
                 /usr/share/fzf/completion.zsh; do
            [[ -f $f ]] && { source "$f"; break; }
        done
    fi
fi

for f in /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
         /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh; do
    [[ -f $f ]] && { source "$f"; break; }
done

for f in /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
         /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
    [[ -f $f ]] && { source "$f"; break; }
done

# ── aliases ─────────────────────────────────────────────────────────────────
if command -v eza >/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lh --icons --group-directories-first --git'
    alias la='eza -lah --icons --group-directories-first --git'
    alias lt='eza --tree --level=2 --icons --group-directories-first'
    alias l='eza -1 --icons --group-directories-first'
fi
if command -v bat >/dev/null; then
    alias cat='bat --style=plain --pager=never'
elif command -v batcat >/dev/null; then
    alias bat='batcat'
    alias cat='batcat --style=plain --pager=never'
fi
command -v rg >/dev/null && alias grep='rg'
if command -v fd >/dev/null; then
    alias find='fd'
elif command -v fdfind >/dev/null; then
    alias fd='fdfind'
    alias find='fdfind'
fi
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias top='btop'
alias ports='ss -tulpn'
alias myip='curl -s ifconfig.me; echo'

if command -v apt-get >/dev/null; then
    alias update='sudo apt-get update && sudo apt-get full-upgrade -y'
    alias cleanup='sudo apt-get autoremove -y && sudo apt-get autoclean'
elif command -v dnf >/dev/null; then
    alias update='sudo dnf upgrade -y'
    alias cleanup='sudo dnf autoremove -y && sudo dnf clean all'
elif command -v pacman >/dev/null; then
    alias update='sudo pacman -Syu'
    alias cleanup='sudo pacman -Sc'
fi

rice() {
    local dir
    dir="$(cat "$HOME/.config/ricing/repo-dir" 2>/dev/null || echo "$HOME/.local/share/linux-mint-rice")"
    cd "$dir" && ls -la
}
alias reload-i3='i3-msg reload && ~/.config/polybar/scripts/launch.sh'
alias effects='~/.config/i3/scripts/effects.sh'
alias theme='~/.config/i3/scripts/theme-switch.sh'
