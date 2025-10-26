# dotfiles


Files:

- `.bashrc`
- `.bash_profile`
- `.zshrc`
- `.zshenv`
- `.zsh-nvm-lazy-load.plugin.zsh`
- `./config/` and `./local/` for machine-specific bits

![screenshot](screenshots/screenshot_1.png)

Install (example):

```bash
git clone <repo> ~/dotfiles
cd ~/dotfiles
ln -s ~/.dotfiles/.zshrc ~/.zshrc  # or copy if you prefer
```

Notes:

- Back up existing dotfiles before replacing them.
- Keep secrets out of the repo (`~/.local` is fine).

License: do what you want.

