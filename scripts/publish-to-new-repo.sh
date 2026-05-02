#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/publish-to-new-repo.sh <new_repo_url> [--keep-history] [--skip-rename]

Examples:
  ./scripts/publish-to-new-repo.sh git@github.com:your-org/python-starter-template.git
  ./scripts/publish-to-new-repo.sh https://github.com/your-org/python-starter-template.git --keep-history
  ./scripts/publish-to-new-repo.sh https://github.com/your-org/my-project.git --skip-rename

Behavior:
  - Default: Deletes .git, re-initializes repository, creates a new initial commit,
    pushes to <new_repo_url>, and renames parent directory to match repo name.
  - --keep-history: Keeps existing git history and points origin to <new_repo_url>.
  - --skip-rename: Do not rename parent directory (keep current directory name).
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" || $# -lt 1 ]]; then
  usage
  exit 0
fi

NEW_REPO_URL="$1"
MODE="fresh"
SKIP_RENAME=false

# Parse optional flags
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep-history)
      MODE="keep"
      shift
      ;;
    --skip-rename)
      SKIP_RENAME=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if ! command -v git >/dev/null 2>&1; then
  echo "git is required but not found in PATH."
  exit 1
fi

# Extract repo name from URL
extract_repo_name() {
  local url="$1"
  # Remove protocol (git@, https://, etc.)
  url="${url##*[:/]}"
  # Remove .git suffix
  url="${url%.git}"
  # Get last part after final slash
  echo "${url##*/}"
}

REPO_NAME=$(extract_repo_name "$NEW_REPO_URL")

if [[ "$MODE" == "keep" ]]; then
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "This folder is not a git repository."
    exit 1
  fi

  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$NEW_REPO_URL"
  else
    git remote add origin "$NEW_REPO_URL"
  fi

  git branch -M main
  git push -u origin main

  echo "Published with existing history to: $NEW_REPO_URL"
  
  if [[ "$SKIP_RENAME" == false ]]; then
    PARENT_DIR=$(dirname "$(pwd)")
    CURRENT_DIR=$(basename "$(pwd)")
    if [[ "$CURRENT_DIR" != "$REPO_NAME" ]]; then
      echo "Renaming directory from $CURRENT_DIR to $REPO_NAME..."
      cd "$PARENT_DIR"
      mv "$CURRENT_DIR" "$REPO_NAME"
      echo "Renamed successfully. New path: $PARENT_DIR/$REPO_NAME"
    fi
  fi
  exit 0
fi

# Fresh-history mode
if [[ ! -d .git ]]; then
  echo "No .git directory found. Fresh-history mode requires a local clone with .git present."
  exit 1
fi

rm -rf .git
git init
git add .
git commit -m "Initial commit"
git remote add origin "$NEW_REPO_URL"
git branch -M main
git push -u --force origin main

echo "Published with fresh history to: $NEW_REPO_URL"

if [[ "$SKIP_RENAME" == false ]]; then
  PARENT_DIR=$(dirname "$(pwd)")
  CURRENT_DIR=$(basename "$(pwd)")
  if [[ "$CURRENT_DIR" != "$REPO_NAME" ]]; then
    echo "Renaming directory from $CURRENT_DIR to $REPO_NAME..."
    cd "$PARENT_DIR"
    mv "$CURRENT_DIR" "$REPO_NAME"
    echo "Renamed successfully. New path: $PARENT_DIR/$REPO_NAME"
  fi
fi
