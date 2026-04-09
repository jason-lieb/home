function dw
    if test (count $argv) -ne 1
        echo "Usage: dw <branch-name>"
        return 1
    end
    set dir (string replace --regex '^jl/' '' $argv[1])
    set root (git worktree list --porcelain 2>/dev/null | head -1 | string replace --regex '^worktree ' '')
    if test $status -ne 0
        echo "Not in a git repository"
        return 1
    end
    set worktree "$root/.worktrees/$dir"
    if not test -d $worktree
        echo "No worktree found for '$dir'"
        return 1
    end
    git worktree remove $worktree
end
