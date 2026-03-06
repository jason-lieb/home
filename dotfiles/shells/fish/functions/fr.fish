function fr
    if test (git rev-parse --abbrev-ref HEAD) != "main"
        git checkout main
    end
    git fetch origin main && git rebase origin/main
end
