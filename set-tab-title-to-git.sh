autoload -U add-zsh-hook

set_tab_title_on_git() {
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    local ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    local gitpath=$(git rev-parse --git-dir)
    if [[ "${gitpath}" == ".git" ]]; then
      local repo=$(basename $(pwd))
      export BRANCH="${ref/refs\/heads\//}"
    else
      local repo=$(basename $(echo ${gitpath} | sed 's/\/\.git.*$//'))
    fi
    if [[ "${TERM_PROGRAM}" == "WezTerm" ]]; then
      repobranch="${repo}/${ref/refs\/heads\//}"
      title=$(printf '{"cmd":"set-tab-title","title":"%s"}' "${repobranch}" | base64)
      printf "\033]1337;SetUserVar=%s=%s\007" shell-interactive-commands ${title}
    else
      set-title-tab "${repo}/${ref/refs\/heads\//}"
    fi
    # configure any local githooks
    if [[ -d ./githooks ]]; then
      local HOOK_PATH=$(git config --local --get core.hooksPath)
      if [[ -z ${HOOK_PATH} ]]; then
        git config --local core.hooksPath ".githooks/"
      fi
    fi
  fi
}

add-zsh-hook chpwd set_tab_title_on_git

