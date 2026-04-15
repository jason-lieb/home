function ghpat
    set -gx GITHUB_TOKEN (gh auth token)
    echo "GITHUB_TOKEN set"
end
