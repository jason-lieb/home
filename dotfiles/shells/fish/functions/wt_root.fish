function wt_root
    if set -q WORKTREE_ROOT
        echo "$WORKTREE_ROOT"
    else
        echo "$HOME/code/.worktrees"
    end
end
