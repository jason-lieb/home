function ghpat-copy
    security find-generic-password -a $USER -s "github-pat" -w | pbcopy
    echo "GitHub PAT copied to clipboard"
end
