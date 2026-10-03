require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Factions/PNC_FactionEmblemRenderer"
require "PNC/UI/Factions/PNC_FactionMemberModal"
require "PNC/Knowledge/PNC_NPCIdentityPresentation"

PNC = PNC or {}
PNC.FactionMemberUI = PNC.FactionMemberUI or {}
local MemberUI = PNC.FactionMemberUI
local Modal = PNC.FactionMemberModal
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local Identity = PNC.NPCIdentityPresentation

local CONTROLS = {
    { id = "refresh", label = "Refresh", variant = "quiet" },
    { id = "add_player", label = "Add Selected Player", variant = "success" },
    { id = "transfer_leadership", label = "Transfer Leadership", variant = "default" },
    { id = "banish_player", label = "Banish Player", variant = "danger" },
    { id = "follow", label = "NPC: Follow", variant = "success" },
    { id = "stay", label = "NPC: Stay", variant = "quiet" },
    { id = "attack_auto", label = "NPC: Auto Attack", variant = "default" },
    { id = "attack_none", label = "NPC: Hold Fire", variant = "danger" },
    { id = "all_follow", label = "All: Follow", variant = "success" },
    { id = "all_stay", label = "All: Stay", variant = "quiet" },
}
local function selectedItem(list)
    local entry = list and list:getItem()
    return entry and entry.item or nil
end
MemberUI.Internal = MemberUI.Internal or {}
MemberUI.Internal.Controls = CONTROLS
MemberUI.Internal.selectedItem = selectedItem

require "PNC/UI/Factions/PNC_FactionMemberWindow_Core"
require "PNC/UI/Factions/PNC_FactionMemberWindow_Actions"
require "PNC/UI/Factions/PNC_FactionMemberWindow_Lifecycle"

return MemberUI
