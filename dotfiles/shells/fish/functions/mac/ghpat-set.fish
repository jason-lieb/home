function ghpat-set
    security add-generic-password -a $USER -s "github-pat" -w $argv[1] 2>/dev/null \
        || security add-generic-password -U -a $USER -s "github-pat" -w $argv[1]
    echo "GitHub PAT saved to Keychain"
end
