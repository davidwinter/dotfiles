alias g=git

# orbstack
if test (uname) = Darwin
    source ~/.orbstack/shell/init.fish 2>/dev/null; or true
end

set -gx fish_greeting ''

starship init fish | source
