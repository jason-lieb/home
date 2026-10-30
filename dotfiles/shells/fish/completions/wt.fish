function __wt_worktree_branches
    git worktree list --porcelain 2>/dev/null \
        | string match -rg '^branch refs/heads/(.*)$' \
        | string match -v main \
        | string replace -r '^jl/' ''
end

function __wt_local_branches
    git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null \
        | string match -v main \
        | string replace -r '^jl/' ''
end

complete -c wt -f
complete -c wt -n __fish_use_subcommand -a list -d 'List worktrees'
complete -c wt -n __fish_use_subcommand -a new -d 'Create or reuse a worktree'
complete -c wt -n __fish_use_subcommand -a go -d 'cd into a worktree'
complete -c wt -n __fish_use_subcommand -a rm -d 'Remove a worktree'
complete -c wt -n __fish_use_subcommand -a open -d 'Open a worktree in GitHub Desktop'
complete -c wt -n '__fish_seen_subcommand_from go rm open; and test (count (commandline -opc)) -eq 2' -a '(__wt_worktree_branches)'
complete -c wt -n '__fish_seen_subcommand_from new; and test (count (commandline -opc)) -eq 2' -a '(__wt_local_branches)'
