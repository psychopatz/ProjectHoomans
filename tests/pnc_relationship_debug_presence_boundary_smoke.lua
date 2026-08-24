local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Social/PNC_RelationshipDebug.lua")
local prefix = "PNC/Social/RelationshipDebug/"
local providers = {
    "PNC_RelationshipDebug_Context",
    "PNC_RelationshipDebug_SnapshotParts",
    "PNC_RelationshipDebug_SnapshotBuilder",
    "PNC_RelationshipDebug_Pacification",
    "PNC_RelationshipDebug_Requests",
    "PNC_RelationshipDebug_SocialEvents",
    "PNC_RelationshipDebug_Formatting",
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
        "function%s+Debug%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", "PNC/Social/PNC_RelationshipDebug.lua")

local publicCount = 0
for name, _ in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.RelationshipDebug[name]), "function",
        "entry point should preserve RelationshipDebug." .. name)
end
T.equal(publicCount, 8, "relationship-debug function declaration count")
T.equal(PNC.RelationshipDebug.SetConversationStanding,
    PNC.RelationshipDebug.SetDebugBaseline,
    "conversation-standing compatibility alias")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_relationship_debug_presence_boundary_smoke")
