#!/usr/bin/env bash
# Update the repo's home/ dotfiles with files from the user's $HOME
# Usage: ./update_from_home.sh [--dry-run] [--backup-dir DIR]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$REPO_DIR/home"
DRY_RUN=false
BACKUP_BASE="${BACKUP_BASE:-$REPO_DIR/.updates_backup}"

usage() {
  cat <<EOF
Usage: $0 [--dry-run] [--backup-dir DIR]

This copies files that exist in "$DOTFILES_DIR" from your $HOME into the repo.
It will back up the repo copy before overwriting into "$BACKUP_BASE/<timestamp>/".

Options:
  --dry-run        Show what would be done without making changes
  --backup-dir DIR Use DIR as the base backup directory
  -h, --help       Show this help
EOF
}

while [[ ${#} -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --backup-dir) BACKUP_BASE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
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

echo "Updating repo dotfiles in: $DOTFILES_DIR"
echo "Backups will be stored in: $BACKUP_DIR"

shopt -s dotglob 2>/dev/null || true

for src in "$DOTFILES_DIR"/.*; do
  name=$(basename "$src")
  # skip . and ..
  [[ "$name" = "." || "$name" = ".." ]] && continue

  homefile="$HOME/$name"
  repofile="$DOTFILES_DIR/$name"

  if [ ! -e "$homefile" ] && [ ! -L "$homefile" ]; then
    echo "Skipping $name: no file at $homefile"
    continue
  fi

  # if identical, skip
  if command -v cmp >/dev/null 2>&1; then
    if cmp -s "$homefile" "$repofile" 2>/dev/null; then
      echo "Skipping $name: identical"
      continue
    fi
  fi

  echo "Preparing to update $name"
  do_cmd "mkdir -p '$BACKUP_DIR'"
  if [ -e "$repofile" ] || [ -L "$repofile" ]; then
    echo "Backing up existing repo file $repofile -> $BACKUP_DIR/"
    do_cmd "mv -v '$repofile' '$BACKUP_DIR/'"
  fi

  echo "Copying $homefile -> $repofile"
  # Prefer rsync if available, otherwise use cp -a
  if command -v rsync >/dev/null 2>&1; then
    do_cmd "rsync -a --delete --links --perms --times --omit-dir-times '$homefile' '$repofile'"
  else
    do_cmd "cp -a '$homefile' '$repofile'"
  fi
done

echo "Done. Backups (if any) are in: $BACKUP_DIR"
if [ "$DRY_RUN" = true ]; then
  echo "(Dry-run: no changes were made.)"
fi
