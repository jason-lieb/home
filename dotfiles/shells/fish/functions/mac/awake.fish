function awake
    switch "$argv[1]"
        case on
            sudo pmset -a disablesleep 1
            and echo "Sleep disabled"
        case off
            sudo pmset -a disablesleep 0
            and echo "Sleep enabled"
        case ''
            if pmset -g | string match -qr 'SleepDisabled\s+1'
                echo "Sleep disabled"
            else
                echo "Sleep enabled"
            end
        case '*'
            echo "Usage: awake [on|off]"
            return 1
    end
end
