#!/bin/bash 

function exit_exception (){
    if [ $? -eq 130 ]; then
    echo "Exiting..."
    exit 1

    fi
}

function switch_branch () {

selected=$(git branch | fzf +m \
    --height 40% \
    --layout reverse \
    --border \
    --preview \
        'git -c color.ui=always log --oneline $(echo {} | tr -d "* ")' \
    --color bg:#222222,preview-bg:#333333)

exit_exception

selected=$(echo $selected | tr -d '* ')

git switch "$selected"
}

function merge () {

selected=$(git branch | fzf +m \
    --height 100% \
    --layout reverse \
    --border \
    --preview \
        'git -c color.ui=always diff $(git branch | grep "^\*" | tr -d "* ") $(echo {} | tr -d "* ")' \
    --color bg:#222222,preview-bg:#333333)

selected=$(echo $selected | tr -d '* ')

git merge "$selected"
}

function delete_branch () {

selected=$(git branch | fzf +m \
    --height 40% \
    --layout reverse \
    --border \
    --preview \
        'git -c color.ui=always diff $(git branch | grep "^\*" | tr -d "* ") $(echo {} | tr -d "* ")' \
    --color bg:#222222,preview-bg:#333333)

selected=$(echo $selected | tr -d '* ')

git branch -d "$selected"
}

function main (){
    options=(\
    "1 - Switch Branch" \
    "2 - Git Merge" \
    "3 - Delete Branch" \
    "Exit" \
    )

    selected=$(for opt in "${options[@]}" ; do echo $opt ; done | fzf +m \
    --height 40% \
    --layout reverse \
    --border \
    --color bg:#222222 \
    )
}

main
