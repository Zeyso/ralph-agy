#!/bin/bash

# Ralph Wiggum - Long-running AI agent loop
# Adapted for Google Antigravity CLI (agy) support
# Usage: ./ralph.sh [--tool amp|claude|agy] [max_iterations]
#
# Runs automatically in a detached screen session so closing the
# VNC/console does NOT kill the process.
# To watch progress afterwards:  screen -r ralph

set -e

# ── Detach into background screen if not already inside one ──────────────
if [[ -z "$STY" ]]; then
  SCREEN_NAME="ralph"

  # If a session with this name already exists, refuse to start a second one
  if screen -list | grep -q "\.${SCREEN_NAME}"; then
    echo "⚠  A ralph screen session is already running."
    echo "   Attach with:  screen -r ${SCREEN_NAME}"
    echo "   Kill it with: screen -S ${SCREEN_NAME} -X quit"
    exit 1
  fi

  echo "▶  Starting Ralph in detached screen session '${SCREEN_NAME}'..."
  echo "   Attach anytime with:  screen -r ${SCREEN_NAME}"
  echo "   Detach again with:    Ctrl-A  D"
  echo "   View log file:        tail -f \$(pwd)/ralph-run.log"

  # Re-launch this exact script with all original arguments inside a detached screen.
  # stdout/stderr are tee'd into ralph-run.log in the current directory.
  screen -dmS "${SCREEN_NAME}" bash -c \
    "\"$0\" $* 2>&1 | tee -a \"$(pwd)/ralph-run.log\"; echo 'Ralph session ended.'"

  exit 0
fi
# ── Everything below runs inside the screen session ──────────────────────

# Parse arguments
TOOL="agy"  # Default to agy
MAX_ITERATIONS=10

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)
      TOOL="$2"
      shift 2
      ;;
    --tool=*)
      TOOL="${1#*=}"
      shift
      ;;
    *)
      # Assume it's max_iterations if it's a number
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

# Validate tool choice
if [[ "$TOOL" != "amp" && "$TOOL" != "claude" && "$TOOL" != "agy" ]]; then
  echo "Error: Invalid tool '$TOOL'. Must be 'amp', 'claude', or 'agy'."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If running from /usr/local/bin, use /workspace as base
if [[ "$SCRIPT_DIR" == "/usr/local/bin" ]]; then
  SCRIPT_DIR="/workspace"
fi

# Workspace = current directory (your project repo)
WORKSPACE_DIR="$(pwd)"
PRD_FILE="$WORKSPACE_DIR/prd.json"
PROGRESS_FILE="$WORKSPACE_DIR/progress.txt"
ARCHIVE_DIR="$WORKSPACE_DIR/archive"
LAST_BRANCH_FILE="$WORKSPACE_DIR/.last-branch"

# Pick the right prompt file
if [[ "$TOOL" == "agy" ]]; then
  PROMPT_FILE="$SCRIPT_DIR/agy-prompt.md"
elif [[ "$TOOL" == "claude" ]]; then
  PROMPT_FILE="$SCRIPT_DIR/CLAUDE.md"
else
  PROMPT_FILE="$SCRIPT_DIR/prompt.md"
fi

if [ ! -f "$PROMPT_FILE" ]; then
  echo "Error: Prompt file not found: $PROMPT_FILE"
  exit 1
fi

if [ ! -f "$PRD_FILE" ]; then
  echo "Error: prd.json not found in $WORKSPACE_DIR"
  echo "Please create a prd.json (see prd.json.example for format)"
  exit 1
fi

# Archive previous run if branch changed
if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")

  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    DATE=$(date +%Y-%m-%d)
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"

    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    echo "  Archived to: $ARCHIVE_FOLDER"

    # Reset progress file for new run
    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

# Track current branch
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

echo "Starting Ralph - Tool: $TOOL - Max iterations: $MAX_ITERATIONS"
echo "Workspace: $WORKSPACE_DIR"
echo "Prompt: $PROMPT_FILE"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "==============================================================="
  echo " Ralph Iteration $i of $MAX_ITERATIONS ($TOOL)"
  echo "==============================================================="

  # Run the selected tool with the ralph prompt
  if [[ "$TOOL" == "agy" ]]; then
    # agy: pipe prompt via stdin, use --dangerously-skip-permissions for autonomous mode
    OUTPUT=$(agy --dangerously-skip-permissions --print < "$PROMPT_FILE" 2>&1 | tee /dev/stderr) || true

  elif [[ "$TOOL" == "amp" ]]; then
    OUTPUT=$(cat "$PROMPT_FILE" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true

  else
    # Claude Code
    OUTPUT=$(claude --dangerously-skip-permissions --print < "$PROMPT_FILE" 2>&1 | tee /dev/stderr) || true
  fi

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "Ralph completed all tasks!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    exit 0
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
exit 1
