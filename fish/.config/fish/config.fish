alias g=git

# orbstack
if test (uname) = Darwin
    source ~/.orbstack/shell/init.fish 2>/dev/null; or true
end

set -gx fish_greeting ''

if test -S ~/.1password/agent.sock
    set -gx SSH_AUTH_SOCK ~/.1password/agent.sock
end

starship init fish | source
