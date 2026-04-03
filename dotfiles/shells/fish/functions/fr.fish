function fr
    set main_repo (git worktree list --porcelain | grep '^worktree ' | head -1 | string replace 'worktree ' '')
    set current_branch (git -C $main_repo rev-parse --abbrev-ref HEAD)

    if test $current_branch = "main"
        git -C $main_repo fetch origin && git -C $main_repo rebase origin/main && git -C $main_repo remote prune origin
    else
        git -C $main_repo fetch origin main:main && git -C $main_repo remote prune origin
    end
    or return 1
end
