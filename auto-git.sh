#!/bin/bash 

FZF_COMMON="--height 50% --layout reverse --border --color bg:#1a1a2e,preview-bg:#16213e,fg:#e0e0e0,hl:#00d4ff,border:#333366"

function exit_exception() {
    if [ $? -eq 130 ]; then
        echo "Exiting..."
        exit 1
    fi
}

# Branchs and Merge

function switch_branch() {

    selected=$(git branch | fzf +m $FZF_COMMON \
        --header "Select the branch to go:" \
        --preview \
            'git -c color.ui=always log --oneline $(echo {} | tr -d "* ")')

    exit_exception

    selected=$(echo $selected | tr -d '* ')

    git switch "$selected"
}

function create_branch() {
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

function delete_branch() {

    selected=$(git branch | fzf +m $FZF_COMMON \
        --header "Select branch to DELETE:" \
        --preview 'git -c color.ui=always log --oneline $(echo {} | tr -d "* ")')

    [ -z "$selected" ] && return
    selected=$(echo "$selected" | tr -d '* ')

    echo ""
    echo -n "  Force delete? (y/n): "
    read -r force

    if [[ "$force" == "y" || "$force" == "Y" ]]; then
        git branch -D "$selected"
    else
        git branch -d "$selected"
        [ $? -ne 0 ] && return
    fi

    echo ""

    if git ls-remote --exit-code --heads origin "$selected" &>/dev/null; then
        echo -n "Do you want to DELETE the branch in remote repository? (y/n): "
        read -r remote_del
        if [[ "$remote_del" == "y" || "$remote_del" == "Y" ]]; then
            git push origin --delete "$selected"
            echo "Branch '$selected' deleted local and remote."
        else
            echo "Branch '$selected' deleted only local."
        fi
    else
        echo "Branch '$selected' deleted ony local (was not exists in remote)."
    fi
}

function merge() {
    current=$(git branch | grep "^\*" | tr -d "* ")

    selected=$(git branch | grep -v "^\*" | fzf +m $FZF_COMMON \
        --header "Merge into [$current]:" \
        --preview \
            'git -c color.ui=always diff $current $(echo {} | tr -d "* ")')

    exit_exception

    selected=$(echo $selected | tr -d '* ')

    git merge "$selected"
}

function rebase() {
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

function interactive_commit() {
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

function amend_commit() {
    echo "Last commit: $(git log --oneline -1)"
    echo ""
    echo -n "New commit message:"
    read -r msg

    if [ -z "$msg" ]; then
        echo "No commit message provided. Aborting."
        return
    fi

    git commit --amend -m "$msg"
}

function cherry_pick() {
    selected=$(git log --oneline --all | fzf +m $FZF_COMMON \
        --header "Select commit to cherry-pick:" \
        --preview \
            'git show --color $(echo {} | awk "{print \$1}")')

    exit_exception

    hash=$(echo $selected | awk '{print $1}')

    git cherry-pick "$hash"
}

function reset_commits() {
    echo "Last 10 commits:"
    git log --oneline -10
    echo ""
    echo -n "How many commits to reset from HEAD? (ex: 1, 2):"
    read -r qty

    if ! [[ "$qty" =~ ^[0-9]+$ ]]; then
        echo "Invalid number. Aborting."
        return
    fi

    echo ""
    echo -n "Hard reset? WARNING: changes will be LOST! (y/n): "
    read -r hard

    if [[ "$hard" == "y" || "$hard" == "Y" ]]; then
        git reset --hard HEAD~"$qty"
    else
        git reset --soft HEAD~"$qty"
        echo "Soft reset done. Changes kept in staging"
    fi
}

function stash_save() {
    echo -n "Stash description (optional): "
    read -r desc

    if [ -z "$desc" ]; then
        git stash
    else
        git stash save "$desc"
    fi

    echo "Stash saved."
}

function stash_apply() {
    stash_list=$(git stash list)

    if [ -z "$stash_list" ]; then
        echo "No stashes found."
        return
    fi

    selected=$(echo "$stash_list" | fzf +m $FZF_COMMON \
        --header "Select stash to apply:" \
        --preview \
            'git stash show -p $(echo {} | cut -d: -f1)')

    exit_exception

    stash_id=$(echo $selected | cut -d: -f1)

    echo ""
    echo -n "Pop stash (removes after applying)? (y/n): "
    read -r pop

    if [[ "$pop" == "y" || "$pop" == "Y" ]]; then
        git stash pop "$stash_id"
    else
        git stash apply "$stash_id"
    fi
}

function stash_drop() {
    stash_list=$(git stash list)

    if [ -z "$stash_list" ]; then
        echo "No stashes found."
        return
    fi

    selected=$(echo "$stash_list" | fzf +m $FZF_COMMON \
        --header "  Select stash to DROP" \
        --preview 'git stash show -p $(echo {} | cut -d: -f1)')

    exit_expection
    stash_id=$(echo $selected | cut -d: -f1)
    git stash drop "$stash_id"
    echo "Stash '$stash_od' dropped."
}

# TAGS

function create_tag() {
    echo -n "Tag name (ex: V1.0):"
    read -r tag_name

    if [ -z "$tag_name" ]; then
        acho "No tag name. Aborting."
        return
    fi

    echo ""
    echo -n "Tag description:"
    read -r tag_desc

    echo ""
    echo -n "Tag a specific commit? (y/n - n = current HEAD): "
    read -r specific

    if [[ "$specific" == "y" || "$specific" == "Y" ]]; then
        commit=$(git log --oneline | fzf +m $FZF_COMMON \
            --header "  Select commit for tag [$tag_name]" \
            --preview 'git show --color $(echo {} | awk "{print \$1}")')
        exit_exception
        hash=$(echo "$commit" | awk '{print $1}')

        if [ -z "$tag_desc" ]; then
            git tag "$tag_name" "$hash"
        else
            git tag -a "$tag_name" "$hash" -m "$tag_desc"
        fi
    else
        if [ -z "$tag_desc" ]; then
            git tag "$tag_name"
        else
            git tag -a "$tag_name" -m "$tag_desc"
        fi
    fi

    echo "  Tag '$tag_name' created."
    echo ""
    echo -n "  Push tag to origin? (y/n): "
    read -r push_tag

    if [[ "$push_tag" == "y" || "$push_tag" == "Y" ]]; then
        git push origin "$tag_name"
    fi
}

function checkout_tag() {
    selected=$(git tag -l | fzf +m $FZF_COMMON \
        --header "  Navigate to tag (detached HEAD)" \
        --preview 'git show --color {}')

    exit_exception

    git checkout "$selected"
}

# LOG & DIFF

function visual_log() {
    git log --oneline --all | fzf +m $FZF_COMMON \
        --header "  Git Log — ENTER to inspect commit" \
        --preview 'git show --color $(echo {} | awk "{print \$1}")' \
        | awk '{print $1}' | xargs -I{} git show --color {}
}

function diff_branches() {
    current=$(git branch | grep "^\*" | tr -d '* ')

    selected=$(git branch | grep -v "^\*" | fzf +m $FZF_COMMON \
        --header "  Diff [$current] vs..." \
        --preview "git -c color.ui=always diff $current \$(echo {} | tr -d '* ')")

    exit_exception

    selected=$(echo "$selected" | tr -d '* ')

    git diff "$current" "$selected"
}

# LOG & DIFF

function require_gh() {
    if ! command -v gh &>/dev/null; then
        echo "[ERROR] This function req GitHub CLI (gh)."
        echo "Install with: https://cli.github.com or terminal command"
        return 1
    fi
    return 0
}

function create_pr() {
    require_gh || return

    current=$(git branch | grep "^\*" | tr -d '* ')

    if ! git ls-remote --exit-code --heads origin "$current" &>/dev/null; then
        echo "Branch '$current' doesn't exists in remote."
        echo -n "Do you want push now? (y/n): "
        read -r do_push

        if [["$do_push" == "y" || "$do_push" == "Y"]]; then
            git push -u origin "$current"
        else
            echo "Aborting. Push the branch before opening PR."
            return
        fi
    fi

    echo ""
    base=$(git branch -r | grep -v "HEAD" | sed 's/origin\///' | tr -d ' ' | \
        fzf +m $FZF_COMMON \
        --header "Branch's PR destiny (base)" \
        --preview "git -c color.ui=always log --oneline origin/{}")

    exit_exception

    echo ""
    echo -n "PR Title: "
    read -r pr_title

    if [ -z "$pr_title" ]; then
        echo "Title's required. Aborting."
        return
    fi

    echo ""
    echo -n "PR description (optional, Enter to skip): "
    read -r pr_body

    echo ""
    echo -n "Mark as Draft? (y/n): "
    read -r draft

    echo ""
    echo "Resume:"
    echo "Branch: $current → $base"
    echo "Title: $pr_title"
    [ -n "$pr_body" ] && "Desc:    $pr_body"
    [[ "$draft" == "y" || "$draft" == "Y" ]] && echo "  Mode:    Draft"
    echo ""
    echo -n "Confirm PR opening? (y/n): "
    read -r confirm

    if [["$confirm" != "y" && "$confirm" != "Y"]]; then
        echo "PR aborted."
        return
    fi

    #Dynamic command
    pr_cmd="gh pr create --base \"$base\" --title \"$pr_title\""
    [ -n "$pr_body" ]                          && pr_cmd+=" --body \"$pr_body\""
    [[ "$draft" == "y" || "$draft" == "Y" ]]   && pr_cmd+=" --draft"

    eval "$pr_cmd"
}

# REMOTE

function push_pull() {
    action=$(printf "push\n pull\n fetch" | fzf +m $FZF_COMMON \
        --header "Remote operation")
    
    exit_exception

    case "$action" in
        *push)
            current=$(git branch | grep "^\*" | tr -d "* ")

            upstream=$(git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2>/dev/null)

            if [ -z "$upstream" ]; then
                echo "Branch \'$current\' doesn't have upstream configured."
                echo ""

                remote=$(git remote | fzf +m $FZF_COMMON \
                    --header "Select the remote's destiny:" \
                    --preview "git remote get-url {}")

                exit_exception

                echo ""
                echo "Integrating \'$current\' to \'$remote/$current\'..."
                git push -u "$remote" "$current"
            else
                git push
            fi
            ;;
        *pull) 
            git pull
            ;;
        *fetch) 
            git fetch && echo "Done. Run pull to apply." 
            ;;
    esac
}



