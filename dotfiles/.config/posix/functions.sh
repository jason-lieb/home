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
