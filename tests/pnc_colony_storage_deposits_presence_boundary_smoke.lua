local T = require "tests/support/test"

local path =
    "PNC/Colony/Storage/ColonyStorageService/" ..
    "PNC_ColonyStorageService_Deposits.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix =
    "PNC/Colony/Storage/ColonyStorageService/" ..
    "ColonyStorageService_Deposits/"
local providers = {
    "PNC_ColonyStorageService_Deposits_Player",
    "PNC_ColonyStorageService_Deposits_NPC",
    "PNC_ColonyStorageService_Deposits_Courier",
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
        "function%s+Service%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

PNC = { ColonyStorageService = { Internal = {} } }
T.load("ProjectHoomans", "server", path)

local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(PNC.ColonyStorageService[name]), "function",
        "entry point preserves ColonyStorageService." .. name)
end
T.equal(publicCount, 5, "deposits public function count")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end

T.finish("pnc_colony_storage_deposits_presence_boundary_smoke")
