#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./path/to/python-starter-template/scripts/publish-to-new-repo.sh <new_repo_url> [--keep-history] [--skip-rename]

IMPORTANT: Run from the PARENT directory of the template folder, NOT from inside it.

Examples (correct):
  cd /path/to/repositories
  ./python-starter-template/scripts/publish-to-new-repo.sh git@github.com:your-org/python-learning-path.git
  ./python-starter-template/scripts/publish-to-new-repo.sh https://github.com/your-org/my-project.git --keep-history
  ./python-starter-template/scripts/publish-to-new-repo.sh https://github.com/your-org/my-project.git --skip-rename

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

# Rename a directory, with graceful fallback instructions on failure (e.g. Windows file locks)
rename_directory() {
  local old_name="$1"
  local new_name="$2"
  local parent="$3"
  echo "Renaming directory from $old_name to $new_name..."
  if mv "$old_name" "$new_name" 2>/dev/null; then
    echo "Renamed successfully. New path: $parent/$new_name"
  else
    echo ""
    echo "WARNING: Could not rename directory automatically (Windows may still hold file handles)."
    echo "Git publish succeeded. To complete setup, run this command once your terminal is clear:"
    echo ""
    echo "  mv \"$parent/$old_name\" \"$parent/$new_name\""
    echo ""
  fi
}

# Determine template directory (parent of scripts directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")"
CURRENT_DIR="$(pwd)"

# Safety check: prevent running from inside the template directory
if [[ "$CURRENT_DIR" == "$TEMPLATE_DIR" ]]; then
  echo "ERROR: This script must be run from the PARENT directory of the template folder."
  echo ""
  echo "Current location: $CURRENT_DIR"
  echo "Template directory: $TEMPLATE_DIR"
  echo ""
  echo "Correct usage:"
  echo "  cd $(dirname "$TEMPLATE_DIR")"
  echo "  ./$(basename "$TEMPLATE_DIR")/scripts/publish-to-new-repo.sh $NEW_REPO_URL"
  exit 1
fi

# Track directories for git operations and later rename
ORIGINAL_DIR="$TEMPLATE_DIR"
ORIGINAL_DIR_NAME=$(basename "$TEMPLATE_DIR")
PARENT_DIR=$(dirname "$TEMPLATE_DIR")

if [[ "$MODE" == "keep" ]]; then
  cd "$TEMPLATE_DIR"
  
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
  
  # Exit to parent to rename
  cd "$PARENT_DIR"
  
  # Now rename the directory if needed
  if [[ "$SKIP_RENAME" == false ]] && [[ "$ORIGINAL_DIR_NAME" != "$REPO_NAME" ]]; then
    rename_directory "$ORIGINAL_DIR_NAME" "$REPO_NAME" "$PARENT_DIR"
  fi
  exit 0
fi

# Fresh-history mode
echo "Published with fresh history to: $NEW_REPO_URL"
cd "$TEMPLATE_DIR"

if [[ ! -d .git ]]; then
  echo "No .git directory found. Fresh-history mode requires a local clone with .git present."
  exit 1
fi

rm -rf .git
git init
# Add everything except README.md and scripts/publish-to-new-repo.sh
find . \( -name README.md -o -path ./scripts/publish-to-new-repo.sh \) -prune -o -type f -print | git add -f --pathspec-from-file=-
git commit -m "Initial commit"
git remote add origin "$NEW_REPO_URL"
git branch -M main
git push -u --force origin main

echo "Published with fresh history to: $NEW_REPO_URL"

# Exit to parent to rename
cd "$PARENT_DIR"

# Now rename the directory if needed (we're now in parent directory, so rename is safe)
if [[ "$SKIP_RENAME" == false ]] && [[ "$ORIGINAL_DIR_NAME" != "$REPO_NAME" ]]; then
  rename_directory "$ORIGINAL_DIR_NAME" "$REPO_NAME" "$PARENT_DIR"
fi
