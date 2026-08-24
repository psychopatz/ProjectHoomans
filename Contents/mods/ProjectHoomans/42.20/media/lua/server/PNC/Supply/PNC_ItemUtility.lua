-- Stable supply item-utility entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ItemUtility = PNC.ItemUtility or {}
PNC.ItemUtility.Internal = PNC.ItemUtility.Internal or {}

local Utility = PNC.ItemUtility
local H = Utility.Internal

Utility.STATIC_SCHEMA = 2
if Utility.StaticSchema ~= Utility.STATIC_SCHEMA then
    Utility.StaticByTypeID = {}
    Utility.StaticSchema = Utility.STATIC_SCHEMA
else
    Utility.StaticByTypeID = Utility.StaticByTypeID or {}
end
Utility.Adapters = Utility.Adapters or {}

H.CoreInventory =
    require "PsychopatzCore/Inventory/PsychopatzInventory"
H.Constants =
    require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
H.StateCodec = require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreStateCodec"

require "PNC/Supply/ItemUtility/PNC_ItemUtility_Core"
require "PNC/Supply/ItemUtility/PNC_ItemUtility_StaticProfiles"
require "PNC/Supply/ItemUtility/PNC_ItemUtility_Descriptors"

return Utility
