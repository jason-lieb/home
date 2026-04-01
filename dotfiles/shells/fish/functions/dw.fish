function dw
    if test (count $argv) -ne 1
        echo "Usage: dw <branch-name>"
        return 1
    end
    set branch $argv[1]
    set root (git rev-parse --show-toplevel 2>/dev/null)
    if test $status -ne 0
        echo "Not in a git repository"
        return 1
    end
    set worktree "$root/.worktrees/$branch"
    if not test -d $worktree
        echo "No worktree found for '$branch'"
        return 1
    end
    git worktree remove $worktree
end
