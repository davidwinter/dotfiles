function git_prompt
  if git root &>/dev/null
    set_color normal
    printf ' on '
    set_color magenta
    printf '%s' (git currentbranch 2>/dev/null)
    set_color normal
  end
end
