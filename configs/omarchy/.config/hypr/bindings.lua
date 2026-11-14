-- Personal keybinding overrides, loaded after Omarchy's defaults. Add new
-- bindings with o.bind or replace defaults with o.rebind.
--
-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- Free up SUPER + / and SUPER + ALT + / (monitor scaling toggles)
hl.unbind("SUPER + SLASH")
hl.unbind("SUPER + ALT + SLASH")

-- Claude instead of ChatGPT
o.rebind("SUPER + SHIFT + A", "Claude", { webapp = "https://claude.ai/" })

-- On the UK Mac layout (the M1 MacBook), Alt + 3 types #, as Option + 3 does
-- on macOS. Right Option + 3 also works. This takes Alt + 3 from apps, such
-- as a browser's go-to-tab-3.
local keyboard = require("default.hypr.keyboard").selected()
if (keyboard.XKBLAYOUT or ""):match("^gb") and (keyboard.XKBVARIANT or ""):match("^mac") then
  o.bind("ALT + 3", "Type #", "wtype '#'")
end
