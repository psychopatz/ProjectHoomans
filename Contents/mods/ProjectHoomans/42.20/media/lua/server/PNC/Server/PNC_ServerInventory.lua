if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

require "PNC/00_PNC_Init"

PNC = PNC or {}
PNC.ServerInventory = PNC.ServerInventory or {}
PNC.ServerInventory.Internal = PNC.ServerInventory.Internal or {}

require "PNC/Server/ServerInventory/PNC_ServerInventory_Context"
require "PNC/Server/ServerInventory/PNC_ServerInventory_NativeItems"
require "PNC/Server/ServerInventory/PNC_ServerInventory_CompactItems"
require "PNC/Server/ServerInventory/PNC_ServerInventory_PlayerToNPC"
require "PNC/Server/ServerInventory/PNC_ServerInventory_NPCToPlayer"
require "PNC/Server/ServerInventory/PNC_ServerInventory_GiftEffects"
require "PNC/Server/ServerInventory/PNC_ServerInventory_Transfer"
require "PNC/Server/ServerInventory/PNC_ServerInventory_Actions"

return PNC.ServerInventory
