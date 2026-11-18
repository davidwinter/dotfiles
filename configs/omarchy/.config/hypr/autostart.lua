-- Extra autostart processes, loaded after Omarchy's defaults.

o.launch_on_start("1password --silent")

-- Start on the leftmost monitor's first workspace. With two monitors Hyprland
-- can start focused on the other one. Each monitor has its own workspaces, and
-- which block of numbers (1-10, 11-20, ...) it owns depends on the order
-- Omarchy first saw them, so pick the monitor by position, not by number.
hl.on("hyprland.start", function()
  local left
  for _, monitor in ipairs(hl.get_monitors()) do
    if not monitor.is_mirror and (not left or monitor.x < left.x) then
      left = monitor
    end
  end

  if left then
    hl.dispatch(o.workspaces.focus(1, left.name))
  end
end)
