local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Registry/PNC_Registry.lua"
)
local providers = {
    "PNC_Registry_StorageCore",
    "PNC_Registry_StorageMigration",
    "PNC_Registry_LoadDirty",
    "PNC_Registry_Records",
    "PNC_Registry_LivePositions",
}
local publicFunctions = {
    "MarkDirty",
    "Load",
    "EnsureLoaded",
    "FlushDirty",
    "Save",
    "ForEach",
    "ForEachLive",
    "AddRecord",
    "RemoveRecord",
    "Get",
    "GetLiveZombie",
    "RegisterLiveZombie",
    "UnregisterLiveZombie",
    "FindRecordByZombie",
    "RefreshLivePositions",
    "RefreshLivePosition",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle =
        'require "PNC/Core/Registry/PNC_Registry/'
            .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

local added
PNC = {
    Core = {},
    Const = {},
}
Events = {
    OnInitGlobalModData = {
        Add = function(callback) added = callback end,
    },
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Registry/PNC_Registry.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.Registry[functionName]),
        "function",
        "entry point should preserve Registry." .. functionName
    )
end
T.equal(type(added), "function", "global ModData hook")

for i = 1, #providers do
    package.loaded[
        "PNC/Core/Registry/PNC_Registry/" .. providers[i]
    ] = nil
end

T.finish("pnc_registry_presence_boundary_smoke")
