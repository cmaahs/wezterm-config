local wezterm = require 'wezterm'
local act = wezterm.action

-- this is our way of storing values for specific 'windows' in this case
-- we could certainly store things specifically for other objects, or even
-- store complex table objects for each 'window'
wezterm.GLOBAL.window_jira = wezterm.GLOBAL.window_jira or {}

-- split is just a basic splitter, creating a table (array) out of the splits
local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end
-- extract_command pulls the actual command from between '<bash:' and '>'
local function extract_command(uri)
  local _, _, command = string.find(uri, "<bash:(.*)>")
  return command;
end

-- shell_interactive_commands is a table (array) of functions that are run
-- on fired events for 'user-var-changed' (see below)
local shell_interactive_commands = {
  -- set-jira-issue will set the value in the GLOBAL we are using to store values
  -- per 'window'
  ['set-jira-issue'] = function(window, pane, cmd_context)
    -- wezterm has LOTS of 'windows', grr...
    -- pane:window():window_id() is the window we are launching from
    -- window:window_id() is the window for which the user-var-changed callback was run from
    -- user-var-changed is triggered for EACH top level window you have open, since they are
    -- effectively GLOBAL
    local pwin_id = tostring(pane:window():window_id())
    local win_id = tostring(window:window_id())
    if pwin_id == win_id then
      -- we make a copy of the global table, update an array entry, then copy it back
      local current_jira = wezterm.GLOBAL.window_jira
      current_jira[win_id] = cmd_context.jira
      wezterm.GLOBAL.window_jira = current_jira
    end
  end,

  -- set-tab-title will set the 'title' property for a TAB object
  -- IF you use the OSC 1/2 to set the TAB title, that will be stored and consumed
  -- ahead of this value... Some shells make this call automatically to set the title of the window
  -- or tab to the running process name... this from the docs:
  --   Note that wezterm will attempt to determine the foreground process and substitute its title if
  --   the pane is a local pane and no title has been set by an OSC escape sequence.
  --
  -- OSC 1 sets the "icon" title for a pane.
  -- OSC 2 sets the title title for a pane.
  -- When wezterm determines the title for a pane to display it, or return it via lua properties:

  -- * The icon title (OSC 1), if set, takes precedence
  -- * Then the OSC 2 title
  -- * If the pane is a local pane, and the title is "wezterm" (the default title of the terminal state),
  --   then the foreground process name, if we can resolve it, is used in place of "wezterm"
  --
  -- expects .title
  ['set-tab-title'] = function(window, pane, cmd_context)
    pane:mux_pane():tab():set_title(cmd_context.title)
  end,

  -- open-tab will open a new TAB in your current 'window'
  -- expects .title
  -- the JIRA_ISSUE is determined based on the top level window
  ['open-tab'] = function(window, pane, cmd_context)
    local pwin_id = tostring(pane:window():window_id())
    local win_id = tostring(window:window_id())
    if pwin_id == win_id then

      local new_tab, _, _ = window:mux_window():spawn_tab {
        cwd = cmd_context.cwd
      }

      new_tab:set_title(cmd_context.title)
      local jira_issue = wezterm.GLOBAL.window_jira[win_id] or ""
      for pane_index, pane in ipairs(new_tab:panes_with_info()) do
        if pane.is_active then
          pane.pane:send_text('export JIRA_ISSUE=' .. jira_issue .. '\n')
          local lc = split(string.lower(jira_issue),'-')
          pane.pane:send_text('switch-jira ' .. lc[1] .. '\n')
        end
      end
    end
    return
  end,

  -- open-window will open a new TOP level window and set the 'window' title
  -- expects .title and .jira as properties on cmd_context
  ['open-window'] = function(window, pane, cmd_context)
    local pwin_id = tostring(pane:window():window_id())
    local win_id = tostring(window:window_id())
    if pwin_id == win_id then
      local newtab, _, _ = wezterm.mux.spawn_window { cwd = cmd_context.cwd }
      -- we need the NEW window id of the window that was just created
      local win_id = tostring(newtab:window():window_id())
      -- set our GLOBAL to store our passed in JIRA ID
      local current_jira = wezterm.GLOBAL.window_jira
      current_jira[win_id] = cmd_context.jira
      wezterm.GLOBAL.window_jira = current_jira
      local tab = wezterm.mux.get_tab(newtab:tab_id())
      tab:set_title(cmd_context.title)
      for pane_index, pane in ipairs(tab:panes_with_info()) do
        if pane.is_active then
          -- send some commands to the new pane, to set some defaults based on
          -- what we are working on, this works surprisingly well
          pane.pane:send_text('export JIRA_ISSUE=' .. cmd_context.jira .. '\n')
          pane.pane:send_text('switch-jira ' .. cmd_context.board .. '\n')
        end
      end
    end
    return
  end,
}

