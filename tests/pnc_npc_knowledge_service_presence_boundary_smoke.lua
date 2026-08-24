local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans", "server", "PNC/Knowledge/PNC_NPCKnowledgeService.lua")
local prefix = "PNC/Knowledge/NPCKnowledgeService/"
local providers = {
    "PNC_NPCKnowledgeService_Core",
    "PNC_NPCKnowledgeService_Normalization",
    "PNC_NPCKnowledgeService_Persistence",
    "PNC_NPCKnowledgeService_Resolution",
    "PNC_NPCKnowledgeService_Evidence",
    "PNC_NPCKnowledgeService_JournalsAndDisclosure",
    "PNC_NPCKnowledgeService_PlayerSnapshots",
    "PNC_NPCKnowledgeService_DebugSnapshots",
    "PNC_NPCKnowledgeService_Discovery",
    "PNC_NPCKnowledgeService_DebugCommands",
    "PNC_NPCKnowledgeService_Hooks",
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
        "function%s+Knowledge%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", "PNC/Knowledge/PNC_NPCKnowledgeService.lua")

local publicCount = 0
for name, _ in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.NPCKnowledge[name]), "function",
        "entry point should preserve NPCKnowledge." .. name)
end
T.equal(publicCount, 28, "public function declaration count")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_npc_knowledge_service_presence_boundary_smoke")
