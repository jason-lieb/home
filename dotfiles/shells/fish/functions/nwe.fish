function nwe
    if test (count $argv) -ne 1
        echo "Usage: nwe <branch-name>"
        return 1
    end
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "Not in a git repository"
        return 1
    end
    set -l full_branch $argv[1]
    set -l dir (string replace --regex '^jl/' '' $full_branch)
    set -l existing (wt_find $full_branch)
    if test -n "$existing"
        cd "$existing"
        return 0
    end
    set -l worktree_path (wt_root)/(wt_repo)/$dir
    mkdir -p (dirname $worktree_path)
    if git show-ref --verify --quiet "refs/heads/$full_branch"
        git worktree add "$worktree_path" "$full_branch"
    else
        git worktree add "$worktree_path" -b "$full_branch" main
    end
    and cd "$worktree_path"
end
