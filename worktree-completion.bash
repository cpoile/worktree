#!/bin/bash

# Working completion for worktree script with subcommands

# Get directory names from the main worktree script
get_server_dir_name() {
    if [ -f "./worktree" ]; then
        grep '^SERVER_DIR_NAME=' "./worktree" 2>/dev/null | cut -d'=' -f2 | tr -d '"'
    else
        echo "server"  # fallback default
    fi
}

get_enterprise_dir_name() {
    if [ -f "./worktree" ]; then
        grep '^ENTERPRISE_DIR_NAME=' "./worktree" 2>/dev/null | cut -d'=' -f2 | tr -d '"'
    else
        echo "enterprise"  # fallback default
    fi
}

# Get available branches from server repo
_worktree_branches() {
    local SERVER_DIR_NAME=$(get_server_dir_name)
    if [ -d "$SERVER_DIR_NAME/.git" ]; then
        (cd "$SERVER_DIR_NAME" 2>/dev/null && {
            git branch --format='%(refname:short)' 2>/dev/null | grep -v '^master$' | grep -v '^main$'
            git branch -r --format='%(refname:short)' 2>/dev/null | sed 's|origin/||' | grep -v HEAD | grep -v '^master$' | grep -v '^main$'
        } | sort -u 2>/dev/null)
    fi
}

# Get all branches including main/master for base branch selection
_worktree_all_branches() {
    local SERVER_DIR_NAME=$(get_server_dir_name)
    if [ -d "$SERVER_DIR_NAME/.git" ]; then
        (cd "$SERVER_DIR_NAME" 2>/dev/null && {
            git branch --format='%(refname:short)' 2>/dev/null
            git branch -r --format='%(refname:short)' 2>/dev/null | sed 's|origin/||' | grep -v HEAD
        } | sort -u 2>/dev/null)
    fi
}

# Get existing worktree branch names
_worktree_existing_branches() {
    local SERVER_DIR_NAME=$(get_server_dir_name)
    local ENTERPRISE_DIR_NAME=$(get_enterprise_dir_name)
    local BASENAME=$(basename "$(pwd)")
    local parent_dir=$(dirname "$(pwd)")
    local branches=""

    # We can run from any directory that has server and enterprise subdirs
    if [ ! -d "$SERVER_DIR_NAME" ] || [ ! -d "$ENTERPRISE_DIR_NAME" ]; then
        return
    fi

    for dir in "$parent_dir"/$BASENAME-*; do
        # Skip if directory doesn't exist or is a file
        if [ ! -d "$dir" ]; then
            continue
        fi
        
        # Check if it has a server directory with git (worktrees have .git file, not directory)
        if [ -d "$dir/$SERVER_DIR_NAME" ] && ([ -d "$dir/$SERVER_DIR_NAME/.git" ] || [ -f "$dir/$SERVER_DIR_NAME/.git" ]); then
            local branch=$(cd "$dir/$SERVER_DIR_NAME" 2>/dev/null && git branch --show-current 2>/dev/null)
            if [ -n "$branch" ]; then
                echo "$branch"
            fi
        fi
    done | sort -u
}

# Zsh completion using compdef (compsys)
if [ -n "$ZSH_VERSION" ]; then
    _worktree_complete() {
        local -a subcmds
        subcmds=(
            'create:Create a new worktree from a branch'
            'remove:Remove an existing worktree'
            'list:List existing worktrees'
        )

        if (( CURRENT == 2 )); then
            _describe 'subcommand' subcmds
        elif (( CURRENT == 3 )); then
            case "${words[2]}" in
                create)
                    local -a branches
                    branches=(${(f)"$(_worktree_branches)"})
                    _describe 'branch' branches
                    ;;
                remove)
                    local -a existing
                    existing=(${(f)"$(_worktree_existing_branches)"})
                    _describe 'worktree' existing
                    ;;
            esac
        elif (( CURRENT == 4 )); then
            case "${words[2]}" in
                remove)
                    local -a flags=('--force:Force removal')
                    _describe 'flag' flags
                    ;;
            esac
        fi
    }

    compdef _worktree_complete worktree
    compdef _worktree_complete ./worktree
fi

# Bash completion
if [ -n "$BASH_VERSION" ]; then
    _worktree_bash_complete() {
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local prev="${COMP_WORDS[COMP_CWORD-1]}"
        local word_count=${#COMP_WORDS[@]}
        
        # Complete first argument
        if [ $COMP_CWORD -eq 1 ]; then
            local commands="create remove list"
            COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        # Complete second argument based on first
        elif [ $COMP_CWORD -eq 2 ]; then
            case "$prev" in
                "create")
                    local branches=$(_worktree_branches)
                    COMPREPLY=($(compgen -W "$branches" -- "$cur"))
                    ;;
                "remove")
                    local existing=$(_worktree_existing_branches)
                    COMPREPLY=($(compgen -W "$existing" -- "$cur"))
                    ;;
                "list")
                    COMPREPLY=()
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
        # Complete third argument (short-name for create command, --force for remove)
        elif [ $COMP_CWORD -eq 3 ]; then
            case "${COMP_WORDS[1]}" in
                "create")
                    # Short name - no completion suggestions
                    COMPREPLY=()
                    ;;
                "remove")
                    # Suggest --force flag
                    COMPREPLY=($(compgen -W "--force" -- "$cur"))
                    ;;
                *)
                    COMPREPLY=()
                    ;;
            esac
        else
            COMPREPLY=()
        fi
    }
    
    complete -F _worktree_bash_complete worktree
    complete -F _worktree_bash_complete ./worktree

    echo "Bash completion loaded for worktree with subcommands"
fi