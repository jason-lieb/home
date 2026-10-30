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

wt() {
    case "${1:-}" in
        new|go)
            local worktree
            worktree=$(command wt "$@") && cd "$worktree"
            ;;
        *)
            command wt "$@"
            ;;
    esac
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
