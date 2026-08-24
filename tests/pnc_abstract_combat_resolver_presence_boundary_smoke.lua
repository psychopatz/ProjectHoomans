local T = require "tests/support/test"

local path = "PNC/Director/PNC_AbstractCombatResolver.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Director/AbstractCombatResolver/"
local providers = {
    "PNC_AbstractCombatResolver_Math",
    "PNC_AbstractCombatResolver_Resources",
    "PNC_AbstractCombatResolver_Outcomes",
    "PNC_AbstractCombatResolver_Resolution",
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
        "function%s+Combat%.([%w_]+)%s*%("
    ) do publicFunctions[name] = true end
end

PNC = {
    DirectorConfig = {}, AbstractWorldStore = {},
    AbstractCombatProfile = {}, AbstractBehaviorProfile = {},
    AbstractCasualtyResolver = {}, AbstractRetreatResolver = {},
    AbstractGroups = {},
}
local Combat = T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(Combat[name]), "function",
        "entry point preserves AbstractCombatResolver." .. name)
end
T.equal(publicCount, 1, "abstract-combat public function count")
T.equal(type(Combat.Metrics), "table", "combat metrics remain initialized")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_abstract_combat_resolver_presence_boundary_smoke")
