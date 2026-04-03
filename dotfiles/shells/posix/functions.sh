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
        export GITHUB_TOKEN=$(security find-generic-password -a "$USER" -s "github-pat" -w)
        echo "GITHUB_TOKEN set"
    }

    ghpat-copy() {
        security find-generic-password -a "$USER" -s "github-pat" -w | pbcopy
        echo "GitHub PAT copied to clipboard"
    }

    ghpat-get() {
        gh auth login -s read:packages
        gh auth token
    }

    ghpat-set() {
        security add-generic-password -a "$USER" -s "github-pat" -w "$1" 2>/dev/null \
            || security add-generic-password -U -a "$USER" -s "github-pat" -w "$1"
        echo "GitHub PAT saved to Keychain"
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

nw() {
    if [ $# -ne 1 ]; then
        echo "Usage: nw <branch-name>"
        return 1
    fi
    local branch="$1"
    local root
    root=$(git rev-parse --show-toplevel)
    if git show-ref --verify --quiet "refs/heads/jl/$branch"; then
        git worktree add "$root/.worktrees/$branch" "jl/$branch"
    else
        git worktree add "$root/.worktrees/$branch" -b "jl/$branch"
    fi
    cd "$root/.worktrees/$branch"
}

sw() {
    if [ $# -ne 1 ]; then
        echo "Usage: sw <branch-name>"
        return 1
    fi
    local branch="$1"
    local root
    root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not in a git repository"; return 1; }
    local worktree="$root/.worktrees/$branch"
    if [ ! -d "$worktree" ]; then
        echo "No worktree found for '$branch'"
        return 1
    fi
    cd "$worktree"
}

dw() {
    if [ $# -ne 1 ]; then
        echo "Usage: dw <branch-name>"
        return 1
    fi
    local branch="$1"
    local root
    root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not in a git repository"; return 1; }
    local worktree="$root/.worktrees/$branch"
    if [ ! -d "$worktree" ]; then
        echo "No worktree found for '$branch'"
        return 1
    fi
    git worktree remove "$worktree"
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
