git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

docker_status() {
    if command -v docker &>/dev/null && docker ps -q 2>/dev/null | grep -q .; then
        echo " (docker)"
    fi
}

aws_profile() {
    if [ -n "${AWS_PROFILE:-}" ]; then
        echo " (aws:$AWS_PROFILE)"
    fi
}

if [[ "$(uname)" == "Darwin" ]]; then
    ghpat() {
        export GITHUB_TOKEN=$(gh auth token)
        echo "GITHUB_TOKEN set"
    }

    ghpat-copy() {
        gh auth token | pbcopy
        echo "GitHub PAT copied to clipboard"
    }
fi

grf() {
    if [ $# -eq 1 ]; then
        git branch -D "$1"
        git fetch origin "$1"
        git checkout "$1"
    else
        echo "Invalid number of arguments"
    fi
}

main() {
    local main_worktree
    main_worktree=$(git worktree list --porcelain 2>/dev/null | grep "^worktree " | head -1 | awk '{print $2}')
    if [ -z "$main_worktree" ]; then
        echo "Not in a git repository"
        return 1
    fi
    if [ "$PWD" != "$main_worktree" ]; then
        cd "$main_worktree"
    else
        git checkout main
    fi
}

worktree_root() {
    if [ -n "${WORKTREE_ROOT:-}" ]; then
        echo "$WORKTREE_ROOT"
    else
        echo "$HOME/code/.worktrees"
    fi
}

worktree_repo() {
    local common_dir
    common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    if [ -n "$common_dir" ]; then
        basename "$(dirname "$common_dir")"
    else
        git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p' | head -1 | xargs basename
    fi
}

worktree_find() {
    local dir="${1#jl/}"
    git worktree list --porcelain 2>/dev/null | awk -v d="$dir" '
        /^worktree / { wt = substr($0, 10) }
        /^branch /   { br = substr($0, 8); sub(/^refs\/heads\//, "", br); sub(/^jl\//, "", br) }
        NF == 0      { if (br == d && wt) print wt; wt = ""; br = "" }
        END          { if (br == d && wt) print wt }
    '
}

nw() {
    if [ $# -ne 1 ]; then
        echo "Usage: nw <branch-name>"
        return 1
    fi
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Not in a git repository"
        return 1
    fi
    local full_branch="$1"
    local dir="${full_branch#jl/}"
    local existing worktree_path
    existing=$(worktree_find "$full_branch")
    if [ -n "$existing" ]; then
        echo "Worktree already exists: $existing"
        return 0
    fi
    worktree_path="$(worktree_root)/$(worktree_repo)/$dir"
    mkdir -p "$(dirname "$worktree_path")"
    if git show-ref --verify --quiet "refs/heads/$full_branch"; then
        git worktree add "$worktree_path" "$full_branch"
    else
        git worktree add "$worktree_path" -b "$full_branch" main
    fi
}

nwe() {
    if [ $# -ne 1 ]; then
        echo "Usage: nwe <branch-name>"
        return 1
    fi
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Not in a git repository"
        return 1
    fi
    local full_branch="$1"
    local dir="${full_branch#jl/}"
    local existing worktree_path
    existing=$(worktree_find "$full_branch")
    if [ -n "$existing" ]; then
        cd "$existing"
        return 0
    fi
    worktree_path="$(worktree_root)/$(worktree_repo)/$dir"
    mkdir -p "$(dirname "$worktree_path")"
    if git show-ref --verify --quiet "refs/heads/$full_branch"; then
        git worktree add "$worktree_path" "$full_branch"
    else
        git worktree add "$worktree_path" -b "$full_branch" main
    fi && cd "$worktree_path"
}

sw() {
    if [ $# -ne 1 ]; then
        echo "Usage: sw <branch-name>"
        return 1
    fi
    local worktree
    worktree=$(worktree_find "$1")
    if [ -z "$worktree" ]; then
        echo "No worktree found for '$1'"
        return 1
    fi
    cd "$worktree"
}

dw() {
    if [ $# -ne 1 ]; then
        echo "Usage: dw <branch-name>"
        return 1
    fi
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Not in a git repository"
        return 1
    fi
    local worktree
    worktree=$(worktree_find "$1")
    if [ -z "$worktree" ]; then
        echo "No worktree found for '$1'"
        return 1
    fi
    git worktree remove "$worktree"
    rmdir "$(dirname "$worktree")" 2>/dev/null || true
}

ghd() {
    if [ $# -ne 1 ]; then
        echo "Usage: ghd <branch-name>"
        return 1
    fi
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Not in a git repository"
        return 1
    fi
    local worktree
    worktree=$(worktree_find "$1")
    if [ -z "$worktree" ]; then
        echo "No worktree found for '$1'"
        return 1
    fi
    open -a "GitHub Desktop" "$worktree"
}

fr() {
    local main_repo current_branch
    main_repo=$(git worktree list --porcelain | grep '^worktree ' | head -1 | sed 's/^worktree //')
    current_branch=$(git -C "$main_repo" rev-parse --abbrev-ref HEAD)

    if [ "$current_branch" = "main" ]; then
        git -C "$main_repo" fetch origin && git -C "$main_repo" rebase origin/main && git -C "$main_repo" remote prune origin
    else
        git -C "$main_repo" fetch origin main:main && git -C "$main_repo" remote prune origin
    fi || return 1
}
