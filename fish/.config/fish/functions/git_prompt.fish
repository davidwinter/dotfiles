function git_prompt
  if git root >/dev/null 2>&1
    set_color normal
    printf ' on '
    set_color magenta
    printf '%s' (git currentbranch ^/dev/null)
    set_color normal
  end
end
