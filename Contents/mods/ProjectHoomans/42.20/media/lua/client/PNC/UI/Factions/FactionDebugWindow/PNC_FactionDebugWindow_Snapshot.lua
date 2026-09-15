-- Faction debug window snapshot and selection state.


PNC = PNC or {}
PNC.FactionDebugUI = PNC.FactionDebugUI or {}

local FactionUI = PNC.FactionDebugUI
local Internal = FactionUI.Internal or {}
FactionUI.Internal = Internal
local Model = Internal.Model
local ClientState = Internal.ClientState
local CONTROLS = Internal.Controls
local MOBILE_FILTER_CONTROL_MAP = Internal.MobileFilterControlMap
local UI = Internal.UI
local text = Internal.Text
function ISPNCFactionDebugWindow:getFaction()
    local list = self.viewMode == "mobile"
        and self.mobileGroups or self.factions
    local entry = list and list:getItem()
    -- Keep the list wrapper here.  The rest of this window uses
    -- faction.faction for the serialized faction payload, while the
    -- wrapper itself supplies the stable selection id/label.
    return entry and entry.item or nil
end

function ISPNCFactionDebugWindow:getNPC()
    local entry = self.npcs and self.npcs:getItem()
    return entry and entry.item or nil
end

function ISPNCFactionDebugWindow:getTargetFaction()
    local entry = self.targets and self.targets:getItem()
    return entry and entry.item or nil
end

function ISPNCFactionDebugWindow:requestSnapshot()
    local faction = self:getFaction()
    local npc = self:getNPC()
    local target = self:getTargetFaction()
    if PNC.Client and PNC.Client.RequestFactionDebug then
        PNC.Client.RequestFactionDebug(
            faction and faction.id,
            npc and npc.id,
            target and target.id
        )
    end
    self.lastRequestAt = PNC.Core.Now()
end

function ISPNCFactionDebugWindow:refreshMobileFilterControls(snapshot)
    local counts = Model.BuildMobilePoolCounts(snapshot)
    for index, definition in ipairs(CONTROLS) do
        local filter = MOBILE_FILTER_CONTROL_MAP[definition.id]
        local button = self.controls[index]
        if filter and button then
            local count = Model.MobileFilterCount(counts, filter)
            local title = Model.MobileFilterLabel(filter)
                .. " (" .. tostring(count) .. ")"
            if button.setTitle then
                button:setTitle(title)
            else
                button.title = title
            end
            UI.SetButtonVariant(
                button,
                filter == self.mobileFilter and "selected" or "quiet"
            )
        end
    end
end

local function restoreSelection(list, id)
    if not id then return end
    for index, entry in ipairs(list.items or {}) do
        if entry.item and entry.item.id == id then
            list.selected = index
            return
        end
    end
end

function ISPNCFactionDebugWindow:refreshSnapshot()
    local oldFaction = self:getFaction()
    local oldNPC = self:getNPC()
    local oldTarget = self:getTargetFaction()
    local snapshot = ClientState.factionDebug
    self.factions:clear()
    for _, item in ipairs(Model.BuildFactionItems(snapshot)) do
        self.factions:addItem(item.label, item)
    end
    restoreSelection(
        self.factions,
        snapshot and snapshot.selectedFactionID
            or oldFaction and oldFaction.id
    )
    if #self.factions.items > 0
        and (tonumber(self.factions.selected) or 0) < 1
    then
        self.factions.selected = 1
    end
    self.mobileGroups:clear()
    for _, item in ipairs(Model.BuildMobileItems(
        snapshot, self.mobileFilter
    )) do
        self.mobileGroups:addItem(item.label, item)
    end
    self:refreshMobileFilterControls(snapshot)
    restoreSelection(
        self.mobileGroups,
        snapshot and snapshot.selectedFactionID
            or oldFaction and oldFaction.id
    )
    if #self.mobileGroups.items > 0
        and (tonumber(self.mobileGroups.selected) or 0) < 1
    then
        self.mobileGroups.selected = 1
    end
    self.targets:clear()
    for _, item in ipairs(
        Model.BuildTargetFactionItems(snapshot)
    ) do
        self.targets:addItem(item.label, item)
    end
    restoreSelection(
        self.targets,
        snapshot and snapshot.selectedTargetFactionID
            or oldTarget and oldTarget.id
    )
    if #self.targets.items > 0
        and (tonumber(self.targets.selected) or 0) < 1
    then
        local selectedSource = self:getFaction()
        for index, entry in ipairs(self.targets.items) do
            if not selectedSource
                or entry.item.id ~= selectedSource.id
            then
                self.targets.selected = index
                break
            end
        end
    end
    self.npcs:clear()
    for _, item in ipairs(Model.BuildNPCItems(snapshot)) do
        self.npcs:addItem(item.label, item)
    end
    restoreSelection(
        self.npcs,
        snapshot and snapshot.selectedNPCID
            or oldNPC and oldNPC.id
    )
    if #self.npcs.items > 0
        and (tonumber(self.npcs.selected) or 0) < 1
    then
        self.npcs.selected = 1
    end
    local selectedFaction = self:getFaction()
    if selectedFaction and selectedFaction.faction
        and selectedFaction.faction.mobile
        and selectedFaction.faction.mobile.active == true
    then
        self.mobileControlMode = selectedFaction.faction.mobile.controlMode
            or self.mobileControlMode
        self.mobilePathMode = selectedFaction.faction.mobile.pathMode
            or self.mobilePathMode
    end
    for index, definition in ipairs(CONTROLS) do
        if definition.id == "mobile_control_mode"
            or definition.id == "mobile_path_mode"
        then
            local value = definition.id == "mobile_control_mode"
                and self.mobileControlMode or self.mobilePathMode
            self.controls[index]:setTitle(
                text(definition.titleKey) .. ": " .. tostring(value)
            )
        end
    end
    self.details:clear()
    for _, item in ipairs(Model.BuildGUIRows(
        snapshot,
        ClientState.factionDebugAuthorized,
        ClientState.factionDebugReason,
        self.viewMode
    )) do
        self.details:addItem(item.label, item)
    end
    self.lastReceiveAt =
        tonumber(ClientState.lastFactionDebugReceiveAt)
        or PNC.Core.Now()
end
function ISPNCFactionDebugWindow:selectionSignature()
    local faction = self:getFaction()
    local npc = self:getNPC()
    local target = self:getTargetFaction()
    return tostring(faction and faction.id or "") .. "|"
        .. tostring(target and target.id or "") .. "|"
        .. tostring(npc and npc.id or "")
end
