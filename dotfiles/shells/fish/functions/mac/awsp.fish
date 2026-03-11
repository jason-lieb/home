function awsp
    # Run the interactive picker if no profile was supplied
    if test (count $argv) -eq 0
        go-awsp
    end

    # Pick the profile (either from argument or from the file the picker wrote)
    set -q argv[1]
    and set -x selected_profile $argv[1]
    or  set -l selected_profile (cat $HOME/.awsp)

    # Unset AWS_PROFILE rather than setting it to "default"
    if test -z "$selected_profile"; or test "$selected_profile" = "default"
        set -e AWS_PROFILE
    else
        set -gx AWS_PROFILE $selected_profile
    end
end
