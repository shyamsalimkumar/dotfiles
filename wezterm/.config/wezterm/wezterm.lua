local wezterm = require("wezterm")

local config = wezterm.config_builder()

local is_windows = os.getenv("OS") and os.getenv("OS"):lower():find("windows")
local is_macos = wezterm.target_triple:lower():find("darwin") ~= nil

-- Utility functions
local window_background_opacity = 0.8
local function toggle_window_background_opacity(window)
  local overrides = window:get_config_overrides() or {}
  if not overrides.window_background_opacity then
    overrides.window_background_opacity = 1.0
  else
    overrides.window_background_opacity = nil
  end
  window:set_config_overrides(overrides)
end
wezterm.on("toggle-window-background-opacity", toggle_window_background_opacity)

-- Returns color scheme dependant on operating system theme setting (dark/light)
local function color_scheme_for_appearance(appearance)
  if appearance:find("Dark") then
    return "Tokyo Night Moon"
  else
    return "Tokyo Night Day"
  end
end

-- Start tmux when opening WezTerm.
-- The first pane creates/attaches the persistent "base" session. Every
-- subsequent pane (new tab, split, new window) joins "base" as its own
-- grouped session instead of attaching directly to it: grouped sessions
-- share the same window list but each tracks its own current window, so
-- a new tab no longer mirrors whatever window the previous tab was on
-- (plain `tmux attach`/`new -A` would show the exact same window in both).
-- Joining alone isn't enough, though: a freshly grouped session starts
-- pointed at whatever window "base" was already on, so two tabs opened
-- back to back land on the SAME window/pane (same pty) until one of them
-- navigates elsewhere -- keystrokes in one show up in the other because
-- it's literally one shell being viewed twice. `; new-window` immediately
-- creates and switches to a brand-new window on join, so every new tab
-- gets its own independent pane from the start.
config.default_prog = {
  "/bin/zsh",
  "-l",
  "-c",
  "--",
  "tmux has-session -t base 2>/dev/null && exec tmux new-session -t base \\; new-window || exec tmux new-session -s base",
}

-- Appearance
config.font = wezterm.font_with_fallback {
  -- "Departure Mono Nerd Font",
  -- "IosevkaTerm Nerd Font Mono",
  -- "JetBrainsMono Nerd Font",
  -- "Hack Nerd Font",
}
config.font_size = 18.0
-- config.color_scheme = color_scheme_for_appearance(wezterm.gui.get_appearance())
-- config.color_scheme = 'Google Dark (Gogh)'
config.window_background_opacity = window_background_opacity
config.macos_window_background_blur = 10
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true
config.native_macos_fullscreen_mode = false
config.use_fancy_tab_bar = false
config.max_fps = 144
config.animation_fps = 144

-- config.color_scheme = "rose-pine-moon"
config.color_scheme = 'Google Dark (Gogh)'
-- Override the scheme's selection colors: the default selection background
-- was too close to the pane background to tell selected text apart.
config.colors = {
  selection_fg = "#232136", -- rose-pine-moon Base (dark text on the highlight)
  selection_bg = "#c4a7e7", -- rose-pine-moon Iris (high-contrast highlight)
}
-- config.max_fps = 120
-- config.font = wezterm.font("Hack Nerd Font", { weight = "DemiBold" })
-- config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_frame = {
  font = wezterm.font("Hack Nerd Font", { weight = "Bold" }),
}
config.inactive_pane_hsb = {
  saturation = 0.0,
  brightness = 0.5,
}

-- Keybindings
-- Copy-on-select: WezTerm's default mouse selection only fills the internal
-- "primary selection" buffer, not the system clipboard (github.com/wezterm/wezterm/issues/2588).
-- Route left-click selection into the real clipboard too, so it's pasteable with Cmd+V immediately.
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor("ClipboardAndPrimarySelection"),
  },
  {
    event = { Up = { streak = 2, button = "Left" } },
    mods = "NONE",
    action = wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
  },
  {
    event = { Up = { streak = 3, button = "Left" } },
    mods = "NONE",
    action = wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
  },
}

-- Cmd+V: WezTerm only speaks the text-only OSC 52 clipboard protocol, so a
-- plain paste can't hand image bytes to apps like Claude Code that want to
-- read an image from the clipboard (github.com/wezterm/wezterm/issues/7272).
-- Shell out to `pngpaste` (brew install pngpaste) first: if the clipboard
-- holds an image, save it to a temp file and paste the file path as text
-- instead; otherwise fall through to a normal text paste.
local function paste_image_or_clipboard(window, pane)
  local image_dir = "/tmp/wezterm-clipboard-images"
  os.execute("mkdir -p " .. image_dir)
  local path = image_dir .. "/paste-" .. os.time() .. ".png"
  -- WezTerm.app is launched by macOS (not a login shell), so os.execute's
  -- PATH won't include Homebrew's /opt/homebrew/bin -- use the absolute
  -- path so this doesn't silently no-op as "command not found".
  local ok = os.execute("/opt/homebrew/bin/pngpaste " .. path .. " >/dev/null 2>&1")
  if ok then
    window:perform_action(wezterm.action.SendString(path), pane)
    window:toast_notification("WezTerm", "Image pasted: " .. path, nil, 4000)
  else
    os.remove(path)
    window:perform_action(wezterm.action.PasteFrom("Clipboard"), pane)
    window:toast_notification("WezTerm", "No image on clipboard, pasted text instead", nil, 4000)
  end
end

config.keys = {
  -- Cmd+/: open the full key-binding reference (`wezterm show-keys`) in a
  -- new tab. Complements the built-in command palette (Cmd+Shift+P), which
  -- only lists actionable commands from the main key table.
  {
    key = "/",
    mods = "CMD",
    action = wezterm.action.SpawnCommandInNewTab {
      domain = "CurrentPaneDomain",
      args = { "/bin/zsh", "-l", "-c", "wezterm show-keys | less" },
    },
  },
  {
    key = "v",
    mods = "CMD",
    action = wezterm.action_callback(paste_image_or_clipboard),
  },
  -- Shift+Enter: WezTerm doesn't distinguish this from plain Enter by
  -- default. Send ESC+CR, which Claude Code (and other readline-style
  -- apps) interpret as a soft newline instead of submitting.
  {
    key = "Enter",
    mods = "SHIFT",
    action = wezterm.action.SendString "\x1b\r",
  },
}

if is_windows then
  config.win32_system_backdrop = "Acrylic"
  config.window_background_opacity = 0.7
  config.window_frame.font_size = 10.0
end

if is_macos then
  config.window_background_opacity = 0.8
  config.macos_window_background_blur = 50
  config.font_size = 12.0
  config.window_frame.font_size = 10.0
end

-- Open the initial window sized to leave a fixed pixel gap around the
-- screen edges (20px left/right, 100px top/bottom) instead of a
-- percentage-of-screen size, so the gap stays constant across monitors.
wezterm.on("gui-startup", function(cmd)
  local screen = wezterm.gui.screens().active
  local gap_x, gap_y = 20, 100

  local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
  local gui_window = window:gui_window()
  gui_window:set_inner_size(screen.width - gap_x * 2, screen.height - gap_y * 2)
  gui_window:set_position(screen.x + gap_x, screen.y + gap_y)
end)

-- Return config to WezTerm
return config
