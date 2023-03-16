# wezterm-config

A place to hold some config files for researching a switch

I use dynamic profiles, and itermp to automate the iTerm2 applicaion.  I am
getting close to being able to switch and try out wezterm without giving up
my normal routine, which consists of setting an environment variable at
window/tab launch, and running a command or two at launch, independent of the
shell profile load, and dependent upon some variables passed into the launch of
the window/tab.

## Things that needed solving

- [x] Running an additional command upon shell launch, eg, setting ENV VARS
- [?] Formatting the TAB font size
  - I switched to a font that was naturally larger, which is a start
- [ ] Launching `restore_session.sh`, should be fairly easy with `--cmd` on `wezterm cli spawn --cwd <full path>`
  - this may need to be driven through the `shell-interactive-commands` mechanism, so the launch commands and exports can be done
- [ ] Launching with multiple PANE definitions
  - I use itermp to accomplish this with iTerm2, though I don't use it nearly as much anymore
- [x] Duplicate SmartSelectionRules `<bash:command param1 -switch1>`
  - I use this to make clickables that drop a command between `<bash:` and `>` back onto my command line
  - Personal CLI tools that I write will output this way, to allow quick clicks to drill into next commands
  - Turns out this mechanism works better, no key to hold down, clickable links just work

## Files

### wezterm.lua

The core config has a few interesting bits, most of which I gleaned from issue/
discussion posts on [github](https://github.com/wez/wezterm).

- wezterm.on('user-var-changed'...)

An interesting way to use this mechanism, and seems to work, at least until a
better way comes along.

- local shell_interactive_commands = {...}

The application of the `cmd` key passed into the `user-var-changed` function.

- wezterm.GLOBAL.window_jira

A global variable with which to store and retrieve values that are specific to,
in my case, different windows.

### wezterm-shell-interactions.sh

This file is sourced in, and provides commands to interact with wezterm.

- `neww` will launch a new window, and takes BOARD JIRA_NUM as parameters
- `newt` will luanch a new tab in your existing window.  Takes TITLE as the only parameter
  - this will use the `window` level BOARD/JIRA_NUM setting to setup variable/run commands
- `set-tab-title` will set `shell-interactive-commands` user variable in order to run a command to set the tab title
- `set-jira-issue` will override the jira issue saved with the `window` at launch
- Also included are the functions used to interact with iTerm2

### set-tab-title-to-git.sh

This is my `zsh` `chpwd` hook.  It runs on every directory change, checks to see if we are in a git
directory, and if so, sets the `tab` `title` to the repository name and branch name.  It does this
with a call to set the user variable `shell-interactive-commands`
