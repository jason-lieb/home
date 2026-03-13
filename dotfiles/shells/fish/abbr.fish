# Navigation
abbr c clear
abbr la 'ls -A'
abbr ll 'ls -l'
abbr lr 'ls -R'
abbr cat bat
abbr .. 'cd ..'
abbr ... 'cd ../..'
abbr .... 'cd ../../..'
abbr ..... 'cd ../../../..'
abbr ...... 'cd ../../../../..'
abbr f fish
abbr home 'cd ~/code/home'

# Git
abbr g git
abbr ga 'git add'
abbr gaa 'git add -A'
abbr gap 'git add -p'
abbr gf 'git commit --fixup'
abbr gaf 'git add -A; git commit --fixup'
abbr gfh 'git commit --fixup HEAD'
abbr gafh 'git add -A; git commit --fixup HEAD'
abbr gc 'git commit -m'
abbr gac 'git add -A; git commit -m'
abbr gd 'git checkout -- .'
abbr gdiff 'git diff'
abbr gdiffs 'git diff --staged'
abbr gr 'git reset HEAD^'
abbr gl 'git log --oneline --ancestry-path origin/main^..HEAD'
abbr gcp 'git cherry-pick'
abbr main 'git checkout main'
abbr pull 'git pull --rebase origin'
abbr push 'git push origin'
abbr fpush 'git push origin --force-with-lease'
abbr fetch 'git fetch origin'
abbr gs 'git stash push -u'
abbr gsm 'git stash push -u -m'
abbr gsd 'git stash drop'
abbr gsl 'git stash list'
abbr gsp 'git stash pop'
abbr b 'git branch'
abbr db 'git branch -D'
abbr nb 'git checkout -b'
abbr sb 'git checkout'
abbr fe 'git fetch origin main'
abbr re 'git rebase main'
abbr rei 'git rebase -i main'
abbr abort 'git rebase --abort'
abbr pr 'gh pr create -t'
abbr prd 'gh pr create --draft -t'

# Vault
abbr vault-login 'vault login -method=github -path=github/cincpro token=$GITHUB_TOKEN'

# Development
abbr p pnpm
abbr docker-clean 'docker system prune -a'
