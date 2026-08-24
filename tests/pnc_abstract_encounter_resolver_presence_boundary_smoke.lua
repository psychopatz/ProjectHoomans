local T = require "tests/support/test"

local path = "PNC/Director/PNC_AbstractEncounterResolver.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Director/AbstractEncounterResolver/"
local providers = {
    "PNC_AbstractEncounterResolver_Core",
    "PNC_AbstractEncounterResolver_State",
    "PNC_AbstractEncounterResolver_Hostile",
    "PNC_AbstractEncounterResolver_Displacement",
    "PNC_AbstractEncounterResolver_Resolution",
    "PNC_AbstractEncounterResolver_QueueProcessing",
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
T.load("ProjectHoomans", "server", path)

local expectedFunctions = {
    "Enqueue",
    "EvaluateHostileResponse",
    "Resolve",
    "ProcessBatch",
}
for i = 1, #expectedFunctions do
    local name = expectedFunctions[i]
    T.equal(type(PNC.AbstractEncounterResolver[name]), "function",
        "entry point preserves AbstractEncounterResolver." .. name)
end
T.equal(type(PNC.AbstractEncounterResolver.Queue), "table",
    "encounter queue remains initialized")
T.equal(type(PNC.AbstractEncounterResolver.QueuedIDs), "table",
    "queued encounter IDs remain initialized")
T.equal(type(PNC.AbstractEncounterResolver.Metrics), "table",
    "encounter metrics remain initialized")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_abstract_encounter_resolver_presence_boundary_smoke")
