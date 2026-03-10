function ghpat
    set -gx GITHUB_TOKEN (security find-generic-password -a $USER -s "github-pat" -w)
    echo "GITHUB_TOKEN set"
end
