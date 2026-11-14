-- Extra autostart processes, loaded after Omarchy's defaults.

o.launch_on_start("1password --silent")

-- Older Omarchy sometimes started on another workspace. Uncomment if it does
-- again.
-- hl.on("hyprland.start", function()
--   hl.dispatch(hl.dsp.focus({ workspace = "1" }))
-- end)
