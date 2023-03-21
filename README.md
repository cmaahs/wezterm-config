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
- [x] Launching `restore_session.sh`, should be fairly easy with `--cmd` on `wezterm cli spawn --cwd <full path>`
  - this may need to be driven through the `shell-interactive-commands` mechanism, so the launch commands and exports can be done
  - Using the `open-tab` command, I am able to pass in the details for restoring an existing session
  - The WINDOW_TITLE (JIRA_ISSUE) are set by the `neww` and `newj` which would launch a new window, place you in the workdir where the `restore-session*.sh` files live
- [ ] Launching with multiple PANE definitions
  - I use itermp to accomplish this with iTerm2, though I don't use it nearly as much anymore
- [x] Duplicate SmartSelectionRules `<bash:command param1 -switch1>`
  - I use this to make clickables that drop a command between `<bash:` and `>` back onto my command line
  - Personal CLI tools that I write will output this way, to allow quick clicks to drill into next commands
  - Turns out this mechanism works better, no key to hold down, clickable links just work
- [x] Adjust my `save-session`, aliases `ss` and `gj` to handle saving to `~/Work/${ITERM_PROFILE}/restore-session-${TODAY}`
  - Need an ITERM_PROFILE replacement
  - Need some ability to determine the current TAB order when closed
  - I created two new `shell-interactive-commands`: `save-sessions` and `save-session` that save to shell files
- [ ] iTerm2 has the ability to LOG sessions, as I'm sure does WexTerm.
  - Currently when enabled logging to `~/Work/${ITERM_PROFILE}/log/${SESSION_ID}.log`
- [x] Convert iTerm2 Color-Scheme to wezterm
  - Created `Maahsome.toml` scheme file
- [x] iTerm2 has a password manager, not super important, though I had it so that it automatically pops up the password manager when the shell is prompting to unlock and RSA key file.  It was nice though.
  - Using a custom key binding, and EmitEvent to use `security` and `send_text` to lookup a keyring item and express it to the terminal.  This will work for now, since I use this mostly to not have to type the LONG passphrase on my private key files.
- [ ] Can I make it so that COMMAND-T (new tab) will perform the exact same operation as `newt` bash function?
  - a little too much muscle memory, and `newt` just adds a tab title, which we can just default to `new` or perhaps make it the same as the window title
- [ ] Update my `abandon-file` function, which leverages ${ITERM_PROFILE} to make some path assumptions

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
- `save-wez-session` will output a shell script file in `workdir/tabs/restore-tab-DATE-TIME.sh` file, optionally close tab
- `save-wez-sessions` will output a shell script file in `workdir/restore-session-DATE.sh` file, optionally closing tabs
  - this file will be overwritten (one file per day)
- `restt` will open a new tab, passing in just a tab title, and cwd.  This is used by the `save*` routines
- Also included are the functions used to interact with iTerm2
- Aliases:
  - sss = save-wez-sessions false   # save all the sessions without closing 
  - mm  = save-wez-sessions true    # save all the sessions and close all tabs
  - ss  - save-wez-session false    # save tab session and leave open
  - gj  - save-wez-session true     # save tab session and close 

### set-tab-title-to-git.sh

This is my `zsh` `chpwd` hook.  It runs on every directory change, checks to see if we are in a git
directory, and if so, sets the `tab` `title` to the repository name and branch name.  It does this
with a call to set the user variable `shell-interactive-commands`

