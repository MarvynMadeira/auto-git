#!/bin/bash 

FZF_COMMON="--height 50% --layout reverse --border --color bg:#1a1a2e,preview-bg:#16213e,fg:#e0e0e0,hl:#00d4ff,border:#333366"

function exit_exception (){
    if [ $? -eq 130 ]; then
    echo "Exiting..."
    exit 1

    fi
}

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

function delete_branch () {

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

function merge () {

selected=$(git branch | fzf +m \
    --header "Select the branch to merge:" \
    --height 100% \
    --layout reverse \
    --border \
    --preview \
        'git -c color.ui=always diff $(git branch | grep "^\*" | tr -d "* ") $(echo {} | tr -d "* ")' \
    --color bg:#222222,preview-bg:#333333)

selected=$(echo $selected | tr -d '* ')

git merge "$selected"
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
