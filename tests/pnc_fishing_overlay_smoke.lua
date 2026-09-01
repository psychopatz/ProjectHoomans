local T = require "tests/support/test"

T.addPackagePaths()

local highlights = {}
addAreaHighlightForPlayer = function(...)
    highlights[#highlights + 1] = { ... }
end
getSpecificPlayer = function()
    return { getPlayerNum = function() return 0 end }
end

PNC = {}
local Overlay = T.load("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_FishingZoneOverlay.lua")
local zone = {
    valid = true,
    geometry = { levels = { [0] = { rows = { [0] = { 1, 2 } } } } },
    fishingSpots = {{ standX = 1.5, standY = 0.5, standZ = 0 }},
}

T.truthy(Overlay.SetZone(zone), "valid fishing zone was not accepted")
T.truthy(Overlay.IsEnabled(), "valid fishing overlay was not enabled")
Overlay.Render()
T.equal(#highlights, 2, "fishing zone and shoreline overlays were not rendered")
Overlay.Clear()
T.falsy(Overlay.IsEnabled(), "fishing overlay did not clear")

T.finish("pnc_fishing_overlay_smoke")
