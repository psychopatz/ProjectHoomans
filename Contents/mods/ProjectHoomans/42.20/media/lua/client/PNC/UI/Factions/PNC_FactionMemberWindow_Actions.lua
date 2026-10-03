local MemberUI = PNC.FactionMemberUI
local Modal = PNC.FactionMemberModal
local ClientState = PNC.Network.ClientState
local CONTROLS = MemberUI.Internal.Controls
local selectedItem = MemberUI.Internal.selectedItem
local function tr(key, fallback)
    local value = getText and PNC.Translation.GetKey(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end
function ISPNCFactionMemberWindow:confirmPlayerAction(
    action,
    item
)
    local labels = {
        add_player = {
            title = tr(
                "UI_PNC_FactionMemberAddTitle",
                "Add Player to Faction"
            ),
            message = "Add " .. tostring(item.label)
                .. " as a faction member?",
            confirm = tr(
                "UI_PNC_FactionMemberAdd",
                "Add Player"
            ),
        },
        transfer_leadership = {
            title = tr(
                "UI_PNC_FactionMemberTransferTitle",
                "Transfer Faction Leadership"
            ),
            message = "Make " .. tostring(item.label)
                .. " the faction's only leader?",
            detail = "You will remain a faction member.",
            confirm = tr(
                "UI_PNC_FactionMemberTransfer",
                "Transfer"
            ),
        },
        banish_player = {
            title = tr(
                "UI_PNC_FactionMemberBanishTitle",
                "Banish Faction Member"
            ),
            message = "Remove " .. tostring(item.label)
                .. " from this faction?",
            detail = "They immediately lose access to faction NPC commands.",
            confirm = tr(
                "UI_PNC_FactionMemberBanish",
                "Banish"
            ),
            danger = true,
        },
    }
    local definition = labels[action]
    if not definition then return end
    Modal.Open({
        title = definition.title,
        message = definition.message,
        detail = definition.detail,
        confirmLabel = definition.confirm,
        danger = definition.danger,
        context = {
            action = action,
            playerKey = item.key,
        },
        onConfirm = function(context)
            PNC.Client.SendFactionMemberAction(
                context.action,
                context.playerKey
            )
        end,
    })
end

function ISPNCFactionMemberWindow:onAction(button)
    local action = button and button.internal or ""
    if action == "refresh" then
        self:requestSnapshot()
        return
    end
    if action == "add_player" then
        local item = selectedItem(self.availablePlayers)
        if item then self:confirmPlayerAction(action, item) end
        return
    end
    if action == "transfer_leadership"
        or action == "banish_player"
    then
        local item = selectedItem(self.playerMembers)
        if item then self:confirmPlayerAction(action, item) end
        return
    end
    local npc = selectedItem(self.npcMembers)
    if action == "all_follow" then
        PNC.Client.SendCompanionCommand(
            "follow",
            nil,
            "group"
        )
    elseif action == "all_stay" then
        PNC.Client.SendCompanionCommand(
            "stay",
            nil,
            "group"
        )
    elseif npc then
        PNC.Client.SendCompanionCommand(
            action,
            npc.id,
            "member_window"
        )
    end
end
