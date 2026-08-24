local T = require "tests/support/test"

local path = "PNC/Communities/PNC_CommunitySiteResolver.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Communities/CommunitySiteResolver/"
local providers = {
    "PNC_CommunitySiteResolver_Core",
    "PNC_CommunitySiteResolver_Description",
    "PNC_CommunitySiteResolver_Candidates",
    "PNC_CommunitySiteResolver_Finders",
    "PNC_CommunitySiteResolver_SpawnPoints",
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
        "function%s+Resolver%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = {}
T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.CommunitySiteResolver[name]), "function",
        "entry point preserves CommunitySiteResolver." .. name)
end
T.equal(publicCount, 7, "community-site-resolver public function count")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_community_site_resolver_presence_boundary_smoke")
