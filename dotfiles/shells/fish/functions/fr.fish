function fr
    set main_repo (git rev-parse --git-common-dir | string replace -r '/\.git$' '')
    git -C $main_repo fetch origin main:main && git -C $main_repo remote prune origin
    or return 1

    if test (git -C $main_repo rev-parse --abbrev-ref HEAD) = "main"
        git -C $main_repo merge --ff-only origin/main
    end
end
