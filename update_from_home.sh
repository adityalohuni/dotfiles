#!/usr/bin/env bash
# Update the repo's home/ dotfiles with files from the user's $HOME
# Usage: ./update_from_home.sh [--dry-run] [--backup-dir DIR]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$REPO_DIR/home"
CONFIG_SRC="$HOME/.config"
CONFIG_DST="$DOTFILES_DIR/.config"
DRY_RUN=false
BACKUP_BASE="${BACKUP_BASE:-$REPO_DIR/.updates_backup}"

usage() {
  cat <<EOF
Usage: $0 [--dry-run] [--backup-dir DIR]

This copies files that exist in "$DOTFILES_DIR" from your $HOME into the repo.
It also syncs your entire $HOME/.config into "$DOTFILES_DIR/.config".
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

do_cmd_argv() {
  if [ "$DRY_RUN" = true ]; then
    printf "DRY RUN:"
    printf " %q" "$@"
    printf "\n"
  else
    "$@"
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
  # .config is handled separately below
  [[ "$name" = ".config" ]] && continue

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

sync_config_dir() {
  if [ ! -d "$CONFIG_SRC" ] && [ ! -L "$CONFIG_SRC" ]; then
    echo "Skipping .config: no directory at $CONFIG_SRC"
    return
  fi

  tracked_paths=()
  if command -v git >/dev/null 2>&1; then
    while IFS= read -r path; do
      tracked_paths+=("$path")
    done < <(git -C "$REPO_DIR" ls-files -- 'home/.config/**')
  fi

  if [ "${#tracked_paths[@]}" -eq 0 ]; then
    echo "Skipping .config: no tracked files under $DOTFILES_DIR/.config"
    return
  fi

  echo "Preparing to update .config"
  do_cmd "mkdir -p '$BACKUP_DIR'"
  if [ -e "$CONFIG_DST" ] || [ -L "$CONFIG_DST" ]; then
    echo "Backing up existing repo dir $CONFIG_DST -> $BACKUP_DIR/"
    do_cmd "mv -v '$CONFIG_DST' '$BACKUP_DIR/'"
  fi

  echo "Copying $CONFIG_SRC -> $CONFIG_DST"
  do_cmd_argv mkdir -p "$CONFIG_DST"
  for tracked in "${tracked_paths[@]}"; do
    rel_path="${tracked#home/.config/}"
    src_path="$CONFIG_SRC/$rel_path"
    dst_path="$CONFIG_DST/$rel_path"

    if [ ! -e "$src_path" ] && [ ! -L "$src_path" ]; then
      echo "Skipping missing .config file: $src_path"
      continue
    fi

    do_cmd_argv mkdir -p "$(dirname "$dst_path")"
    if command -v rsync >/dev/null 2>&1; then
      do_cmd_argv rsync -a --links --perms --times --omit-dir-times "$src_path" "$dst_path"
    else
      do_cmd_argv cp -a "$src_path" "$dst_path"
    fi
  done
}

sync_config_dir

echo "Done. Backups (if any) are in: $BACKUP_DIR"
if [ "$DRY_RUN" = true ]; then
  echo "(Dry-run: no changes were made.)"
fi
