local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Settlement/PNC_FacilityDefinitions.lua"
)
local prefix = "PNC/Core/Settlement/PNC_FacilityDefinitions/"
local providers = {
    "PNC_FacilityDefinitions_Core",
    "PNC_FacilityDefinitions_Stockpile",
    "PNC_FacilityDefinitions_Barracks",
    "PNC_FacilityDefinitions_Farm",
    "PNC_FacilityDefinitions_CommonRooms",
    "PNC_FacilityDefinitions_Workstations",
    "PNC_FacilityDefinitions_Water",
}
local publicFunctions = {
    "GetComponentIconPath",
    "Register",
    "Get",
    "GetLevel",
    "GetComponentCosts",
    "GetComponentBuildWork",
    "RequiresComponentConstruction",
    "GetComponentLimit",
    "RequiresWorkZone",
}
local facilityIDs = {
    "stockpile",
    "bedroom",
    "barracks",
    "farm",
    "living_room",
    "dining_room",
    "hospital",
    "research_facility",
    "workshop",
    "water_collector",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "' .. prefix .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Settlement/PNC_FacilityDefinitions.lua"
)
T.equal(PNC.FacilityDefinitions.SCHEMA_VERSION, 1, "schema version")
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.FacilityDefinitions[functionName]),
        "function",
        "entry point should preserve FacilityDefinitions." .. functionName
    )
end
for i = 1, #facilityIDs do
    local facilityID = facilityIDs[i]
    T.truthy(
        PNC.FacilityDefinitions.Get(facilityID),
        "entry point should register " .. facilityID
    )
end
for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end
T.equal(#PNC.FacilityDefinitions.GetComponentCosts(
    "barracks", 1, "work.zone"), 0,
    "work zone coordinate moves have no material cost")
T.equal(PNC.FacilityDefinitions.Get("barracks").id, "bedroom",
    "legacy barracks id resolves to the bedroom definition")
T.equal(PNC.FacilityDefinitions.Get("bedroom").zoneOverlay, true,
    "bedroom opts into the reusable zone overlay")
T.equal(PNC.FacilityDefinitions.Get("bedroom").zoneColor, "bedroom",
    "bedroom selects its dedicated overlay color")
T.equal(PNC.FacilityDefinitions.RequiresWorkZone(
    "bedroom", 1), false,
    "bedroom does not invent a labor standing area")
T.equal(PNC.FacilityDefinitions.GetComponentLimit(
    "bedroom", 1, "work.zone"), nil,
    "bedroom has no work-zone component limit")
T.equal(PNC.FacilityDefinitions.RequiresWorkZone(
    "farm", 1), true,
    "farm explicitly opts into a labor standing area")
T.equal(PNC.FacilityDefinitions.RequiresComponentConstruction(
    "barracks", 1, "work.zone", "region"), false,
    "work zone coordinate moves skip reconstruction")
T.equal(PNC.FacilityDefinitions.RequiresComponentConstruction(
    "barracks", 1, "sleep.bed", "anchor"), true,
    "ordinary component construction remains enabled")

T.finish("pnc_facility_definitions_presence_boundary_smoke")
