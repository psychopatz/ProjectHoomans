local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Social/PNC_RelationshipService.lua")
local prefix = "PNC/Social/RelationshipService/"
local providers = {
    "PNC_RelationshipService_Context",
    "PNC_RelationshipService_Commit",
    "PNC_RelationshipService_Queries",
    "PNC_RelationshipService_MemoryCommands",
    "PNC_RelationshipService_EventMutation",
    "PNC_RelationshipService_Maintenance",
    "PNC_RelationshipService_PersonalBoundary",
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
        "function%s+Relationships%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", "PNC/Social/PNC_RelationshipService.lua")

local publicCount = 0
for name, _ in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.Relationships[name]), "function",
        "entry point should preserve Relationships." .. name)
end
T.equal(publicCount, 14, "relationship function declaration count")
T.equal(PNC.Relationships.Personal.Queries.Get,
    PNC.Relationships.Get, "personal Get compatibility")
T.equal(PNC.Relationships.Personal.Commands.AddMemory,
    PNC.Relationships.AddMemory, "personal AddMemory compatibility")
T.equal(PNC.Relationships.Personal.Commands.ApplyEventMutation,
    PNC.Relationships.ApplyEventMutation,
    "personal ApplyEventMutation compatibility")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_relationship_service_presence_boundary_smoke")
