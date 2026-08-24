local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Social/PNC_SocialEncounterTracker.lua")
local prefix = "PNC/Social/SocialEncounterTracker/"
local providers = {
    "PNC_SocialEncounterTracker_Context",
    "PNC_SocialEncounterTracker_Activity",
    "PNC_SocialEncounterTracker_Abandonment",
    "PNC_SocialEncounterTracker_Completion",
    "PNC_SocialEncounterTracker_Pump",
}

local previous = 0
local publicFunctions = {}
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "' .. prefix .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
    local providerSource = T.read(
        "ProjectHoomans", "server", prefix .. provider .. ".lua")
    for name in providerSource:gmatch(
        "function%s+Tracker%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", "PNC/Social/PNC_SocialEncounterTracker.lua")

local publicCount = 0
for name, _ in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.SocialEncounterTracker[name]), "function",
        "entry point should preserve SocialEncounterTracker." .. name)
end
T.equal(publicCount, 11, "social-encounter function declaration count")
T.equal(type(PNC.SocialEncounterTracker.Encounters), "table",
    "entry point should preserve encounter state")
T.equal(PNC.SocialEncounterTracker.ABANDON_DISTANCE, 20,
    "entry point should preserve public tuning constants")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_social_encounter_tracker_presence_boundary_smoke")
