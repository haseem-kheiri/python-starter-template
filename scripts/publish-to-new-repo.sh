#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/publish-to-new-repo.sh <new_repo_url> [--keep-history]

Examples:
  ./scripts/publish-to-new-repo.sh git@github.com:your-org/python-starter-template.git
  ./scripts/publish-to-new-repo.sh https://github.com/your-org/python-starter-template.git --keep-history

Behavior:
  - Default: Deletes .git, re-initializes repository, creates a new initial commit,
    then pushes to <new_repo_url>.
  - --keep-history: Keeps existing git history and points origin to <new_repo_url>.
EOF
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" || $# -lt 1 ]]; then
  usage
  exit 0
fi

NEW_REPO_URL="$1"
MODE="fresh"

if [[ ${2:-} == "--keep-history" ]]; then
  MODE="keep"
elif [[ $# -ge 2 ]]; then
  echo "Unknown option: $2"
  usage
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is required but not found in PATH."
  exit 1
fi

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
git push -u origin main

echo "Published with fresh history to: $NEW_REPO_URL"
