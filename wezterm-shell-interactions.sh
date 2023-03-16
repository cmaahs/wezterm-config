#!/usr/bin/env zsh

function to-lower () {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# shell functions
# neww will launch a new top level window, setting the JIRA 'BOARD-NUM' as the window title
# it will also set JIRA_ISSUE, and run 'switch-jira BOARD'
function neww() {
  BOARD=${1}
  JIRA_NUM=${2}
  WINDOW_TITLE="${1}-${2}"
  # TODO: implement a extra_cmd json key with extra commands to run ';' separated
  RUN_DMC=${3}
  RUN_DMC="${RUN_DMC}; cd ~\/Work/${BOARD}-${JIRA_NUM}; export JIRA_ISSUE=${BOARD}-${JIRA_NUM}"
  touch ~/.itermp/select/${WINDOW_TITLE}
  mkdir -p ~/Work/${WINDOW_TITLE}/log
  board=$(to-lower ${BOARD})
  jcwd="${HOME}/Work/${WINDOW_TITLE}"
  jcmd=$(jq -c -n --arg title "${WINDOW_TITLE}" --arg board "${board}" --arg cwd ${jcwd} '{"cmd":"open-window","title":$title,"jira":$title,"cwd":$cwd,"board":$board}' | base64)
  printf "\033]1337;SetUserVar=%s=%s\007" shell-interactive-commands ${jcmd}
}

# newt will launch a new TAB in your current window, setting JIRA_ISSUE based on the
# top level window, and also running 'switch-jira BOARD' based on the top level window
function newt() {
  if [[ "${TERM_PROGRAM}" == "WezTerm" ]]; then
    title=${1}
    jcmd=$(jq -c -n --arg title "${title}" '{"cmd":"open-tab","title":$title}' | base64)
    printf "\033]1337;SetUserVar=%s=%s\007" shell-interactive-commands ${jcmd}
  fi
}

# set-tab-title will override he TAB title
function set-tab-title() {
  title=${1}
  if [[ "${TERM_PROGRAM}" == "WezTerm" ]]; then
    jcmd=$(jq -c -n --arg title "${title}" '{"cmd":"set-tab-title","title":$title}' | base64)
    printf "\033]1337;SetUserVar=%s=%s\007" shell-interactive-commands ${jcmd}
  else
    set-title-tab ${title}
  fi
}

# set-jira-issue will override the TOP level JIRA_ISSUE / window title
function set-jira-issue() {
  jira=${1}
  jcmd=$(jq -c -n --arg jira "${jira}" '{"cmd":"set-jira-issue","jira":$jira}' | base64)
  printf "\033]1337;SetUserVar=%s=%s\007" shell-interactive-commands ${jcmd}
}

# these are the original methods for setting Window/Tab titles in iTerm2
# $1 = type; 0 - both, 1 - tab, 2 - title
# rest = text
function set-terminal-title () {
    # echo works in bash & zsh
    local mode=$1 ; shift
    echo -ne "\033]$mode;$@\007"
}
function set-title-both() {
  set-terminal-title 0 $@
}
function set-title-tab () {
  ITERM_TAB=$@
  set-terminal-title 1 $@
}
function set-title-window () {
  set-terminal-title 2 $@
}
function set-tab-title-pwd () {
  TITLE=${1:-$(basename ${PWD})}
  ITERM_TAB=${TITLE}
  set-terminal-title 1 ${TITLE}
}

