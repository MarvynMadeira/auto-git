#!/bin/bash 

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

FZF_THEME="--color bg:#1a1a2e,fg:#e0e0e0,hl:#00d4ff,border:#333366,header:#00d4ff"

function exit_exception() {
    if [ $? -eq 130 ]; then
        echo "  Exiting..."
        exit 1
    fi
}

if ! command -v fzf &>/dev/null; then
    echo "[ERROR] fzf not found. Install with: brew install fzf  or  apt install fzf"
    exit 1
fi

profile=$(printf " Developer\n Operator" | fzf +m \
    --height 30% \
        --layout reverse \
        --border \
        --header "GITFLOW — What's your profile?  (ESC = exit)" \
    $FZF_THEME \
    --no-sort)

exit_exception
[ -z "$profile" ] && exit 0

case "$profile" in
    *"Developer")
        "$SCRIPT_DIR/auto-git.sh"
        ;;
        *"Operator")
            if ! command -v gh &>/dev/null; then
            echo ""
            echo "[WARNING] GitHub Cli (gh) not found."
            echo "The operator's functions depends on GitHub Cli."
            echo "Install with: brew install gh  or  https://cli.github.com"
            echo ""
            echo -n "Ignore and continue? (y/n): "
            read -r proceed

            if [[ "$proceed" != "y" && "$proceed" != "Y" ]]; then
                exit 0
            fi
        fi
        "$SCRIPT_DIR/operator-git.sh"
        ;;
        *)
        exit 0
        ;;
    esac


