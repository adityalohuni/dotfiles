#!/usr/bin/env bash
# Bootstrap script to symlink files from this repository's home/ into $HOME
# Usage: ./bootstrap.sh [--dry-run] [--backup-dir DIR]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$REPO_DIR/home"
DRY_RUN=false
BACKUP_BASE="${BACKUP_BASE:-$HOME/.dotfiles_backup}"

while [[ ${#} -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --backup-dir) BACKUP_BASE="$2"; shift 2 ;;
    -h|--help) echo "Usage: $0 [--dry-run] [--backup-dir DIR]"; exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

timestamp() { date +%Y%m%d-%H%M%S; }

do_cmd() {
  if [ "$DRY_RUN" = true ]; then
    printf "DRY RUN: %s\n" "$*"
  else
    eval "$*"
  fi
}

mkdir -p "$BACKUP_BASE"
BACKUP_DIR="$BACKUP_BASE/backup-$(timestamp)"

echo "Installing dotfiles from: $DOTFILES_DIR"
echo "Backup dir: $BACKUP_DIR"

for src in "$DOTFILES_DIR"/.*; do
  name=$(basename "$src")
  # skip . and ..
  [[ "$name" = "." || "$name" = ".." ]] && continue

  target="$HOME/$name"

  # If target exists and is not the desired symlink, move to backup
  if [ -e "$target" ] || [ -L "$target" ]; then
    # Check if it's already the correct symlink
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$src")" ]; then
      echo "Skipping $name: already symlinked"
      continue
    fi

    echo "Backing up existing $target -> $BACKUP_DIR/"
    do_cmd "mkdir -p '$BACKUP_DIR'"
    do_cmd "mv '$target' '$BACKUP_DIR/'"
  fi

  echo "Linking $src -> $target"
  do_cmd "ln -s '$src' '$target'"
done

echo "Done. If you used --dry-run no changes were written. Backups (if any) are in: $BACKUP_DIR"
