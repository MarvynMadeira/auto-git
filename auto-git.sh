#!/bin/bash

selected=$(git branch | fzf \
--height 40% \
--layout reverse \
--border \
--preview 'git log --oneline')

selected=$(echo $selected | tr -d '* ')

echo "$selected"

git switch "$selected"