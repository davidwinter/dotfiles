function zellij
    if test (count $argv) -eq 0
        command zellij -l welcome
    else
        command zellij $argv
    end
end
