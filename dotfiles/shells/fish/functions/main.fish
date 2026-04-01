function main
    set main_worktree (git worktree list --porcelain 2>/dev/null | grep "^worktree " | head -1 | awk '{print $2}')
    if test -z "$main_worktree"
        echo "Not in a git repository"
        return 1
    end
    if test $PWD != $main_worktree
        cd $main_worktree
    else
        git checkout main
    end
end
