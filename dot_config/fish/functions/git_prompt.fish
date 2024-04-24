function git_prompt
  if git rev-parse --show-toplevel &>/dev/null
    set_color normal
    printf ' on '
    set_color magenta
    printf '%s' (git branch --show-current 2>/dev/null)
    set_color normal
  end
end
