local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Equipment/PNC_Equipment_Slots.lua"
)
local providers = {
    "Locations", "VisualNormalization", "SlotMetadata", "LoadoutState",
    "AttachmentResolution", "Ordering", "VisualCapture",
    "VisualSummaries", "CharacterCapture",
}
local publicFunctions = {
    "VisualStateFromItemState", "StoreVisualStateInItemState",
    "NormalizeLoadoutSpec", "EnsureRecordEquipment", "SetLoadout",
    "SetPrimary", "SetSecondary", "SetAttached", "SetWorn",
    "ResolveAttachedSlotType", "ResolveAttachedLocation", "SetAttachedByItem",
    "GetOrderedWornEntries", "GetOrderedAttachedEntries",
    "CaptureItemVisualState", "BuildPrimaryVisualSummary",
    "BuildWornVisualSummary", "CaptureCharacterLoadout",
    "CopyCharacterLoadout",
}

local previous = 0
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "PNC/Core/Equipment/PNC_Equipment_Slots/'
        .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {}
T.load("ProjectHoomans", "shared", "PNC/Core/Equipment/PNC_Equipment_Slots.lua")

for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(type(PNC.Equipment[functionName]), "function",
        "entry point should preserve Equipment." .. functionName)
end
T.truthy(type(PNC.Equipment.Internal) == "table",
    "providers should share an internal contract")
T.finish("pnc_equipment_slots_presence_boundary_smoke")
