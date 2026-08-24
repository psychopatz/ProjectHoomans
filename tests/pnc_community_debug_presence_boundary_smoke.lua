local T = require "tests/support/test"

local path = "PNC/Communities/PNC_CommunityDebug.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Communities/CommunityDebug/"
local providers = {
    "PNC_CommunityDebug_Core",
    "PNC_CommunityDebug_Summaries",
    "PNC_CommunityDebug_Snapshot",
    "PNC_CommunityDebug_Actions",
    "PNC_CommunityDebug_Format",
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
T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.CommunityDebug[name]), "function",
        "entry point preserves CommunityDebug." .. name)
end
T.equal(publicCount, 3, "community-debug public function count")
T.equal(type(PNC.CommunityDebugInternal), "table",
    "community-debug internals remain initialized")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_community_debug_presence_boundary_smoke")
