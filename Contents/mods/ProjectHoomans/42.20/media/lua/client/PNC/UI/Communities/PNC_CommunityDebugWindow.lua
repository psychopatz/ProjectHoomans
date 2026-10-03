require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Communities/PNC_CommunityDebugModel"
require "PNC/UI/Communities/PNC_CommunityDebugOverlay"

PNC = PNC or {}
PNC.CommunityDebugUI = PNC.CommunityDebugUI or {}
local CommunityUI = PNC.CommunityDebugUI
local Model = PNC.CommunityDebugModel
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local CONTROLS = {
    { id = "refresh", key = "UI_PNC_MonitorRefresh", variant = "quiet" },
    { id = "overlay", key = "UI_PNC_CommunityToggleOverlay", variant = "quiet" },
    { id = "create_settlement", key = "UI_PNC_CommunityCreateSettlement", variant = "success" },
    { id = "create_camp", key = "UI_PNC_CommunityCreateCamp", variant = "success" },
    { id = "assign", key = "UI_PNC_CommunityAssignNPC", variant = "success" },
    { id = "transfer", key = "UI_PNC_CommunityTransferNPC", variant = "default" },
    { id = "remove", key = "UI_PNC_CommunityRemoveNPC", variant = "danger" },
    { id = "leader", key = "UI_PNC_CommunitySetLeader", variant = "default" },
    { id = "role", key = "UI_PNC_CommunityNextRole", variant = "quiet" },
    { id = "set_home_to_npc", key = "UI_PNC_CommunitySetHome", variant = "quiet" },
    { id = "security_down", key = "UI_PNC_CommunitySecurityDown", variant = "quiet" },
    { id = "security_up", key = "UI_PNC_CommunitySecurityUp", variant = "quiet" },
    { id = "morale_down", key = "UI_PNC_CommunityMoraleDown", variant = "quiet" },
    { id = "morale_up", key = "UI_PNC_CommunityMoraleUp", variant = "quiet" },
    { id = "supply_add", key = "UI_PNC_CommunityAddSupply", variant = "success" },
    { id = "supply_remove", key = "UI_PNC_CommunityRemoveSupply", variant = "danger" },
    { id = "next_supply", key = "UI_PNC_CommunityNextSupply", variant = "quiet" },
    { id = "validate", key = "UI_PNC_CommunityValidate", variant = "quiet" },
    { id = "repair_indexes", key = "UI_PNC_CommunityRepair", variant = "danger" },
    { id = "archive", key = "UI_PNC_CommunityArchive", variant = "danger" },
    { id = "destroy", key = "UI_PNC_CommunityDestroy", variant = "danger" },
}
local function selected(list)
    local entry = list and list:getItem()
    return entry and entry.item or nil
end
CommunityUI.Internal = CommunityUI.Internal or {}
CommunityUI.Internal.Controls = CONTROLS
CommunityUI.Internal.selected = selected

require "PNC/UI/Communities/PNC_CommunityDebugWindow_Core"
require "PNC/UI/Communities/PNC_CommunityDebugWindow_Actions"
require "PNC/UI/Communities/PNC_CommunityDebugWindow_Lifecycle"

return CommunityUI
