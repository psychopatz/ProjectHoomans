require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Factions/PNC_FactionDebugModel"

PNC.FactionDebugUI = PNC.FactionDebugUI or {}

local FactionUI = PNC.FactionDebugUI
local Model = PNC.FactionDebugModel
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function text(key)
    return getText and getText(key) or key
end

local CONTROLS = {
    { id = "refresh", titleKey = "UI_PNC_MonitorRefresh", variant = "quiet" },
    { id = "create_player_faction", titleKey = "UI_PNC_FactionCreatePlayer", variant = "success" },
    { id = "create_settler", titleKey = "UI_PNC_FactionCreateSettler", variant = "success" },
    { id = "create_looter", titleKey = "UI_PNC_FactionCreateLooter", variant = "danger" },
    { id = "create_trader", titleKey = "UI_PNC_FactionCreateTrader", variant = "default" },
    { id = "create_refugee", titleKey = "UI_PNC_FactionCreateRefugee", variant = "default" },
    { id = "assign", titleKey = "UI_PNC_FactionAssignNPC", variant = "success" },
    { id = "transfer", titleKey = "UI_PNC_FactionTransferNPC", variant = "default" },
    { id = "remove", titleKey = "UI_PNC_FactionRemoveNPC", variant = "danger" },
    { id = "leader", titleKey = "UI_PNC_FactionSetLeader", variant = "default" },
    { id = "role", titleKey = "UI_PNC_FactionNextRole", variant = "quiet" },
    { id = "rank", titleKey = "UI_PNC_FactionNextRank", variant = "quiet" },
    { id = "archive", titleKey = "UI_PNC_FactionArchive", variant = "danger" },
    { id = "war", titleKey = "UI_PNC_FactionDeclareWar", variant = "danger" },
    { id = "truce", titleKey = "UI_PNC_FactionStartTruce", variant = "quiet" },
    { id = "peace", titleKey = "UI_PNC_FactionMakePeace", variant = "success" },
    { id = "alliance", titleKey = "UI_PNC_FactionFormAlliance", variant = "success" },
    { id = "break_alliance", titleKey = "UI_PNC_FactionBreakAlliance", variant = "danger" },
    { id = "incident_minor", titleKey = "UI_PNC_FactionMinorAttack", variant = "quiet" },
    { id = "incident_severe", titleKey = "UI_PNC_FactionSevereAttack", variant = "danger" },
    { id = "incident_killed", titleKey = "UI_PNC_FactionMemberKilled", variant = "danger" },
    { id = "incident_rescue", titleKey = "UI_PNC_FactionMemberRescued", variant = "success" },
    { id = "recalculate", titleKey = "UI_PNC_FactionRecalculate", variant = "quiet" },
}

local function drawEntity(list, y, entry, alternate)
    local item = entry.item
    UI.DrawListSelection(
        list, y, list.itemheight,
        list.selected == entry.index, alternate
    )
    local text = Theme.colors.text
    local muted = Theme.colors.textMuted
    list:drawText(
        Layout.Ellipsize(
            item.label,
            UIFont.Small,
            list:getWidth() - 20
        ),
        10, y + 5,
        text.r, text.g, text.b, text.a,
        UIFont.Small
    )
    list:drawText(
        Layout.Ellipsize(
            item.detail or item.id,
            UIFont.Small,
            list:getWidth() - 20
        ),
        10, y + 24,
        muted.r, muted.g, muted.b, muted.a,
        UIFont.Small
    )
    return y + list.itemheight
end

local function drawDetail(list, y, entry, alternate)
    local item = entry.item
    local muted = Theme.colors.textMuted
    local color = Theme.colors[item.tone or "text"]
        or Theme.colors.text
    local labelWidth = math.min(
        150,
        math.floor(list:getWidth() * 0.34)
    )
    UI.DrawListSelection(
        list, y, list.itemheight, false, alternate
    )
    list:drawText(
        item.label,
        10, y + 6,
        muted.r, muted.g, muted.b, muted.a,
        UIFont.Small
    )
    list:drawText(
        Layout.Ellipsize(
            item.value,
            UIFont.Small,
            math.max(40, list:getWidth() - labelWidth - 24)
        ),
        12 + labelWidth, y + 6,
        color.r, color.g, color.b, color.a,
        UIFont.Small
    )
    return y + list.itemheight
end

ISPNCFactionDebugWindow =
    PsychopatzWindow:derive("ISPNCFactionDebugWindow")

function ISPNCFactionDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCFactionDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.factions = UI.CreateList(self, {
        itemHeight = Layout.Pixels(44, self.uiScale),
        doDrawItem = drawEntity,
    })
    self.targets = UI.CreateList(self, {
        itemHeight = Layout.Pixels(44, self.uiScale),
        doDrawItem = drawEntity,
    })
    self.npcs = UI.CreateList(self, {
        itemHeight = Layout.Pixels(44, self.uiScale),
        doDrawItem = drawEntity,
    })
    self.details = UI.CreateList(self, {
        itemHeight = Layout.Pixels(27, self.uiScale),
        doDrawItem = drawDetail,
    })
    self.controls = {}
    for _, definition in ipairs(CONTROLS) do
        local button = UI.CreateButton(self, {
            id = definition.id,
            title = text(definition.titleKey),
            target = self,
            onclick = ISPNCFactionDebugWindow.onAction,
            variant = definition.variant,
        })
        self.controls[#self.controls + 1] = button
    end
    self:requestResponsiveLayout(true)
    self:requestSnapshot()
end

function ISPNCFactionDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 28, bottom = 12 })
    local controls = Layout.Flow(
        self.controls,
        { x = rect.x, y = rect.y, width = rect.width },
        { scale = self.uiScale, minWidth = 86 }
    )
    local top = controls.bottom + Layout.Pixels(25, self.uiScale)
    local height = math.max(100, rect.y + rect.height - top)
    local gap = Layout.Pixels(8, self.uiScale)
    local listWidth = math.max(
        150,
        math.floor((rect.width - gap * 3) * 0.19)
    )
    self.layout = {
        faction = {
            x = rect.x, y = top,
            width = listWidth, height = height,
        },
        target = {
            x = rect.x + listWidth + gap, y = top,
            width = listWidth, height = height,
        },
        npc = {
            x = rect.x + listWidth * 2 + gap * 2, y = top,
            width = listWidth, height = height,
        },
        detail = {
            x = rect.x + listWidth * 3 + gap * 3,
            y = top,
            width = rect.width - listWidth * 3 - gap * 3,
            height = height,
        },
    }
    for widget, bounds in pairs({
        [self.factions] = self.layout.faction,
        [self.targets] = self.layout.target,
        [self.npcs] = self.layout.npc,
        [self.details] = self.layout.detail,
    }) do
        Layout.SetBounds(
            widget,
            bounds.x, bounds.y, bounds.width, bounds.height
        )
    end
end

function ISPNCFactionDebugWindow:getFaction()
    local entry = self.factions and self.factions:getItem()
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
    self.targets:clear()
    for _, item in ipairs(Model.BuildFactionItems(snapshot)) do
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
    self.details:clear()
    for _, item in ipairs(Model.BuildRows(
        snapshot,
        ClientState.factionDebugAuthorized,
        ClientState.factionDebugReason
    )) do
        self.details:addItem(item.label, item)
    end
    self.lastReceiveAt =
        tonumber(ClientState.lastFactionDebugReceiveAt)
        or PNC.Core.Now()
end

