local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Map/PNC_MapPresentation.lua"

PNC = {
    Const = {
        MAP_PRESENTATION_MAX_KNOWN_PLAYERS = 2,
        MAP_PRESENTATION_ROLE_MAX_LENGTH = 8,
        MAP_PRESENTATION_ICON_MAX_LENGTH = 10,
    },
}

T.load(FILE)

local default = PNC.MapPresentation.Normalize(nil)
T.truthy(default.visibility == "all", "default marker visibility is not all")
T.truthy(PNC.MapPresentation.IsVisibleFor(default, "Alice", false),
    "default marker was hidden")

local record = {}
T.truthy(PNC.MapPresentation.Apply(record, {
    visibility = "known",
    roleTag = "very-long-trader",
    iconID = "quest_giver_long",
}))
T.truthy(record.mapPresentation.roleTag == "very-lon",
    "role tag was not bounded")
T.truthy(record.mapPresentation.iconID == "quest_give",
    "icon id was not bounded")

PNC.MapPresentation.SetKnown(record, "Alice", true)
PNC.MapPresentation.SetKnown(record, "Bob", true)
PNC.MapPresentation.SetKnown(record, "Carol", true)
local count = 0
for _ in pairs(record.mapPresentation.knownBy) do count = count + 1 end
T.truthy(count == 2, "known-player set exceeded its bound")
T.truthy(PNC.MapPresentation.IsVisibleFor(record.mapPresentation, "Alice", false),
    "known player could not see marker")
T.truthy(not PNC.MapPresentation.IsVisibleFor(
    record.mapPresentation,
    "Unknown",
    false
), "unknown player could see known-only marker")
T.truthy(PNC.MapPresentation.IsVisibleFor(
    { visibility = "hidden" },
    "Unknown",
    true
), "selected marker did not override hidden mode")
T.truthy(not PNC.MapPresentation.IsVisibleFor(
    { visibility = "selected" },
    "Alice",
    false
), "unselected marker leaked from selected-only mode")
T.finish("pnc_map_presentation_smoke")

T.finish("pnc_map_presentation_smoke")