-- the CONFIGURATION
return {
  font = wezterm.font_with_fallback {
      { family = "Roboto Mono Light for Powerline", weight="Light", stretch="Normal", style="Normal" },
      -- one of these two supplies U+F8FF as the APPLE LOGO
      { family = "AppleGothic", weight="Regular", stretch="Normal", style="Normal" },
      { family = "Apple Color Emoji", weight="Regular", stretch="Normal", style="Normal" },
  },
  font_size = 22.0,
  color_scheme = "Maahsome",
  use_fancy_tab_bar = true,  -- this is actually default
  tab_max_width = 100,  -- this will truncate the length of the titles in the tabs
  window_frame = {
    -- font = wezterm.font { family = 'Roboto Mono Light for Powerline', weight = 'Light' },
    -- this font is a bit bigger, the TAB bar is quite small
    font = wezterm.font { family = 'Noto Sans', weight = 'Regular' },
    font_size = 16.0,
  },
  keys = {
    { key = 'j', mods = 'ALT|CMD', action = act.ActivateWindowRelative(-1) },
    { key = 'k', mods = 'ALT|CMD', action = act.ActivateWindowRelative(1) },
    { key = 'h', mods = 'ALT|CMD', action = act.ActivateTabRelative(-1) },
    { key = 'l', mods = 'ALT|CMD', action = act.ActivateTabRelative(1) },
    { key = ';', mods = 'ALT|CMD', action = wezterm.action.ShowTabNavigator },
  },
  hyperlink_rules = {
    -- These are the default rules, but you currently need to repeat
    -- them here when you define your own rules, as your rules override
    -- the defaults

    -- URL with a protocol
    {
      regex = "\\b\\w+://(?:[\\w.-]+)\\.[a-z]{2,15}\\S*\\b",
      format = "$0",
    },

    -- implicit mailto link
    -- {
    --     regex = "\\b\\w+@[\\w-]+(\\.[\\w-]+)+\\b",
    --     format = "mailto:$0",
    -- },

    -- custom rules below
    -- this rule matchs our custom '<bash:command>' output
    -- format is the underlying URI that gets passed into the 'on:open-uri' trigger
    -- it would be very fun if the entire thing could be replaced with a explicitHyperlink!
    -- what a screen space saver that would be.  Potentially could change the output to be
    -- GLGJp(projectID)l(logID) and format = "<bash:gitlab-tool get job -p $1 -l $2"
    -- the output would just be 'GLGJp2456l1235674' which would be underlined as a clickable
    -- would be easy to match on that for sure, though it would mean ALL custom regex matches...
    -- worth it?
    {
      regex = "<bash:(.*)>",
      format = "$0"
    },
    -- Cannot have your cake and eat it too... one or the other on this one
    -- there doesn't seem to be a way to make a certain portion of the match
    -- be the LINK, it uses the entire $0 match as the UNDERLINING for the
    -- link to be active.  Since we need the first column field for both of
    -- these to use in the URI format, it is a no-go
    {
      -- regex = "([A-Za-z0-9]+(-[A-Za-z0-9]+)+)\\s+.*Running",
      regex = "([A-Za-z0-9]+(-[A-Za-z0-9]+)+)\\s+[0-9]+/[0-9]+\\s+",
      format = "<bash:$1>"
    },
    {
      regex = "/dev/(.*)\\b",
      format = "<bash:$1>"
    },
    {
      regex = "gs://(.*)/",
      format = "<bash:$0>"
    },
    {
      regex = "\\b(TSAASPD-[0-9]+)\\b",
      format = "https://alteryx.atlassian.net/browse/$0"
    },
    -- {
    --   regex = "([A-Za-z0-9]+(-[A-Za-z0-9]+)+)\\s+.*Running",
    --   format = "<bash:k exec -it $1 -n ${NAMESPACE} -- /bin/bash>"
    -- },
  },

  -- format-window-title is a triggered event that renders the 'window' title
  wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
    local zoomed = ''
    if tab.active_pane.is_zoomed then
      zoomed = '[Z] '
    end

    local index = ''
    if #tabs > 1 then
      index = string.format('[%d/%d] ', tab.tab_index + 1, #tabs)
    end

    local window_id = tostring(tab.window_id)
    -- use the window_id to fetch our JIRA setting from our GLOBAL table
    local jira_issue = wezterm.GLOBAL.window_jira[window_id] or ""

    return zoomed .. index .. jira_issue .. "( " .. tab.tab_title .. " )"
  end),

  -- format-tab-title is a triggered event that renders the 'tab' title
  wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
    local foreground = '#3cdf2b'

    if tab.is_active then
      foreground = '#1477da'
    elseif hover then
      foreground = '#1477da'
    end
    -- ensure that the titles fit in the available space,
    -- and that we have room for the edges.
    -- this is the way one can grab the title based on the wezterm 'precedence'
    -- on newly launched tab and windows, it would always end up with the porcess
    -- name as the title, no matter how I tried to override that
    -- in my use case, NO USING OSC 1/2 to set tab titles...
    -- local title = wezterm.truncate_right(tab.active_pane.title, max_width - 2)
    local title = wezterm.truncate_right(tab.tab_title, max_width - 2)
    -- this format is confusing, though I suspect the Foreground (and also Background) are just
    -- decorators for the Text that follows
    return {
      { Foreground = { Color = foreground } },
      { Text = "[ " },
      { Foreground = { Color = foreground } },
      { Text = title },
      { Foreground = { Color = foreground } },
      { Text = " ]" },
    }
  end),

  -- this is all VERY hacky... future self, be warned...
  -- It is done vi OSC communications https://wezfurlong.org/wezterm/escape-sequences/#operating-system-command-sequences
  -- This is called using this type of shell command
  --   jcmd=$(jq -n --arg title "${WINDOW_TITLE}" --arg jira "${JIRA_NUM}" '{"cmd":"open-window","title":"$title","jira":"$jira"}' | base64)
  --   printf "\033]1337;SetUserVar=%s=%s\007" shell-interactive-commands ${jcmd}
  --
  -- We pass in the command as a JSON set of key/value pairs, these are unmarshalled, if you will, into a lua object
  -- where the 'key' portion is a property of the variable, and the 'value' portion is the value of that property
  -- in our example above we end up with three properties: .cmd, .title, and .jira
  --
  -- Be aware that this routine will fire for EVERY TOP level window you have open, basically ensuring global coverage
  -- in the commands that are part of the 'shell_interactive_commands' table, there are checks to ensure that we are
  -- only updating for the top level window that we initiated the command from
  wezterm.on('user-var-changed', function(window, pane, name, value)
    if name == 'shell-interactive-commands' then
      local cmd_context = wezterm.json_parse(value)
      wezterm.log_info('cmd_context', cmd_context)
      shell_interactive_commands[cmd_context.cmd](window, pane, cmd_context)
      return
    end
  end),

  wezterm.on("open-uri", function(window, pane, uri)
    wezterm.log_info('open-uri', uri)
    local bash_command = extract_command(uri)
    if bash_command ~= nil then
      -- for pane_index, pane in ipairs(tab:panes_with_info()) do
      --    if pane.is_active then
      --     -- send some commands to the new pane, to set some defaults based on
      --     -- what we are working on, this works surprisingly well
          pane:send_text(bash_command)
      --   end
      -- end
      -- prevent the default action from opening in a browser
      return false
    end
  end),

}

