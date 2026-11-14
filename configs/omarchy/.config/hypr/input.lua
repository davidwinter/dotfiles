-- Personal input overrides, loaded after Omarchy's defaults. Omarchy's own
-- input.lua template lists the other settings.
--
-- The keyboard layout is set on each machine with Omarchy's layout picker
-- (omarchy-setup-keyboard), which keeps Hyprland and the Fcitx5 input method
-- in step; a layout set here would be out of step with Fcitx5.

-- Natural scrolling on trackpads. Mice keep the default (input.natural_scroll).
hl.config({
  input = {
    touchpad = {
      natural_scroll = true,
    },
  },
})
