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
    echo "Joe"

selected=$(git branch | fzf +m \
    --height 100% \
    --layout reverse \
    --border \
    --preview \
    'git -c color.ui=always diff $(git branch | grep "^\*" | tr -d "* ") $(echo {} | tr -d "* ")' \
    --color bg:#222222,preview-bg:#333333)

selected=$(echo $selected | tr -d '* ')

echo "$selected"

git merge "$selected"
}

merge

