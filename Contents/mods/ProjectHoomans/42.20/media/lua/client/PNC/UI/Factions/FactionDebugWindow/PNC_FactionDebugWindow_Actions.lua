-- Faction debug window action dispatcher.


PNC = PNC or {}
PNC.FactionDebugUI = PNC.FactionDebugUI or {}

local FactionUI = PNC.FactionDebugUI
local Internal = FactionUI.Internal or {}
FactionUI.Internal = Internal
function ISPNCFactionDebugWindow:onAction(button)
    local internal = button.internal
    if Internal.HandleMobileFilterAction(self, internal) then return end
    local faction = self:getFaction()
    local npc = self:getNPC()
    local target = self:getTargetFaction()
    if Internal.HandleWindowAction(
        self, button, internal, faction, npc, target
    ) then
        return
    end
    if Internal.HandleModeAction(self, button, internal, faction) then
        return
    end
    Internal.SendAction(self, internal, faction, npc, target)
end
