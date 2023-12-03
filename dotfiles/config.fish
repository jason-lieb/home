if status is-interactive
    # Commands to run in interactive sessions can go here
end

###

# Aliases
alias bran "git branch | tr '\\n' '\\n'"
alias c "clear"
alias dbran "git branch -D"
alias g "git"
alias gac "git add -A; git commit -m"
alias ll "ls -l"
alias la "ls -A"
alias main "git checkout main"
alias pull "git pull origin main"
alias push "git push origin"
alias run-qa "git commit --allow-empty -m '[qa]'"