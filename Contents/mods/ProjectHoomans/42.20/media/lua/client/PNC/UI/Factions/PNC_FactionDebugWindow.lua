require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISTextEntryBox"
require "PNC/UI/Factions/PNC_FactionDebugModel"
require "PNC/UI/Factions/PNC_FactionDebugOverlay"
require "PNC/UI/Factions/PNC_FactionEmblemEditor"
require "PNC/UI/Factions/PNC_FactionMemberWindow"

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

local function views(first, second)
    local values = {}
    if first then values[first] = true end
    if second then values[second] = true end
    return values
end

local CONTROLS = {
    { id = "refresh", titleKey = "UI_PNC_MonitorRefresh", variant = "quiet" },
    { id = "overlay", titleKey = "UI_PNC_FactionToggleOverlay", variant = "quiet" },
    { id = "view_overview", titleKey = "UI_PNC_FactionViewOverview", variant = "quiet" },
    { id = "view_diplomacy", titleKey = "UI_PNC_FactionViewDiplomacy", variant = "quiet" },
    { id = "view_members", titleKey = "UI_PNC_FactionViewMembers", variant = "quiet" },
    { id = "view_diagnostics", titleKey = "UI_PNC_FactionViewDiagnostics", variant = "quiet" },
    { id = "create_player_faction", titleKey = "UI_PNC_FactionCreatePlayer", variant = "success", views = views("overview") },
    { id = "edit_emblem", titleKey = "UI_PNC_FactionEditEmblem", variant = "default", views = views("overview") },
    { id = "create_settler", titleKey = "UI_PNC_FactionCreateSettler", variant = "success", views = views("overview") },
    { id = "create_looter", titleKey = "UI_PNC_FactionCreateLooter", variant = "danger", views = views("overview") },
    { id = "create_looter_group", titleKey = "UI_PNC_FactionCreateLooterGroup", variant = "danger", views = views("overview") },
    { id = "create_trader", titleKey = "UI_PNC_FactionCreateTrader", variant = "default", views = views("overview") },
    { id = "create_refugee", titleKey = "UI_PNC_FactionCreateRefugee", variant = "default", views = views("overview") },
    { id = "generate_group", titleKey = "UI_PNC_FactionGenerateGroup", variant = "success", views = views("overview") },
    { id = "mobile_path_mode", titleKey = "UI_PNC_FactionMobilePathMode", variant = "quiet", views = views("overview") },
    { id = "mobile_relocate", titleKey = "UI_PNC_FactionMobileRelocate", variant = "quiet", views = views("overview") },
    { id = "population_label", titleKey = "UI_PNC_FactionGroupSize", variant = "quiet", views = views("overview") },
    { id = "presence_mode", titleKey = "UI_PNC_FactionPresenceMode", variant = "quiet", views = views("overview") },
    { id = "archive", titleKey = "UI_PNC_FactionArchive", variant = "danger", views = views("overview") },
    { id = "assign", titleKey = "UI_PNC_FactionAssignNPC", variant = "success", views = views("members") },
    { id = "manage_player_members", titleKey = "UI_PNC_FactionManageMembers", variant = "success", views = views("members") },
    { id = "transfer", titleKey = "UI_PNC_FactionTransferNPC", variant = "default", views = views("members") },
    { id = "remove", titleKey = "UI_PNC_FactionRemoveNPC", variant = "danger", views = views("members") },
    { id = "leader", titleKey = "UI_PNC_FactionSetLeader", variant = "default", views = views("members") },
    { id = "role", titleKey = "UI_PNC_FactionNextRole", variant = "quiet", views = views("members") },
    { id = "rank", titleKey = "UI_PNC_FactionNextRank", variant = "quiet", views = views("members") },
    { id = "war", titleKey = "UI_PNC_FactionDeclareWar", variant = "danger", views = views("diplomacy") },
    { id = "truce", titleKey = "UI_PNC_FactionStartTruce", variant = "quiet", views = views("diplomacy") },
    { id = "peace", titleKey = "UI_PNC_FactionMakePeace", variant = "success", views = views("diplomacy") },
    { id = "alliance", titleKey = "UI_PNC_FactionFormAlliance", variant = "success", views = views("diplomacy") },
    { id = "break_alliance", titleKey = "UI_PNC_FactionBreakAlliance", variant = "danger", views = views("diplomacy") },
    { id = "incident_minor", titleKey = "UI_PNC_FactionMinorAttack", variant = "quiet", views = views("diplomacy") },
    { id = "incident_severe", titleKey = "UI_PNC_FactionSevereAttack", variant = "danger", views = views("diplomacy") },
    { id = "incident_killed", titleKey = "UI_PNC_FactionMemberKilled", variant = "danger", views = views("diplomacy") },
    { id = "incident_rescue", titleKey = "UI_PNC_FactionMemberRescued", variant = "success", views = views("diplomacy") },
    { id = "recalculate", titleKey = "UI_PNC_FactionRecalculate", variant = "quiet", views = views("diplomacy") },
    { id = "check_relation", titleKey = "UI_PNC_FactionCheckRelation", variant = "quiet", views = views("diplomacy", "diagnostics") },
    { id = "reconcile_treaty", titleKey = "UI_PNC_FactionReconcileTreaty", variant = "quiet", views = views("diplomacy", "diagnostics") },
    { id = "telemetry_toggle", titleKey = "UI_PNC_FactionEnableTelemetry", variant = "success", views = views("diagnostics") },
    { id = "telemetry_clear", titleKey = "UI_PNC_FactionClearTelemetry", variant = "danger", views = views("diagnostics") },
    { id = "next_scenario", titleKey = "UI_PNC_FactionNextScenario", variant = "quiet", views = views("diagnostics") },
    { id = "run_scenario", titleKey = "UI_PNC_FactionRunScenario", variant = "success", views = views("diagnostics") },
    { id = "check_registry", titleKey = "UI_PNC_FactionCheckRegistry", variant = "quiet", views = views("diagnostics") },
    { id = "repair_indexes", titleKey = "UI_PNC_FactionRepairIndexes", variant = "danger", views = views("diagnostics") },
    { id = "export_snapshot", titleKey = "UI_PNC_FactionExportSnapshot", variant = "default", views = views("diagnostics") },
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
    self.dashboard = PNC.FactionDebugOverlay.NewDashboard(
        0, 0, 430, 492
    )
    self:addChild(self.dashboard)
    self.controls = {}
    self.scenarioIndex = 1
    self.groupSize = 4
    self.presenceMode = "auto"
    self.mobilePathMode = "random"
    self.viewMode = "overview"
    for _, definition in ipairs(CONTROLS) do
        local title = text(definition.titleKey)
        if definition.id == "presence_mode" then
            title = title .. ": " .. self.presenceMode
        elseif definition.id == "mobile_path_mode" then
            title = title .. ": " .. self.mobilePathMode
        end
        local button = UI.CreateButton(self, {
            id = definition.id,
            title = title,
            target = self,
            onclick = ISPNCFactionDebugWindow.onAction,
            variant = definition.variant,
        })
        self.controls[#self.controls + 1] = button
    end
    self.groupSizeEntry = ISTextEntryBox:new(
        tostring(self.groupSize),
        0,
        0,
        64,
        26
    )
    self.groupSizeEntry:initialise()
    self.groupSizeEntry:instantiate()
    self.groupSizeEntry:setOnlyNumbers(true)
    self.groupSizeEntry.psychopatzPreferredWidth = 64
    self.groupSizeEntry.tooltip =
        text("UI_PNC_FactionGroupSizeTooltip")
    self:addChild(self.groupSizeEntry)
    self:requestResponsiveLayout(true)
    self:requestSnapshot()
end

function ISPNCFactionDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 28, bottom = 12 })
    local visibleControls = {}
    for index, button in ipairs(self.controls) do
        local definition = CONTROLS[index]
        local visible = definition.views == nil
            or definition.views[self.viewMode] == true
        button:setVisible(visible)
        if visible then
            visibleControls[#visibleControls + 1] = button
            if definition.id == "population_label" then
                self.groupSizeEntry:setVisible(true)
                visibleControls[#visibleControls + 1] =
                    self.groupSizeEntry
            end
        end
    end
    if self.viewMode ~= "overview" then
        self.groupSizeEntry:setVisible(false)
    end
    local controls = Layout.Flow(
        visibleControls,
        { x = rect.x, y = rect.y, width = rect.width },
        { scale = self.uiScale, minWidth = 76 }
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
        [self.dashboard] = self.layout.detail,
    }) do
        Layout.SetBounds(
            widget,
            bounds.x, bounds.y, bounds.width, bounds.height
        )
    end
    self.dashboard:setVisible(self.viewMode == "overview")
    self.details:setVisible(self.viewMode ~= "overview")
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
    if internal == "overlay" then
        local visible = PNC.FactionDebugOverlay.Toggle()
        if visible then
            PNC.FactionDebugOverlay.SetSelection(
                faction and faction.id,
                target and target.id,
                npc and npc.id
            )
        end
        return
    end
    if internal == "manage_player_members" then
        PNC.FactionMemberUI.Open()
        return
    end
    if internal == "create_player_faction"
        or internal == "edit_emblem"
    then
        local snapshot = ClientState.factionDebug or {}
        local selected = faction and faction.faction or nil
        PNC.FactionEmblemEditor.Open({
            archetypeID = selected
                and selected.archetypeID or "settler",
            emblem = internal == "edit_emblem"
                and selected and selected.emblem or nil,
            seed = selected and selected.id
                or snapshot.currentPlayerKey
                or "player_faction",
            context = {
                action = internal,
                groupSize = tonumber(
                    self.groupSizeEntry
                        and self.groupSizeEntry:getText()
                        or self.groupSize
                ) or 4,
                presenceMode = self.presenceMode,
            },
            onSave = function(emblem, context)
                PNC.Client.SendDebug(
                    "faction_debug_action",
                    {
                        factionAction =
                            context.action == "edit_emblem"
                                and "set_emblem"
                                or "create_player_faction",
                        factionID = selected and selected.id,
                        emblem = emblem,
                        groupSize = math.max(
                            1,
                            math.min(
                                24,
                                math.floor(
                                    context.groupSize or 4
                                )
                            )
                        ),
                        presenceMode = context.presenceMode,
                    }
                )
            end,
        })
        return
    end
    if string.sub(internal, 1, 5) == "view_" then
        local view = string.sub(internal, 6)
        if Model.Views[view] then
            self.viewMode = view
            self:refreshSnapshot()
            self:requestResponsiveLayout(true)
        end
        return
    end
    if internal == "next_scenario" then
        local names = ClientState.factionDebug
            and ClientState.factionDebug.scenarioNames or {}
        if #names > 0 then
            self.scenarioIndex =
                ((tonumber(self.scenarioIndex) or 1) % #names) + 1
            self.scenarioName = names[self.scenarioIndex]
            if button.setTitle then
                button:setTitle(
                    text("UI_PNC_FactionNextScenario")
                        .. ": " .. self.scenarioName
                )
                self:requestResponsiveLayout(true)
            end
        end
        return
    end
    if internal == "presence_mode" then
        local modes = { "auto", "abstract", "live" }
        local nextIndex = 1
        for index, mode in ipairs(modes) do
            if mode == self.presenceMode then
                nextIndex = (index % #modes) + 1
                break
            end
        end
        self.presenceMode = modes[nextIndex]
        button:setTitle(
            text("UI_PNC_FactionPresenceMode")
                .. ": " .. self.presenceMode
        )
        self:requestResponsiveLayout(true)
        return
    end
    if internal == "mobile_path_mode" then
        local modes = { "random", "player" }
        local nextIndex = 1
        for index, mode in ipairs(modes) do
            if mode == self.mobilePathMode then
                nextIndex = (index % #modes) + 1
                break
            end
        end
        self.mobilePathMode = modes[nextIndex]
        button:setTitle(
            text("UI_PNC_FactionMobilePathMode")
                .. ": " .. self.mobilePathMode
        )
        if faction and faction.faction
            and faction.faction.mobile
            and faction.faction.mobile.active == true
        then
            PNC.Client.SendDebug(
                "faction_debug_action",
                {
                    factionAction = "mobile_path_mode",
                    factionID = faction.id,
                    mobilePathMode = self.mobilePathMode,
                }
            )
        end
        self:requestResponsiveLayout(true)
        return
    end
    local enteredGroupSize = tonumber(
        self.groupSizeEntry
            and self.groupSizeEntry:getText()
            or self.groupSize
    )
    enteredGroupSize = math.max(
        1,
        math.min(24, math.floor(enteredGroupSize or 4))
    )
    self.groupSize = enteredGroupSize
    if self.groupSizeEntry then
        self.groupSizeEntry:setText(
            tostring(enteredGroupSize)
        )
    end
    local payload = {
        factionID = faction and faction.id,
        npcID = npc and npc.id,
        targetFactionID = target and target.id,
        groupSize = enteredGroupSize,
        presenceMode = self.presenceMode,
        mobilePathMode = self.mobilePathMode,
    }
    if internal == "create_player_faction" then
        payload.factionAction = internal
    elseif internal == "create_looter_group" then
        payload.factionAction = "create"
        payload.archetypeID = "looter"
        payload.creationKind = "mobile_group"
    elseif internal == "create_trader" then
        payload.factionAction = "create"
        payload.archetypeID = "trader"
        payload.creationKind = "mobile_group"
    elseif internal == "create_refugee" then
        payload.factionAction = "create"
        payload.archetypeID = "refugee"
        payload.creationKind = "mobile_group"
    elseif internal == "mobile_relocate" then
        payload.factionAction = "mobile_relocate"
    elseif internal == "generate_group" then
        payload.factionAction = "generate_group"
    elseif internal == "mobile_path_mode" then
        payload.factionAction = "mobile_path_mode"
    elseif string.sub(internal, 1, 7) == "create_" then
        payload.factionAction = "create"
        payload.archetypeID = string.sub(internal, 8)
    else
        payload.factionAction = internal
    end
    if internal == "run_scenario" then
        local names = ClientState.factionDebug
            and ClientState.factionDebug.scenarioNames or {}
        payload.scenarioName = self.scenarioName
            or names[self.scenarioIndex or 1]
            or "single_minor_attack"
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
    local isMobileFaction = faction ~= nil
        and faction.faction.mobile ~= nil
        and faction.faction.mobile.active == true
    for index, button in ipairs(self.controls) do
        local internal = CONTROLS[index].id
        local definition = CONTROLS[index]
        local visible = definition.views == nil
            or definition.views[self.viewMode] == true
        if internal == "mobile_path_mode"
            or internal == "mobile_relocate"
        then
            visible = visible and isMobileFaction
        end
        button:setVisible(visible)
        local create = string.sub(internal, 1, 7) == "create_"
            and internal ~= "create_player_faction"
        local enabled = internal == "refresh"
            or internal == "overlay" or create
        if string.sub(internal, 1, 5) == "view_" then
            enabled = string.sub(internal, 6) ~= self.viewMode
        end
        if internal == "create_player_faction" then
            enabled = playerFactionID == nil
        elseif internal == "edit_emblem" then
            enabled = faction ~= nil
                and playerFactionID == faction.id
                and faction.faction.ownerPlayerKey ~= nil
        elseif internal == "generate_group" then
            enabled = faction ~= nil
                and faction.faction.status == "active"
        elseif internal == "mobile_path_mode" then
            enabled = isMobileFaction
        elseif internal == "mobile_relocate" then
            enabled = isMobileFaction
        elseif internal == "population_label" then
            enabled = false
        elseif internal == "presence_mode"
        then
            enabled = true
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
        elseif internal == "check_relation"
            or internal == "reconcile_treaty"
        then
            enabled = pairSelected
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
                and currentFactionID == nil
        elseif internal == "manage_player_members" then
            enabled = faction ~= nil
                and playerFactionID == faction.id
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
        if internal == "telemetry_toggle"
            and button.setTitle
        then
            local titleKey = snapshot.telemetry
                and snapshot.telemetry.enabled
                and "UI_PNC_FactionDisableTelemetry"
                or "UI_PNC_FactionEnableTelemetry"
            local title = text(titleKey)
            if button.title ~= title then
                button:setTitle(title)
            end
        end
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCFactionDebugWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then return end
    UI.DrawSectionTitle(
        self, text("UI_PNC_FactionSectionPersistent"),
        self.layout.faction.x,
        self.layout.faction.y - Layout.Pixels(21, self.uiScale),
        self.layout.faction.width
    )
    UI.DrawSectionTitle(
        self, text("UI_PNC_FactionSectionTarget"),
        self.layout.target.x,
        self.layout.target.y - Layout.Pixels(21, self.uiScale),
        self.layout.target.width
    )
    UI.DrawSectionTitle(
        self, text("UI_PNC_FactionSectionNPC"),
        self.layout.npc.x,
        self.layout.npc.y - Layout.Pixels(21, self.uiScale),
        self.layout.npc.width
    )
    UI.DrawSectionTitle(
        self, text(
            "UI_PNC_FactionSection"
                .. string.upper(string.sub(
                    self.viewMode, 1, 1
                ))
                .. string.sub(self.viewMode, 2)
        ),
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
        local screenWidth = getCore and getCore()
            and getCore():getScreenWidth() or 1280
        local screenHeight = getCore and getCore()
            and getCore():getScreenHeight() or 800
        window = UI.NewWindow(ISPNCFactionDebugWindow, {
            title = getText("UI_PNC_FactionInspectorTitle"),
            resizable = true,
            responsiveSpec = {
                width = math.min(1280, screenWidth - 24),
                height = math.min(800, screenHeight - 40),
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
