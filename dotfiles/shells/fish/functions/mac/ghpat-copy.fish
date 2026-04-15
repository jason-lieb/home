function ghpat-copy
    gh auth token | pbcopy
    echo "GitHub PAT copied to clipboard"
end
