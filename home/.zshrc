#!/usr/bin/env zsh
# moved from repo root: .zshrc

export TERMINFO=/usr/share/terminfo

# Conda
### For Conda SSL Warning
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1

# vi mode
source /usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# Use powerline
USE_POWERLINE="true"
# Has weird character width
# Example:
#    is not a diamond
HAS_WIDECHARS="false"

# Use Maia zsh prompt
if [[ -e /usr/share/zsh/zsh-maia-prompt ]]; then
  source /usr/share/zsh/zsh-maia-prompt
fi

alias xx="tmux -u"
alias hx="helix"

# Beautiful ls command with exa
alias ll="exa -lgh --icons --group-directories-first"
alias la="exa -lgha --icons --group-directories-first"

# NVM load lazy
source ~/.zsh-nvm-lazy-load.plugin.zsh

[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh

# GO Path
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin


# Cargo path
export CARGOPATH=$HOME/.cargo
export PATH=$PATH:$CARGOPATH/bin
