function add_to_path
  if test -d $1
    set -gx PATH $1 $PATH
  end
end
