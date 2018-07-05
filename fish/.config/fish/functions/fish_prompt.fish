function fish_prompt
  set_color $fish_color_cwd
    printf '%s' (prompt_pwd)
    set_color normal

  git_prompt
  hg_prompt

  echo ' >: '
end
