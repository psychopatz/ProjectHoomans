local T = require "tests/support/test"

T.addPackagePaths()

local highlights = {}
addAreaHighlightForPlayer = function(...)
    highlights[#highlights + 1] = { ... }
end
getSpecificPlayer = function()
    return { getPlayerNum = function() return 0 end }
end

local fishingCalls = {}
PNC = {
    FishingZoneOverlay = {
        SetZone = function(zone, owner)
            fishingCalls[#fishingCalls + 1] = { "set", zone, owner }
            return true
        end,
        Clear = function(owner)
            fishingCalls[#fishingCalls + 1] = { "clear", owner }
            return true
        end,
    },
}

local Overlay = T.load("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_ZoneOverlay.lua")
local region = { levels = { [0] = { rows = { [10] = { 10, 11 } } } } }

T.truthy(Overlay.SetActive("lumber", { geometry = region }),
    "lumber overlay did not activate")
Overlay.Render()
T.equal(#highlights, 1, "lumber overlay did not render its region")
T.equal(#fishingCalls, 1, "lumber activation did not clean fishing ownership")
T.equal(fishingCalls[1][1], "clear", "wrong fishing cleanup operation")

highlights = {}
T.truthy(Overlay.SetActive("corpse_haul", {
    sourceRegion = region,
    destinationRegion = { levels = { [0] = { rows = { [10] = { 11, 12 } } } } },
}), "corpse overlay did not activate")
Overlay.Render()
T.equal(#highlights, 3,
    "corpse overlay did not split source, destination, and overlap tiles")
T.equal(highlights[1][2], 10,
    "corpse source-only tile was not rendered first")
T.equal(highlights[2][2], 12,
    "corpse destination-only tile was not rendered separately")
T.equal(highlights[3][2], 11,
    "corpse overlap tile was not rendered separately")
T.near(highlights[3][7], 1.0,
    "corpse overlap tile did not use the conflict color")
T.near(highlights[3][8], 0.12,
    "corpse overlap tile did not use the conflict color")

highlights = {}
PsychopatzCore = { UI = { GridRegionSelector = {
    IsWorldInputOwned = function() return true end,
} } }
Overlay.Render()
T.equal(#highlights, 0,
    "zone overlay rendered while the region selector owned world input")
PsychopatzCore = nil

T.truthy(Overlay.SetActive("fishing", {
    valid = true, geometry = region,
}), "fishing overlay did not activate")
T.equal(fishingCalls[#fishingCalls][1], "set",
    "fishing activation did not delegate to fishing renderer")
T.equal(fishingCalls[#fishingCalls][3], Overlay.OWNER,
    "fishing overlay owner was not scoped to the command hub")

Overlay.Clear()
T.equal(fishingCalls[#fishingCalls][1], "clear",
    "zone overlay did not clear its fishing renderer")

T.finish("pnc_command_hub_zone_overlay_smoke")
