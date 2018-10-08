function add_to_path
  if test -d $argv
    set -gx PATH $argv $PATH
  end
end
