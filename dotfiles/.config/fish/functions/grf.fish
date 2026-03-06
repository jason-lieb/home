function grf
    if test (count $argv) -eq 1
        git branch -D "$argv"
        git fetch origin "$argv"
        git checkout "$argv"
    else
        echo "Invalid number of arguments"
    end
end
