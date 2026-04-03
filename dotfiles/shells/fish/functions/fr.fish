function fr
    set main_repo (git rev-parse --git-common-dir | string replace -r '/\.git$' '')
    set current_branch (git -C $main_repo rev-parse --abbrev-ref HEAD)

    if test $current_branch = "main"
        git -C $main_repo pull --ff-only origin main && git -C $main_repo remote prune origin
    else
        git -C $main_repo fetch origin main:main && git -C $main_repo remote prune origin
    end
    or return 1
end
