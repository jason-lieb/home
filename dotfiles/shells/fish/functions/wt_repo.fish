function wt_repo
    set -l common_dir (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if test -n "$common_dir"
        basename (dirname "$common_dir")
    else
        git worktree list --porcelain 2>/dev/null | grep '^worktree ' | head -1 | string replace --regex '^worktree ' '' | basename
    end
end
