function hg_prompt
  if hg root >/dev/null 2>&1
    set_color normal
    printf ' on '
    set_color magenta
    printf '%s' (hg branch ^/dev/null)
    set_color normal
  end
end
