function dw
    if test (count $argv) -ne 1
        echo "Usage: dw <branch-name>"
        return 1
    end
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "Not in a git repository"
        return 1
    end
    set -l worktree (wt_find $argv[1])
    if test -z "$worktree"
        echo "No worktree found for '$argv[1]'"
        return 1
    end
    git worktree remove $worktree
    and rmdir (dirname $worktree) 2>/dev/null
end
