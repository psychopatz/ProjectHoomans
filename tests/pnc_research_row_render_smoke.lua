-- The research tree stores each row as an envelope under entry.item:
--   { kind = "item", item = <row>, selected = <bool> }
-- The renderer used to read entry.item AS the row, so every row drew the
-- envelope: no name, the default source label, and a nil status that fell back
-- to the "NO RESEARCH TABLE" badge even while a research table was built and
-- research was running.
local T = require "tests/support/test"

T.addPackagePaths()

local drawn, badges = {}, {}

package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    return PsychopatzCore.UI
end

PsychopatzCore = {
    UI = {
        Theme = {
            colors = {
                text = { r = 1, g = 1, b = 1, a = 1 },
                textMuted = { r = 0.7, g = 0.7, b = 0.7, a = 1 },
                accent = { r = 0.2, g = 0.7, b = 0.8, a = 1 },
                surfaceRaised = { r = 0.1, g = 0.1, b = 0.1, a = 1 },
                success = { r = 0.4, g = 0.8, b = 0.5, a = 1 },
                warning = { r = 0.9, g = 0.7, b = 0.3, a = 1 },
            },
            Font = function() return "Small" end,
            TextWidth = function(_, value) return #tostring(value or "") * 7 end,
        },
        Layout = {
            Ellipsize = function(value) return tostring(value or "") end,
        },
        DrawListSelection = function() return true end,
        DrawBadge = function(_, text)
            badges[#badges + 1] = tostring(text)
            return #tostring(text) * 7
        end,
    },
}
PNC = { Translation = { GetKey = function(_, fallback) return fallback end } }

local Presentation = T.load("ProjectHoomans", "client",
    "PNC/UI/Research/PNC_ResearchPresentation.lua")

local function list()
    return {
        uiScale = 1, itemheight = 40,
        drawText = function(_, text) drawn[#drawn + 1] = tostring(text) end,
        drawRect = function() end,
        getWidth = function() return 400 end,
    }
end

-- A real tree row: envelope in entry.item, row one level deeper.
drawn, badges = {}, {}
Presentation.DrawCatalogRow(list(), 0, {
    item = { kind = "item", selected = true,
        item = { key = "technology:hq2", name = "Headquarters II",
            status = "available", source = "technology",
            requiredWork = 120 } },
}, false)
T.truthy(#drawn > 0, "row drew nothing at all")
T.contains(table.concat(drawn, "|"), "Headquarters II",
    "row renders the item name from the envelope")
T.contains(table.concat(drawn, "|"), "120 WORK",
    "row renders the item detail line")
T.equal(badges[1], "AVAILABLE",
    "row badge reflects the item status, not a fallback")
T.falsy(table.concat(drawn, "|"):find("NO RESEARCH TABLE", 1, true),
    "row no longer shows the missing-station warning for an available item")

-- Unknown status: no badge at all rather than the missing-station warning.
drawn, badges = {}, {}
Presentation.DrawCatalogRow(list(), 0, {
    item = { kind = "item", selected = false,
        item = { key = "technology:x", name = "Mystery",
            status = "something-new", source = "technology" } },
}, false)
T.equal(#badges, 0, "unknown status draws no badge")

-- An explicit unavailable status still reports the missing station.
drawn, badges = {}, {}
Presentation.DrawCatalogRow(list(), 0, {
    item = { kind = "item", selected = false,
        item = { key = "technology:y", name = "No Table",
            status = "unavailable", source = "technology" } },
}, false)
T.equal(badges[1], "NO RESEARCH TABLE",
    "a genuinely unavailable row still reports the missing station")

-- Group envelope rows keep their header rendering.
drawn, badges = {}, {}
Presentation.DrawCatalogRow(list(), 0, {
    item = { kind = "group",
        group = { id = "upgrades", title = "COLONY UPGRADES",
            knownCount = 0, totalCount = 21, activeCount = 1 } },
}, false)
T.contains(table.concat(drawn, "|"), "COLONY UPGRADES",
    "group header still renders its title")
T.contains(table.concat(drawn, "|"), "0/21",
    "group header still renders its known/total count")
T.equal(#badges, 0, "group header draws no status badge")

T.finish("pnc_research_row_render_smoke")
