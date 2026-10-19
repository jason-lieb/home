function wt_find
    set -l dir (string replace --regex '^jl/' '' $argv[1])
    git worktree list --porcelain 2>/dev/null | awk -v d="$dir" '
        /^worktree / { wt = substr($0, 10) }
        /^branch /   { br = substr($0, 8); sub(/^refs\/heads\//, "", br); sub(/^jl\//, "", br) }
        NF == 0      { if (br == d && wt) print wt; wt = ""; br = "" }
        END          { if (br == d && wt) print wt }
    '
end
