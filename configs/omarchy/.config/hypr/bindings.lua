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
