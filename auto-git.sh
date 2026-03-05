#!/bin/bash

selected=$(git branch | fzf --height 40% --layout reverse --border)

selected=$(echo $selected | tr -d '* ')

echo ">>> $selected"

git switch "$selected"


