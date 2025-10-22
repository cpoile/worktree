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

SERVER_DIR_NAME=$(get_server_dir_name)
ENTERPRISE_DIR_NAME=$(get_enterprise_dir_name)
BASENAME=$(basename "$(pwd)")

# Get available branches from server repo
_worktree_branches() {
    if [ -d "$SERVER_DIR_NAME/.git" ]; then
        (cd "$SERVER_DIR_NAME" 2>/dev/null && {
            git branch --format='%(refname:short)' 2>/dev/null | grep -v '^master$' | grep -v '^main$'
            git branch -r --format='%(refname:short)' 2>/dev/null | sed 's|origin/||' | grep -v HEAD | grep -v '^master$' | grep -v '^main$'
        } | sort -u 2>/dev/null)
    fi
}

# Get all branches including main/master for base branch selection
_worktree_all_branches() {
    if [ -d "$SERVER_DIR_NAME/.git" ]; then
        (cd "$SERVER_DIR_NAME" 2>/dev/null && {
            git branch --format='%(refname:short)' 2>/dev/null
            git branch -r --format='%(refname:short)' 2>/dev/null | sed 's|origin/||' | grep -v HEAD
        } | sort -u 2>/dev/null)
    fi
}

# Get existing worktree branch names and short names
_worktree_existing_branches() {
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
            # Get the branch name
            local branch=$(cd "$dir/$SERVER_DIR_NAME" 2>/dev/null && git branch --show-current 2>/dev/null)
            if [ -n "$branch" ]; then
                echo "$branch"
            fi

            # Also get the short name (directory suffix)
            local short_name=$(basename "$dir" | sed "s/^$BASENAME-//")
            if [ -n "$short_name" ]; then
                echo "$short_name"
            fi
        fi
    done | sort -u
}

# Zsh completion using compctl
if [ -n "$ZSH_VERSION" ]; then
    # Completion function that handles commands and arguments
    _worktree_complete() {
        local words=("${(@s/ /)BUFFER}")
        local current_word="${words[-1]}"
        local prev_word="${words[-2]:-}"
        local word_count=${#words[@]}
        
        # If we're completing the first argument
        if [ $word_count -eq 2 ] || ([ $word_count -eq 1 ] && [ -z "$current_word" ]); then
            # Complete with commands only
            local commands="create remove list"
            reply=(${(s/ /)commands})
        elif [ $word_count -eq 3 ] || ([ $word_count -eq 2 ] && [ -n "$current_word" ]); then
            # Complete second argument based on first argument
            case "$prev_word" in
                "create")
                    # Complete with available branches for first argument
                    reply=(${(f)"$(_worktree_branches)"})
                    ;;
                "remove")
                    # Complete with existing branch names
                    reply=(${(f)"$(_worktree_existing_branches)"})
                    ;;
                "list")
                    # No completion needed for list
                    reply=()
                    ;;
                *)
                    # No additional completion
                    reply=()
                    ;;
            esac
        elif [ $word_count -eq 4 ] || ([ $word_count -eq 3 ] && [ -n "$current_word" ]); then
            # Complete third argument (only for create command - short name)
            local first_cmd="${words[1]}"
            if [ "$first_cmd" = "create" ]; then
                # For create command, third argument is short-name - no completion
                reply=()
            else
                reply=()
            fi
        else
            reply=()
        fi
    }
    
    # Use compctl for completion
    compctl -K _worktree_complete worktree
    compctl -K _worktree_complete ./worktree
    
    echo "Zsh completion loaded for worktree with subcommands"
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
        # Complete third argument (short-name for create command)
        elif [ $COMP_CWORD -eq 3 ]; then
            # Only create command has a third argument
            if [ "${COMP_WORDS[1]}" = "create" ]; then
                # Short name - no completion suggestions
                COMPREPLY=()
            else
                COMPREPLY=()
            fi
        else
            COMPREPLY=()
        fi
    }
    
    complete -F _worktree_bash_complete worktree
    complete -F _worktree_bash_complete ./worktree
    
    echo "Bash completion loaded for worktree with subcommands"
fi