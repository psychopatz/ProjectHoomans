-- Faction debug window control-state lifecycle.


PNC = PNC or {}
PNC.FactionDebugUI = PNC.FactionDebugUI or {}

local FactionUI = PNC.FactionDebugUI
local Internal = FactionUI.Internal or {}
FactionUI.Internal = Internal
local ClientState = Internal.ClientState
local CONTROLS = Internal.Controls
local text = Internal.Text
local function requestRefresh(self)
    local now = PNC.Core.Now()
    local received =
        tonumber(ClientState.lastFactionDebugReceiveAt) or 0
    local signature = self:selectionSignature()
    if received > (tonumber(self.lastReceiveAt) or 0) then
        self:refreshSnapshot()
        signature = self:selectionSignature()
    end
    if signature ~= self.requestedSignature then
        self.requestedSignature = signature
        self:requestSnapshot()
    end
    if now - (tonumber(self.lastRequestAt) or 0) > 2500 then
        self:requestSnapshot()
    end
end

local function isMobileVisibilityControl(internal)
    return internal == "mobile_control_mode"
        or internal == "mobile_path_mode"
        or internal == "mobile_refresh"
        or internal == "mobile_relocate"
        or internal == "force_mobile_road"
        or internal == "force_mobile_departure"
        or internal == "force_mobile_arrival"
        or internal == "repair_mobile_travel"
end

local function enabledForControl(internal, self, context)
    local faction = context.faction
    local npc = context.npc
    local create = string.sub(internal, 1, 7) == "create_"
        and internal ~= "create_player_faction"
    local enabled = internal == "refresh"
        or internal == "overlay" or create
    if string.sub(internal, 1, 5) == "view_" then
        enabled = string.sub(internal, 6) ~= self.viewMode
    end
    if internal == "create_player_faction" then
        enabled = context.playerFactionID == nil
    elseif internal == "edit_emblem" then
        enabled = faction ~= nil
            and context.playerFactionID == faction.id
            and faction.faction.ownerPlayerKey ~= nil
    elseif internal == "generate_group" then
        enabled = faction ~= nil
            and faction.faction.status == "active"
    elseif internal == "create_mobile_player_route_group" then
        local departure = context.snapshot.mobileDeparture or {}
        enabled = (tonumber(departure.playerBaseCount) or 0) > 0
    elseif internal == "mobile_control_mode"
        or internal == "mobile_path_mode"
        or internal == "mobile_refresh"
        or internal == "force_mobile_road"
        or internal == "force_mobile_departure"
        or internal == "force_mobile_arrival"
        or internal == "repair_mobile_travel"
    then
        enabled = context.isMobileFaction
    elseif internal == "mobile_relocate" then
        enabled = context.isMobileFaction
    elseif internal == "roll_mobile_departures" then
        enabled = true
    elseif internal == "population_label" then
        enabled = false
    elseif internal == "presence_mode"
    then
        enabled = true
    elseif internal == "war" then
        enabled = context.pairSelected and not context.atWar
    elseif internal == "truce" then
        enabled = context.pairSelected
    elseif internal == "peace" then
        enabled = context.pairSelected and (
            context.atWar or context.allied
            or (tonumber(context.relation.truceUntil) or 0) > 0
        )
    elseif internal == "alliance" then
        enabled = context.pairSelected and not context.allied
    elseif internal == "break_alliance" then
        enabled = context.pairSelected and context.allied
    elseif internal == "incident_minor"
        or internal == "incident_severe"
        or internal == "incident_killed"
        or internal == "incident_rescue"
        or internal == "recalculate"
    then
        enabled = context.pairSelected
    elseif internal == "check_relation"
        or internal == "reconcile_treaty"
    then
        enabled = context.pairSelected
    elseif internal == "telemetry_clear"
        or internal == "telemetry_toggle"
        or internal == "next_scenario"
        or internal == "run_scenario"
        or internal == "check_registry"
        or internal == "repair_indexes"
        or internal == "export_snapshot"
    then
        enabled = true
    elseif internal == "archive" then
        enabled = faction ~= nil
    elseif internal == "assign" then
        enabled = faction ~= nil and npc ~= nil
            and context.currentFactionID == nil
    elseif internal == "manage_player_members" then
        enabled = faction ~= nil
            and context.playerFactionID == faction.id
    elseif internal == "transfer" then
        enabled = faction ~= nil and npc ~= nil
            and context.currentFactionID ~= nil
            and not context.sameFaction
    elseif internal == "remove"
        or internal == "leader"
        or internal == "role"
        or internal == "rank"
    then
        enabled = context.sameFaction
    end
    return enabled
end

local function updateControl(self, index, button, context)
    local internal = CONTROLS[index].id
    local definition = CONTROLS[index]
    local visible = definition.views == nil
        or definition.views[self.viewMode] == true
    if isMobileVisibilityControl(internal) then
        visible = visible and context.isMobileFaction
    end
    button:setVisible(visible)
    button:setEnable(enabledForControl(internal, self, context))
    if internal == "telemetry_toggle"
        and button.setTitle
    then
        local titleKey = context.snapshot.telemetry
            and context.snapshot.telemetry.enabled
            and "UI_PNC_FactionDisableTelemetry"
            or "UI_PNC_FactionEnableTelemetry"
        local title = text(titleKey)
        if button.title ~= title then
            button:setTitle(title)
        end
    end
end

local function updateControls(self, context)
    for index, button in ipairs(self.controls) do
        updateControl(self, index, button, context)
    end
end

function ISPNCFactionDebugWindow:prerender()
    requestRefresh(self)
    local faction = self:getFaction()
    local npc = self:getNPC()
    local target = self:getTargetFaction()
    local currentFactionID = npc and npc.npc
        and npc.npc.affiliation
        and npc.npc.affiliation.factionID or nil
    local snapshot = ClientState.factionDebug or {}
    local context = {
        faction = faction,
        npc = npc,
        playerFactionID = snapshot.currentPlayerFactionID,
        pairSelected = faction ~= nil and target ~= nil
            and faction.id ~= target.id,
        relation = snapshot.relationForward or {},
        currentFactionID = currentFactionID,
        sameFaction = faction ~= nil
            and currentFactionID == faction.id,
        isMobileFaction = faction ~= nil
            and faction.faction ~= nil
            and faction.faction.mobile ~= nil
            and faction.faction.mobile.active == true,
        snapshot = snapshot,
    }
    context.atWar = context.relation.atWar == true
    context.allied = context.relation.allied == true
    updateControls(self, context)
    PsychopatzWindow.prerender(self)
end
