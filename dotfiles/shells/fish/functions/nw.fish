function nw
    if test (count $argv) -ne 1
        echo "Usage: nw <branch-name>"
        return 1
    end
    set branch $argv[1]
    set root (git rev-parse --show-toplevel)
    if git show-ref --verify --quiet "refs/heads/jl/$branch"
        git worktree add "$root/.worktrees/$branch" "jl/$branch"
    else
        git worktree add "$root/.worktrees/$branch" -b "jl/$branch"
    end
    cd "$root/.worktrees/$branch"
end