local function nextValue(values, current)
    local ordered = {}
    for key, enabled in pairs(values or {}) do
        if enabled == true then ordered[#ordered + 1] = key end
    end
    table.sort(ordered)
    if #ordered == 0 then return nil end
    for index, value in ipairs(ordered) do
        if value == current then
            return ordered[(index % #ordered) + 1]
        end
    end
    return ordered[1]
end

function ISPNCFactionDebugWindow:onAction(button)
    local internal = button.internal
    local faction = self:getFaction()
    local npc = self:getNPC()
    local target = self:getTargetFaction()
    if internal == "refresh" then
        self:requestSnapshot()
        return
    end
    local payload = {
        factionID = faction and faction.id,
        npcID = npc and npc.id,
        targetFactionID = target and target.id,
    }
    if internal == "create_player_faction" then
        payload.factionAction = internal
    elseif string.sub(internal, 1, 7) == "create_" then
        payload.factionAction = "create"
        payload.archetypeID = string.sub(internal, 8)
    else
        payload.factionAction = internal
    end
    if internal == "role" and faction and npc then
        local archetype = PNC.FactionArchetypes.Get(
            faction.faction.archetypeID
        )
        payload.role = nextValue(
            archetype and archetype.allowedRoles,
            npc.npc.affiliation and npc.npc.affiliation.role
        )
    elseif internal == "rank" and npc then
        payload.rank = nextValue(
            PNC.FactionConstants.VALID_RANKS,
            npc.npc.affiliation and npc.npc.affiliation.rank
        )
    end
    PNC.Client.SendDebug("faction_debug_action", payload)
end

function ISPNCFactionDebugWindow:selectionSignature()
    local faction = self:getFaction()
    local npc = self:getNPC()
    local target = self:getTargetFaction()
    return tostring(faction and faction.id or "") .. "|"
        .. tostring(target and target.id or "") .. "|"
        .. tostring(npc and npc.id or "")
end

function ISPNCFactionDebugWindow:prerender()
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
    local faction = self:getFaction()
    local npc = self:getNPC()
    local target = self:getTargetFaction()
    local currentFactionID = npc and npc.npc
        and npc.npc.affiliation
        and npc.npc.affiliation.factionID or nil
    local sameFaction = faction ~= nil
        and currentFactionID == faction.id
    local snapshot = ClientState.factionDebug or {}
    local playerFactionID = snapshot.currentPlayerFactionID
    local pairSelected = faction ~= nil and target ~= nil
        and faction.id ~= target.id
    local relation = snapshot.relationForward or {}
    local atWar = relation.atWar == true
    local allied = relation.allied == true
    for index, button in ipairs(self.controls) do
        local internal = CONTROLS[index].id
        local create = string.sub(internal, 1, 7) == "create_"
            and internal ~= "create_player_faction"
        local enabled = internal == "refresh" or create
        if internal == "create_player_faction" then
            enabled = playerFactionID == nil
        elseif internal == "war" then
            enabled = pairSelected and not atWar
        elseif internal == "truce" then
            enabled = pairSelected
        elseif internal == "peace" then
            enabled = pairSelected and (
                atWar or allied
                or (tonumber(relation.truceUntil) or 0) > 0
            )
        elseif internal == "alliance" then
            enabled = pairSelected and not allied
        elseif internal == "break_alliance" then
            enabled = pairSelected and allied
        elseif internal == "incident_minor"
            or internal == "incident_severe"
            or internal == "incident_killed"
            or internal == "incident_rescue"
            or internal == "recalculate"
        then
            enabled = pairSelected
        elseif internal == "archive" then
            enabled = faction ~= nil
        elseif internal == "assign" then
            enabled = faction ~= nil and npc ~= nil
                and currentFactionID == nil
        elseif internal == "transfer" then
            enabled = faction ~= nil and npc ~= nil
                and currentFactionID ~= nil
                and not sameFaction
        elseif internal == "remove"
            or internal == "leader"
            or internal == "role"
            or internal == "rank"
        then
            enabled = sameFaction
        end
        button:setEnable(enabled)
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCFactionDebugWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then return end
    UI.DrawSectionTitle(
        self, "Persistent factions",
        self.layout.faction.x,
        self.layout.faction.y - Layout.Pixels(21, self.uiScale),
        self.layout.faction.width
    )
    UI.DrawSectionTitle(
        self, "Target faction",
        self.layout.target.x,
        self.layout.target.y - Layout.Pixels(21, self.uiScale),
        self.layout.target.width
    )
    UI.DrawSectionTitle(
        self, "NPC affiliation",
        self.layout.npc.x,
        self.layout.npc.y - Layout.Pixels(21, self.uiScale),
        self.layout.npc.width
    )
    UI.DrawSectionTitle(
        self, "Faction details and members",
        self.layout.detail.x,
        self.layout.detail.y - Layout.Pixels(21, self.uiScale),
        self.layout.detail.width
    )
end

function ISPNCFactionDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    FactionUI.instance = nil
end

function ISPNCFactionDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(
        x, y, width, height, options
    )
    setmetatable(object, self)
    self.__index = self
    return object
end

function FactionUI.Open()
    local window = FactionUI.instance
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        return nil
    end
    if not window then
        window = UI.NewWindow(ISPNCFactionDebugWindow, {
            title = getText("UI_PNC_FactionInspectorTitle"),
            resizable = true,
            responsiveSpec = {
                width = 1280,
                height = 800,
                minWidth = 820,
                minHeight = 540,
                maxWidth = 1500,
                maxHeight = 960,
            },
        })
        window:initialise()
        window:instantiate()
        FactionUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestSnapshot()
    return window
end

function FactionUI.Toggle()
    local window = FactionUI.instance
    if window and window:getIsVisible() then
        window:close()
        return nil
    end
    return FactionUI.Open()
end

local function onResetLua()
    if FactionUI.instance then FactionUI.instance:close() end
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(onResetLua)
end

return FactionUI
