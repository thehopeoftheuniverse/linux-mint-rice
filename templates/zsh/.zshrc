# ════════════════════════════════════════════════════════════════════════════
#  zsh · Tokyo Night rice  ·  built from ~/Desktop/ricing
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

export EDITOR=nano
export VISUAL=nano
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

# ── prompt ──────────────────────────────────────────────────────────────────
autoload -Uz add-zsh-hook vcs_info
setopt PROMPT_SUBST
zstyle ':vcs_info:git:*' formats       " %F{$PURPLE}on %b%f"
zstyle ':vcs_info:git:*' actionformats " %F{$PURPLE}on %b|%a%f"
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr   "%F{$YELLOW}●%f"
zstyle ':vcs_info:git:*' stagedstr     "%F{$GREEN}●%f"

_prompt_precmd() {
    local exit_code=$?
    vcs_info
    PROMPT="%F{$BLUE}%n%f%F{$MUTED}@%f%F{$TEAL}%m%f %F{$FG_DIM}%2~%f${vcs_info_msg_0_}
%(?.%F{$BLUE}.%F{$RED})❯%f "
    RPROMPT="%F{$MUTED}%(?..[%?])%f"
    return $exit_code
}
add-zsh-hook precmd _prompt_precmd

# ── tools ───────────────────────────────────────────────────────────────────
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
[[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && \
    source /usr/share/doc/fzf/examples/key-bindings.zsh
[[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && \
    source /usr/share/doc/fzf/examples/completion.zsh
[[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── aliases ─────────────────────────────────────────────────────────────────
if command -v eza >/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lh --icons --group-directories-first --git'
    alias la='eza -lah --icons --group-directories-first --git'
    alias lt='eza --tree --level=2 --icons --group-directories-first'
    alias l='eza -1 --icons --group-directories-first'
fi
command -v bat >/dev/null && alias cat='bat --style=plain --pager=never'
command -v rg  >/dev/null && alias grep='rg'
command -v fd  >/dev/null && alias find='fd'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias top='btop'
alias ports='ss -tulpn'
alias myip='curl -s ifconfig.me; echo'
alias update='sudo apt update && sudo apt full-upgrade -y'
alias cleanup='sudo apt autoremove -y && sudo apt autoclean'
alias rice='cd ~/Desktop/ricing && ls -la'
alias reload-i3='i3-msg reload && polybar-msg cmd restart'
alias effects='~/.config/i3/scripts/effects.sh'
alias theme='~/.config/i3/scripts/theme-switch.sh'
