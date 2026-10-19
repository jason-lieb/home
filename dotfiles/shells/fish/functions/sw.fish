function sw
    if test (count $argv) -ne 1
        echo "Usage: sw <branch-name>"
        return 1
    end
    set -l worktree (wt_find $argv[1])
    if test -z "$worktree"
        echo "No worktree found for '$argv[1]'"
        return 1
    end
    cd $worktree
end
