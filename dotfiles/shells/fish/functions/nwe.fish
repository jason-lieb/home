function nwe
    if test (count $argv) -ne 1
        echo "Usage: nwe <branch-name>"
        return 1
    end
    set full_branch $argv[1]
    set dir (string replace --regex '^jl/' '' $full_branch)
    set root (git worktree list --porcelain | head -1 | string replace --regex '^worktree ' '')
    if git show-ref --verify --quiet "refs/heads/$full_branch"
        git worktree add "$root/.worktrees/$dir" "$full_branch"
    else
        git worktree add "$root/.worktrees/$dir" -b "$full_branch" main
    end
    and cd "$root/.worktrees/$dir"
end
