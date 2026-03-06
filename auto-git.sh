#!/bin/bash 

FZF_COMMON="--height 50% --layout reverse --border --color bg:#1a1a2e,preview-bg:#16213e,fg:#e0e0e0,hl:#00d4ff,border:#333366"

function exit_exception (){
    if [ $? -eq 130 ]; then
    echo "Exiting..."
    exit 1

    fi
}

# Branchs and Merge

function switch_branch (){

    selected=$(git branch | fzf +m $FZF_COMMON \
        --header "Select the branch to go:" \
        --preview \
            'git -c color.ui=always log --oneline $(echo {} | tr -d "* ")')

    exit_exception

    selected=$(echo $selected | tr -d '* ')

    git switch "$selected"
}

function create_branch (){
    echo -n " New branch name: "
    read -r branch_name

    if [ -z "$branch_name" ]; then
        echo "No branch name provided. Aborting."
        exit 1
    fi
    
    echo ""
    base=$(git branch | fzf +m $FZF_COMMON \
    --header "Select the base branch (ESC = use current)" \
    ---preview \
        'git -c color.ui=always log --oneline $(echo {} | tr -d "* ")')

    if [ -z "$base"]; then
        git switch -c "$branch_name"
    else
        base=$(echo $base | tr -d '* ')
        git switch -c "$branch_name" "$base"
    fi
}

function delete_branch (){

    selected=$(git branch | fzf +m $FZF_COMMON \
        --header "Select the branch to DELETE:" \
        --preview \
            'git -c color.ui=always diff $(git branch | grep "^\*" | tr -d "* ") $(echo {} | tr -d "* ")')
        
    exit_exception

    selected=$(echo $selected | tr -d '* ')

    echo ""
    echo -n "Force delete? (y/n): "
    read -r force

    if [[ "$force" == "y" || "$force" == "Y" ]]; then
        git branch -D "$selected"
    else
        git branch -d "$selected"
    fi
}

function merge (){
    current=$(git branch | grep "^\*" | tr -d "* ")

    selected=$(git branch | grep -v "^\*" | fzf +m $FZF_COMMON \
        --header "Merge into [$current]:" \
        --preview \
            'git -c color.ui=always diff $current $(echo {} | tr -d "* ")')

    exit_exception

    selected=$(echo $selected | tr -d '* ')

    git merge "$selected"
}

function rebase (){
    current=$(git branch | grep "^\*" | tr -d "* ")

    selected=$(git branch | grep -v "^\*" | fzf +m $FZF_COMMON \
        --header "Rebase onto [$current]:" \
        --preview \
            'git -c color.ui=always log --oneline \$(echo {} | tr -d "* ")')

    exit_exception

    selected=$(echo $selected | tr -d '* ')

    echo "Rebasing '$current' onto '$selected'..."
    
    git rebase "$selected"
}

# Commit and Stash

function interactive_commit (){
    status=$(git status --short)

    if [ -z "$status" ]; then
        echo "Nothing to commit."
        return
    fi

    echo -n "Current status:"
    git status --short
    echo ""

    echo -n "Stage all files? (y/n): "
    read -r stage_all

    if [[ "$stage_all" == "y" || "$stage_all" == "Y" ]]; then
        git add .
    else
        echo "Select files to stage:"
        selected=$(echo "$status" | fzf +m $FZF_COMMON \
            --header "Select files to stage (TAB = multi-select):" \
            --preview \
                'git diff --color $(echo {} | awk "{print \$2}")')

        exit_exception

        echo "$selected" | awk '{print $2}' | xargs git add
    fi

    echo ""
    echo -n "Enter commit message: "
    read -r msg

    if [ -z "$msg" ]; then
        echo "No commit message provided. Aborting."
        return
    fi

    git commit -m "$msg"
}


function main (){
    options=(\
    "1 - Switch Branch" \
    "2 - Git Merge" \
    "3 - Delete Branch" \
    "Exit" \
    )

    selected=$(for opt in "${options[@]}" ; do echo $opt ; done | fzf +m \
    --header "Select one option:" \
    --height 40% \
    --layout reverse \
    --border \
    --color bg:#222222 \
    )

    exit_exception

    case "$selected" in
        ${options[0]})
            echo "$selected"
            switch_branch
            exit 0
            ;;
        ${options[1]})
            echo "$selected"
            merge
            exit 0
            ;;
        ${options[2]})
            echo "$selected"
            delete_branch
            exit 0
            ;;
        ${options[3]})
            echo "$selected"
            exit 0
            ;;
        *)
        exit 0
    esac
}

main