function main (){
    options=(
        "  BRANCH  │ Switch Branch"
        "  BRANCH  │ Create Branch"
        "  BRANCH  │ Delete Branch"
        "  BRANCH  │ Merge Branch"
        "  BRANCH  │ Rebase Branch"
        "  COMMIT  │ Interactive Commit"
        "  COMMIT  │ Amend Last Commit"
        "  COMMIT  │ Cherry-pick Commit"
        "  COMMIT  │ Reset Commits"
        "  STASH   │ Save Stash"
        "  STASH   │ Apply Stash"
        "  STASH   │ Drop Stash"
        "  TAG     │ Create Tag"
        "  TAG     │ Checkout Tag"
        "  LOG     │ Visual Log"
        "  LOG     │ Diff Branches"
        "  PR      │ Open Pull Request"
        "  REMOTE  │ Push / Pull / Fetch"
        "  ──────────────────────────────"
        "  EXIT"
    )

    selected=$(for opt in "${options[@]}"; do echo "$opt"; done | fzf +m \
        --height 70% \
        --layout reverse \
        --border \
        --header "  GITFLOW  [DEVELOPER] — Select an action" \
        --color "bg:#1a1a2e,fg:#e0e0e0,hl:#00d4ff,border:#333366,header:#00d4ff" \
        --no-sort)

    exit_exception

    case "$selected" in
        *"Switch Branch")       echo ""; switch_branch ;;
        *"Create Branch")       echo ""; create_branch ;;
        *"Delete Branch")       echo ""; delete_branch ;;
        *"Merge Branch")        echo ""; merge ;;
        *"Rebase Branch")       echo ""; rebase ;;
        *"Interactive Commit")  echo ""; interactive_commit ;;
        *"Amend Last Commit")   echo ""; amend_commit ;;
        *"Cherry-pick Commit")  echo ""; cherry_pick ;;
        *"Reset Commits")       echo ""; reset_commits ;;
        *"Save Stash")          echo ""; stash_save ;;
        *"Apply Stash")         echo ""; stash_apply ;;
        *"Drop Stash")          echo ""; stash_drop ;;
        *"Create Tag")          echo ""; create_tag ;;
        *"Checkout Tag")        echo ""; checkout_tag ;;
        *"Visual Log")          echo ""; visual_log ;;
        *"Diff Branches")       echo ""; diff_branches ;;
        *"Abrir Pull Request")   echo ""; create_pr ;;
        *"Push / Pull / Fetch") echo ""; push_pull ;;
        *"EXIT"|*"──────")      exit 0 ;;
        *) exit 0 ;;
    esac
}

main