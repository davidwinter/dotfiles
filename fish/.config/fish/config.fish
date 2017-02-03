function json; python -m json.tool; end
function h; hg $argv; end

function g; git $argv; end
function gpp; git pull --no-edit ; and git push; end

function prepend_to_path -d "Prepend the given dir to PATH if it exists and is not already in it"
    if test -d $argv[1]
        if not contains $argv[1] $PATH
            set -gx PATH "$argv[1]" $PATH
        end
    end
end

prepend_to_path "/Users/davidwinter/bin/gradle/bin"
prepend_to_path "/Users/davidwinter/bin/maven/bin"
prepend_to_path "/Users/davidwinter/.composer/vendor/bin"
prepend_to_path "/Users/davidwinter/Dropbox/bin"
prepend_to_path "/Users/davidwinter/bin"
prepend_to_path "$HOME/.rbenv/bin"
prepend_to_path "$HOME/.rbenv/shims"
prepend_to_path "/usr/local/php5/bin"
prepend_to_path "/usr/local/bin"
prepend_to_path "/usr/local/sbin"

rbenv rehash >/dev/null ^&1
jenv rehah 2>/dev/null

set BROWSER open

set -g -x M2_HOME "/Users/davidwinter/bin/maven"
set -g -x MAVEN_OPTS "-Xms256m -Xmx512m"
set -g -x M2 "$M2_HOME/bin"
set -g -x JAVA_HOME "/Library/Java/JavaVirtualMachines/jdk1.8.0_102.jdk/Contents/Home"
set -g -x GOPATH "$HOME/go"
set -g -x EDITOR vim
set -g -x NODE_PATH '/usr/local/lib/node_modules'
set -g -x fish_greeting ''
set -x NVM_DIR ~/.nvm

source ~/.config/fish/nvm-wrapper/nvm.fish

function git_prompt
  if git root >/dev/null 2>&1
    set_color normal
    printf ' on '
    set_color magenta
    printf '%s' (git currentbranch ^/dev/null)
    set_color normal
  end
end

function hg_prompt
  if hg root >/dev/null 2>&1
    set_color normal
    printf ' on '
    set_color magenta
    printf '%s' (hg branch ^/dev/null)
    set_color normal
  end
end

function fish_prompt
  set_color $fish_color_cwd
    printf '%s' (prompt_pwd)
    set_color normal

  git_prompt
  hg_prompt

  echo ' >: '
end

function dm; docker-machine $argv[1] default; end
function dme; eval (docker-machine env default); end
function dcr; docker-compose run --rm --service-ports $argv; end
function dc; docker-compose $argv; end

function dcu
  docker-compose run --rm web rm /app/tmp/pids/server.pid
  docker-compose run --rm flourish rm /app/tmp/pids/server.pid
  docker-compose run --rm platform rm /app/tmp/pids/server.pid
  docker-compose up
end

function dcb; docker-compose build; end

function mole; sshuttle -l 0.0.0.0 --dns -r mole 0/0; end
