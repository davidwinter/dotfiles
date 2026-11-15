-- Extra autostart processes, loaded after Omarchy's defaults.

o.launch_on_start("1password --silent")

-- Start on workspace 1. With two monitors Hyprland can start focused on the
-- second one. Each monitor has its own block of workspaces (1-10, 11-20, ...),
-- so this focuses the monitor that owns the first block, and its workspace 1.
hl.on("hyprland.start", function()
  hl.dispatch(hl.dsp.focus({ workspace = "1" }))
end)
