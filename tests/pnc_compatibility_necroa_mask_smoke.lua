local T = require "tests/support/test"

local API_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/PNC_Compatibility_API.lua"
)
local MASK_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/Mods/Necroa/PNC_Necroa_Mask.lua"
)
local POLICY_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/Mods/Necroa/PNC_Necroa_Policy.lua"
)
local ADAPTER_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/Mods/Necroa/PNC_Necroa_Adapter.lua"
)

getActivatedMods = function()
    return {
        contains = function(_, value) return value == "Necroa" end,
    }
end

PNC = {
    Core = {},
    Compatibility = {},
    Equipment = {
        EnsureRecordEquipment = function(record)
            record.equipment = record.equipment or { worn = {} }
            record.equipment.worn = record.equipment.worn or {}
            return record.equipment
        end,
        SetWorn = function(record, slot, fullType)
            record.equipment.worn[slot] = fullType
            return true
        end,
    },
    Inventory = {
        SyncFromEquipment = function(record)
            record.runtimeSynced = true
            return true
        end,
    },
}

T.load(API_FILE)
local mask = T.load(MASK_FILE)
local policy = T.load(POLICY_FILE)
T.load(ADAPTER_FILE)

T.truthy(policy.IsActive(), "Necroa activation was not detected")
T.truthy(mask.IsMaskItem("Base.Hat_SurgicalMask"),
    "surgical mask was not recognized")
T.truthy(mask.IsMaskItem("Base.Hat_GasMask"),
    "gas mask was not recognized")
T.falsy(mask.IsMaskItem("Base.Tshirt"),
    "ordinary clothing was misidentified as a mask")

local wornItem = {
    getFullType = function() return "Base.Hat_SurgicalMask" end,
}
local wornItems = {
    size = function() return 1 end,
    get = function(_, index) return index == 0 and wornItem or nil end,
}
local body = {
    getWornItems = function() return wornItems end,
    getWornItem = function() error("invalid string body-location overload") end,
}
T.truthy(mask.HasMask(body),
    "live mask detection did not use the safe worn-items collection")
T.truthy(mask.HasRecordMask({
    equipment = { worn = { Mask = "Base.Hat_SurgicalMask" } },
}), "logical equipment mask was not recognized")

local record = { equipment = { worn = {} } }
local emitted = PNC.Compatibility.API.EmitEvent("npc_spawn", {
    record = record,
})
T.equal(emitted, 1, "Necroa spawn adapter did not handle the spawn event")
T.equal(record.equipment.worn.Mask, "Base.Hat_SurgicalMask",
    "Necroa did not equip the default surgical mask")
T.truthy(record.runtimeSynced,
    "default mask was not synchronized into the logical inventory")

T.finish("pnc_compatibility_necroa_mask_smoke")
