function wt
    switch "$argv[1]"
        case new go
            set -l worktree (command wt $argv)
            and cd $worktree
        case '*'
            command wt $argv
    end
end
