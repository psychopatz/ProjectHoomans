local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/PNC_Combat_Firearms.lua"
)
local providers = {
    "PNC_Combat_Firearms_Descriptors",
    "PNC_Combat_Firearms_Magazine",
    "PNC_Combat_Firearms_ReloadOps",
    "PNC_Combat_Firearms_State",
    "PNC_Combat_Firearms_Actions",
    "PNC_Combat_Firearms_Debug",
}
local publicFunctions = {
    "IsPlayerOwned",
    "UsesInventoryAmmo",
    "HasUnlimitedReserve",
    "Describe",
    "GetMagazineState",
    "PrepareShot",
    "StartReload",
    "CompleteReload",
    "BuildDebugState",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle =
        'require "PNC/Core/Combat/PNC_Combat_Firearms/'
            .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {
    Combat = {},
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/PNC_Combat_Firearms.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.Firearms[functionName]),
        "function",
        "entry point should preserve Firearms." .. functionName
    )
end

T.finish("pnc_combat_firearms_presence_boundary_smoke")
