local T = require "tests/support/test"

local path = "PNC/Companions/PNC_DebugCompanionRecruit.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Companions/DebugCompanionRecruit/"
local providers = {
    "PNC_DebugCompanionRecruit_Core",
    "PNC_DebugCompanionRecruit_Community",
    "PNC_DebugCompanionRecruit_Ownership",
    "PNC_DebugCompanionRecruit_Persistence",
    "PNC_DebugCompanionRecruit_Assignment",
    "PNC_DebugCompanionRecruit_Reconciliation",
    "PNC_DebugCompanionRecruit_Commands",
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
        "function%s+Recruit%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.DebugCompanionRecruit[name]), "function",
        "entry point preserves DebugCompanionRecruit." .. name)
end
T.equal(publicCount, 6, "debug companion recruit public function count")
T.equal(PNC.Recruitment, PNC.DebugCompanionRecruit,
    "legacy Recruitment alias remains stable")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_debug_companion_recruit_presence_boundary_smoke")
