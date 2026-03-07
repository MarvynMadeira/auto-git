#!/bin/bash 

FZF_COMMON="--height 50% --layout reverse --border --color bg:#1a1a2e,preview-bg:#16213e,fg:#e0e0e0,hl:#ff6b6b,border:#663333"

function was_cancelled() {
    return $( [ $? -eq 130 ] && echo 1 || echo 0 )
}

function require_gh() {
    if ! command -v gh &>/dev/null; then
        echo "[ERROR] This function req GitHub CLI (gh)."
        echo "Install with: brew install gh  or  https://cli.github.com"
        return 1
    fi
    return 0
}

function list_prs() {
    require_gh || return

    echo "Loading Open PRs..."

    pr_list=$(gh pr list --state open --json number,title,author,headRefName \
        --template '{{range .}}#{{.number}} [{{.headRefName}}] {{.title}} — {{.author.login}}{{"\n"}}{{end}}')
    
    if [ -z "$pr_list" ]; then
        echo "No open Pull Requests found."
        return
    fi

    selected=$(echo "$pr_list" | fzf +m $FZF_COMMON \
        --header "Pull Requests Open:" \
        --preview 'gh pr diff $(echo {} | grep -o "#[0-9]*" | tr -d "#") --color=always 2>/dev/null')

    [ -z "$selected" ] && return

    pr_number=$(echo "$selected" | grep -o "#[0-9]*" | tr -d "#")
    echo ""
    echo "PR #$pr_number selected."
    gh pr view "$pr_number"
    echo ""
    echo "Press ENTER to return."
    read -r
}

#Faz merge de um PR aberto: