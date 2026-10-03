local CommunityUI = PNC.CommunityDebugUI
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local text = function(key)
    return getText and PNC.Translation.GetKey(key) or key
end
local CONTROLS = CommunityUI.Internal.Controls
local selected = CommunityUI.Internal.selected

function ISPNCCommunityDebugWindow:onAction(button)
    local internal = button.internal
    local community = selected(self.communities)
    local faction = selected(self.factions)
    local npc = selected(self.npcs)
    if internal == "refresh" then
        self:requestSnapshot()
        return
    end
    if internal == "overlay" then
        PNC.CommunityDebugOverlay.Toggle()
        return
    end
    local snapshot = ClientState.communityDebug or {}
    if internal == "next_supply" then
        local values = snapshot.supplyCategories or {}
        if #values > 0 then
            self.supplyIndex =
                ((self.supplyIndex or 1) % #values) + 1
            button:setTitle(
                text("UI_PNC_CommunityNextSupply")
                    .. ": " .. values[self.supplyIndex]
            )
            self:requestResponsiveLayout(true)
        end
        return
    end
    local payload = {
        communityAction = internal,
        communityID = community and community.id,
        factionID = faction and faction.id,
        npcID = npc and npc.id,
    }
    if internal == "security_down" then
        payload.communityAction = "security"
        payload.delta = -5
    elseif internal == "security_up" then
        payload.communityAction = "security"
        payload.delta = 5
    elseif internal == "morale_down" then
        payload.communityAction = "morale"
        payload.delta = -5
    elseif internal == "morale_up" then
        payload.communityAction = "morale"
        payload.delta = 5
    elseif internal == "supply_add"
        or internal == "supply_remove"
    then
        payload.category = (
            snapshot.supplyCategories or {}
        )[self.supplyIndex or 1] or "food"
        payload.amount = 5
    elseif internal == "role" then
        local roles = snapshot.communityRoles or {}
        if #roles > 0 then
            self.roleIndex =
                ((self.roleIndex or 1) % #roles) + 1
            payload.communityRole = roles[self.roleIndex]
        end
    elseif internal == "assign"
        or internal == "transfer"
    then
        local roles = snapshot.communityRoles or {}
        payload.communityRole =
            roles[self.roleIndex or 1] or "resident"
    end
    PNC.Client.SendDebug(
        "community_debug_action",
        payload
    )
end

function ISPNCCommunityDebugWindow:selectionSignature()
    local community = selected(self.communities)
    local faction = selected(self.factions)
    local npc = selected(self.npcs)
    return tostring(community and community.id or "")
        .. "|" .. tostring(faction and faction.id or "")
        .. "|" .. tostring(npc and npc.id or "")
end
