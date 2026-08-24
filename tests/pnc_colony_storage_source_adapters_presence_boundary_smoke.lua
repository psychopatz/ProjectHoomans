local T = require "tests/support/test"

local path = "PNC/Colony/Storage/ColonyStorageService/" ..
    "PNC_ColonyStorageService_SourceAdapters.lua"
local source = T.read("ProjectHoomans", "server", path)
local prefix = "PNC/Colony/Storage/ColonyStorageService/" ..
    "ColonyStorageService_SourceAdapters/"
local providers = {
    "PNC_ColonyStorageService_SourceAdapters_Player",
    "PNC_ColonyStorageService_SourceAdapters_Storage",
    "PNC_ColonyStorageService_SourceAdapters_Physical",
    "PNC_ColonyStorageService_SourceAdapters_AbstractNPC",
    "PNC_ColonyStorageService_SourceAdapters_LiveNPC",
    "PNC_ColonyStorageService_SourceAdapters_NPCBulk",
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
        "function%s+Internal%.([%w_]+)"
    ) do
        publicFunctions[name] = true
    end
end

local itemRecordPath =
    "PsychopatzCore/Inventory/PsychopatzItemRecord"
local stateCodecPath = "PNC/Core/Inventory/PNC_Inventory/" ..
    "Persistence/PNC_Inventory_CoreStateCodec"
package.preload[itemRecordPath] = function() return {} end
package.preload[stateCodecPath] = function()
    return { pseudoItem = function(item) return item end }
end
PNC = {
    ColonyStorageService = {
        Internal = { CoreInventory = {} },
    },
}
T.load("ProjectHoomans", "server", path)

local internal = PNC.ColonyStorageService.Internal
local publicCount = 0
for name in pairs(publicFunctions) do
    publicCount = publicCount + 1
    T.equal(type(internal[name]), "function",
        "entry point preserves storage adapter " .. name)
end
T.equal(publicCount, 8, "storage source-adapter function count")

for i = 1, #providers do
    package.loaded[prefix .. providers[i]] = nil
end
package.loaded[itemRecordPath] = nil
package.loaded[stateCodecPath] = nil
package.preload[itemRecordPath] = nil
package.preload[stateCodecPath] = nil

T.finish("pnc_colony_storage_source_adapters_presence_boundary_smoke")
