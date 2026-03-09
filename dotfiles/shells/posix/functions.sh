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

ghpat() {
    export GITHUB_TOKEN=$(security find-generic-password -a "$USER" -s "github-pat" -w)
    echo "GITHUB_TOKEN set"
}

ghpat-copy() {
    security find-generic-password -a "$USER" -s "github-pat" -w | pbcopy
    echo "GitHub PAT copied to clipboard"
}

ghpat-set() {
    security add-generic-password -a "$USER" -s "github-pat" -w "$1" 2>/dev/null \
        || security add-generic-password -U -a "$USER" -s "github-pat" -w "$1"
    echo "GitHub PAT saved to Keychain"
}

grf() {
    if [ $# -eq 1 ]; then
        git branch -D "$1"
        git fetch origin "$1"
        git checkout "$1"
    else
        echo "Invalid number of arguments"
    fi
}

fr() {
    if [ "$(git rev-parse --abbrev-ref HEAD)" != "main" ]; then
        git checkout main
    fi
    git fetch origin main && git rebase origin/main
}
