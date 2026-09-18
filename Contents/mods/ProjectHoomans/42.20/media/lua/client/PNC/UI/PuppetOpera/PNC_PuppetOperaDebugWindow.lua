-- Standalone Puppet Opera scene builder.
--
-- The builder is intentionally separate from Player Animation Lab and NPC
-- Presentation Lab.  It reuses their generated catalog data, while playback
-- still goes through Puppet Opera's owned session adapters.

require "ISUI/ISTabPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/PuppetOpera/PNC_PuppetOpera_Client"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaLayoutTab"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaAnimationTab"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaBeatsTab"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaTraceTab"

PNC = PNC or {}
PNC.PuppetOperaDebugWindow = PNC.PuppetOperaDebugWindow or {}

local WindowAPI = PNC.PuppetOperaDebugWindow
local Model = PNC.PuppetOperaDebugModel
local Client = PNC.PuppetOpera.Client
local UI = PsychopatzCore.UI
local Layout = UI.Layout

local function tr(key, fallback)
    if PNC.Translation and PNC.Translation.GetKey then
        local value = PNC.Translation.GetKey(key)
        if value and value ~= key then return value end
    end
    return fallback or key
end

local TEXT_TITLE = tr("UI_PNC_PuppetOpera_Title", "Puppet Opera Scene Builder")
local TEXT_DESCRIPTION = tr(
    "UI_PNC_PuppetOpera_Description",
    "Build a multi-actor scene from existing player and NPC animation routes"
)
local TEXT_NO_ACTOR = tr(
    "UI_PNC_PuppetOpera_SelectActorSlot",
    "Select actor slot"
)

local function setComboSelection(combo, selected)
    combo.selected = tonumber(selected) or 1
end

ISPNCPuppetOperaDebugWindow = PsychopatzWindow:derive(
    "ISPNCPuppetOperaDebugWindow")

function ISPNCPuppetOperaDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCPuppetOperaDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.model = Model
    self.loopEnabled = false
    self.editorStatus = nil
    self.refreshCounter = 0

    self.blueprintCombo = ISComboBox:new(0, 0, 1, 1, self,
        ISPNCPuppetOperaDebugWindow.onBlueprintChanged)
    self.blueprintCombo:initialise()
    self.blueprintCombo:instantiate()
    self:addChild(self.blueprintCombo)

    self.actorCombo = ISComboBox:new(0, 0, 1, 1, self,
        ISPNCPuppetOperaDebugWindow.onActorChanged)
    self.actorCombo:initialise()
    self.actorCombo:instantiate()
    self:addChild(self.actorCombo)

    self.topButtons = {}
    for _, definition in ipairs({
        { "create", "UI_PNC_PuppetOpera_CreateNew", "CREATE NEW", "quiet" },
        { "duplicate", "UI_PNC_PuppetOpera_Duplicate", "DUPLICATE", "quiet" },
        { "save", "UI_PNC_PuppetOpera_SaveDraft", "SAVE DRAFT", "selected" },
        { "reset", "UI_PNC_PuppetOpera_ResetDraft", "RESET DRAFT", "quiet" },
    }) do
        local button = UI.CreateButton(self, {
            id = definition[1],
            title = tr(definition[2], definition[3]),
            target = self,
            onclick = UI.ButtonCallback(function(clicked)
                return self:onTopAction(clicked)
            end),
            variant = definition[4],
        })
        self.topButtons[#self.topButtons + 1] = button
    end

    self.tabPanel = ISTabPanel:new(0, 0, 1, 1)
    self.tabPanel:initialise()
    self.tabPanel:instantiate()
    self.tabPanel.tabPadX = Layout.Pixels(10, self.uiScale)
    self.tabPanel.equalTabWidth = false
    self.tabPanel.allowDraggingTabs = false
    self.tabPanel.allowTornOffTabs = false
    self:addChild(self.tabPanel)

    self.layoutTab = ISPNCPuppetOperaLayoutTab:new(0, 0, 1, 1)
    self.layoutTab:initialise()
    self.layoutTab:instantiate()
    self.tabPanel:addView(
        tr("UI_PNC_PuppetOpera_AnchorGrid", "Layout / anchors"),
        self.layoutTab
    )

    self.playerAnimationTab = ISPNCPuppetOperaAnimationTab:new(0, 0, 1, 1)
    self.playerAnimationTab:initialise()
    self.playerAnimationTab:instantiate()
    self.tabPanel:addView(
        tr("UI_PNC_PuppetOpera_PlayerAnimations", "Player animations"),
        self.playerAnimationTab
    )

    self.npcAnimationTab = ISPNCPuppetOperaAnimationTab:new(0, 0, 1, 1)
    self.npcAnimationTab:initialise()
    self.npcAnimationTab:instantiate()
    self.tabPanel:addView(
        tr("UI_PNC_PuppetOpera_NPCAnimations", "NPC animations"),
        self.npcAnimationTab
    )

    self.beatsTab = ISPNCPuppetOperaBeatsTab:new(0, 0, 1, 1)
    self.beatsTab:initialise()
    self.beatsTab:instantiate()
    self.tabPanel:addView(
        tr("UI_PNC_PuppetOpera_Beats", "Beats"),
        self.beatsTab
    )

    self.traceTab = ISPNCPuppetOperaTraceTab:new(0, 0, 1, 1)
    self.traceTab:initialise()
    self.traceTab:instantiate()
    self.tabPanel:addView(
        tr("UI_PNC_PuppetOpera_Trace", "Trace"),
        self.traceTab
    )
    self.tabDefinitions = {
        {
            key = "layout",
            name = tr("UI_PNC_PuppetOpera_AnchorGrid", "Layout / anchors"),
            view = self.layoutTab,
        },
        {
            key = "player",
            name = tr("UI_PNC_PuppetOpera_PlayerAnimations", "Player animations"),
            view = self.playerAnimationTab,
        },
        {
            key = "npc",
            name = tr("UI_PNC_PuppetOpera_NPCAnimations", "NPC animations"),
            view = self.npcAnimationTab,
        },
        {
            key = "beats",
            name = tr("UI_PNC_PuppetOpera_Beats", "Beats"),
            view = self.beatsTab,
        },
        {
            key = "trace",
            name = tr("UI_PNC_PuppetOpera_Trace", "Trace"),
            view = self.traceTab,
        },
    }
    self.visibleTabKeys = {
        layout = true,
        player = true,
        npc = true,
        beats = true,
        trace = true,
    }

    self.layoutTab:setContext(self)
    self.playerAnimationTab:setContext(self, "player")
    self.npcAnimationTab:setContext(self, "npc")
    self.beatsTab:setContext(self)
    self.traceTab:setContext(self)

    self.controls = {}
    for _, definition in ipairs({
        { "play", "UI_PNC_PuppetOpera_Play", "Play", "selected" },
        { "replay", "UI_PNC_PuppetOpera_Replay", "Replay", "quiet" },
        { "loop", "UI_PNC_PuppetOpera_Loop", "Loop: OFF", "quiet" },
        { "stop", "UI_PNC_PuppetOpera_StopRestore", "Stop / Restore", "danger" },
        { "trace", "UI_PNC_PuppetOpera_DumpTrace", "Dump trace", "quiet" },
        { "clear", "UI_PNC_PuppetOpera_ClearStatus", "Clear status", "quiet" },
    }) do
        local button = UI.CreateButton(self, {
            id = definition[1],
            title = tr(definition[2], definition[3]),
            variant = definition[4],
            target = self,
            onclick = UI.ButtonCallback(function(clicked)
                return self:onControl(clicked)
            end),
        })
        self.controls[#self.controls + 1] = button
    end
    self:requestResponsiveLayout(true)
end

function ISPNCPuppetOperaDebugWindow:onResponsiveLayout()
    local scale = self.uiScale
    local width = self:getWidth()
    local height = self:getHeight()
    local compact = height < Layout.Pixels(430, scale)
    local pad = Layout.Pixels(compact and 6 or 10, scale)
    local gap = Layout.Pixels(compact and 5 or 8, scale)
    local toolbarHeight = Layout.Pixels(compact and 26 or 30, scale)
    local hideSecondaryToolbar = compact
    -- Keep editor controls below the native collapsable-window title bar.
    -- Placing the combos at y=6 made them overlap the close/pin controls on
    -- narrow windows, which looked like a clipped toolbar rather than a
    -- resizable scene builder.
    local rowY = self:titleBarHeight() + Layout.Pixels(6, scale)
    local innerWidth = math.max(1, width - pad * 2)
    local comboWidth = math.max(1, math.floor((innerWidth - gap) / 2))
    Layout.SetBounds(self.blueprintCombo, pad, rowY,
        comboWidth, toolbarHeight)
    Layout.SetBounds(self.actorCombo, pad + comboWidth + gap, rowY,
        math.max(1, innerWidth - comboWidth - gap), toolbarHeight)

    local topRowY = rowY + toolbarHeight + gap
    local topButtonCount = math.max(1, #self.topButtons)
    local topButtonWidth = math.max(1,
        math.floor((innerWidth - gap * (topButtonCount - 1))
            / topButtonCount))
    for index, button in ipairs(self.topButtons) do
        button:setVisible(not hideSecondaryToolbar)
        Layout.SetBounds(button,
            pad + (index - 1) * (topButtonWidth + gap),
            topRowY,
            topButtonWidth,
            toolbarHeight)
    end

    local descriptionY = hideSecondaryToolbar
        and (rowY + toolbarHeight + gap)
        or (topRowY + toolbarHeight + Layout.Pixels(4, scale))
    local bottomColumns = width >= Layout.Pixels(900, scale) and 6 or 3
    local bottomRows = math.ceil(#self.controls / bottomColumns)
    local bottom = bottomRows * toolbarHeight
        + (bottomRows - 1) * gap + pad
    -- The action bar is the last thing to give up when the window is made
    -- short. The editor body may collapse to a one-pixel viewport, but the
    -- controls remain reachable and never sit below the window edge.
    local actionY = math.max(1, height - bottom)
    self.showDescription = not compact
        and actionY - descriptionY >= Layout.Pixels(20, scale)
    local contentTop = descriptionY
        + (self.showDescription and Layout.Pixels(22, scale) or gap)
    local bodyHeight = actionY - contentTop
    local showEditor = bodyHeight > 0
    local tabTop = math.max(1, contentTop)
    self.actionY = actionY
    if self.tabPanel.setVisible then self.tabPanel:setVisible(showEditor) end
    Layout.SetBounds(self.tabPanel, pad, tabTop,
        innerWidth,
        math.max(1, showEditor and actionY - tabTop or 1))
    local viewHeight = math.max(1,
        self.tabPanel:getHeight() - self.tabPanel.tabHeight)
    for _, view in ipairs({
        self.layoutTab,
        self.playerAnimationTab,
        self.npcAnimationTab,
        self.beatsTab,
        self.traceTab,
    }) do
        Layout.SetBounds(view, 0, self.tabPanel.tabHeight,
            self.tabPanel:getWidth(), viewHeight)
        if view.onResponsiveLayout then view:onResponsiveLayout() end
    end

    local buttonWidth = math.max(1,
        math.floor((innerWidth - gap * (bottomColumns - 1))
            / bottomColumns))
    for index, button in ipairs(self.controls) do
        local row = math.floor((index - 1) / bottomColumns)
        local column = (index - 1) % bottomColumns
        Layout.SetBounds(button,
            pad + column * (buttonWidth + gap),
            actionY + row * (toolbarHeight + gap),
            buttonWidth, toolbarHeight)
    end
    self.descriptionY = descriptionY
end

function ISPNCPuppetOperaDebugWindow:refreshBlueprints()
    local selected = Model.GetBlueprintID()
    self.blueprints = Model.GetBlueprints()
    self.blueprintCombo:clear()
    local selectedIndex = 1
    for index, blueprint in ipairs(self.blueprints) do
        local label = tostring(blueprint.label or blueprint.id)
        if Model.IsDirty and Model.IsDirty(blueprint.id) then
            label = tr("UI_PNC_PuppetOpera_DirtyMarker", "* ") .. label
        end
        self.blueprintCombo:addOptionWithData(
            label .. "  [" .. tostring(blueprint.id) .. "]",
            blueprint.id
        )
        if tostring(blueprint.id) == tostring(selected) then
            selectedIndex = index
        end
    end
    if #self.blueprints > 0 then setComboSelection(self.blueprintCombo, selectedIndex) end
end

function ISPNCPuppetOperaDebugWindow:refreshAnimationTabs()
    local selectedActorID = Model.GetSelectedActorID()
    local actorKind = Model.GetActorKind(selectedActorID)
    local visible = {
        layout = true,
        beats = true,
        trace = true,
        player = actorKind == "local_player",
        npc = actorKind == "nearby_live_npc",
    }
    local changed = false
    for _, definition in ipairs(self.tabDefinitions or {}) do
        if self.visibleTabKeys[definition.key] ~= visible[definition.key] then
            changed = true
            break
        end
    end
    if not changed then return end

    local activeKey = self.tabPanel.activeView
        and self.tabPanel.activeView.view
        and self.tabPanel.activeView.view.puppetOperaTabKey or "layout"
    for _, definition in ipairs(self.tabDefinitions or {}) do
        definition.view.puppetOperaTabKey = definition.key
        self.tabPanel:removeView(definition.view)
    end
    self.tabPanel.viewList = {}
    self.tabPanel.maxLength = 0
    self.tabPanel.scrollX = 0
    for _, definition in ipairs(self.tabDefinitions or {}) do
        if visible[definition.key] then
            self.tabPanel:addView(definition.name, definition.view)
        end
    end
    self.visibleTabKeys = visible
    local targetKey = visible[activeKey] and activeKey or "layout"
    for _, definition in ipairs(self.tabDefinitions or {}) do
        if definition.key == targetKey and visible[definition.key] then
            self.tabPanel:activateView(definition.name)
            break
        end
    end
end

function ISPNCPuppetOperaDebugWindow:refreshActorSlots()
    local selectedID = Model.GetSelectedActorID()
    self.actorSlots = Model.GetActorRows(Model.GetSnapshot())
    self.actorCombo:clear()
    self.actorCombo:addOption(TEXT_NO_ACTOR)
    local selectedIndex = 1
    for index, actor in ipairs(self.actorSlots) do
        local resolved = actor.kind ~= "unbound"
            and (" (" .. tostring(actor.kind) .. ")") or " (unbound)"
        local liveID = actor.liveShortID
            and (" [" .. tostring(actor.liveShortID) .. "]") or ""
        local bound = actor.liveName
            and (" - " .. tostring(actor.liveName) .. liveID)
            or " - empty slot"
        self.actorCombo:addOptionWithData(
            tostring(actor.label or actor.id) .. bound .. resolved,
            actor.id
        )
        if selectedID and tostring(actor.id) == tostring(selectedID) then
            selectedIndex = index + 1
        end
    end
    setComboSelection(self.actorCombo, selectedIndex)
end

function ISPNCPuppetOperaDebugWindow:refreshViews()
    self:refreshBlueprints()
    self:refreshActorSlots()
    self:refreshAnimationTabs()
    if Model.RefreshPreflight then Model.RefreshPreflight(false) end
    self.layoutTab:refresh()
    self.playerAnimationTab:refreshCatalog()
    self.npcAnimationTab:refreshCatalog()
    self.beatsTab:refresh()
    self.traceTab:refresh()
end

function ISPNCPuppetOperaDebugWindow:setEditorStatus(message, isError)
    self.editorStatus = message and tostring(message) or nil
    Model.State.editorError = isError and self.editorStatus or nil
end

function ISPNCPuppetOperaDebugWindow:clearEditorStatus()
    self.editorStatus = nil
    Model.State.editorError = nil
end

function ISPNCPuppetOperaDebugWindow:onBlueprintChanged()
    self:clearEditorStatus()
    local index = tonumber(self.blueprintCombo.selected) or 1
    local blueprint = self.blueprints and self.blueprints[index]
    if blueprint then
        local accepted, reason = Model.SetBlueprintID(blueprint.id)
        if not accepted then self:setEditorStatus(reason, true) end
    end
    self:refreshViews()
end

function ISPNCPuppetOperaDebugWindow:onActorChanged()
    self:clearEditorStatus()
    local index = tonumber(self.actorCombo.selected) or 1
    local actor = index > 1 and self.actorSlots and self.actorSlots[index - 1]
        or nil
    if actor then
        Model.SelectActor(actor.id)
    else
        Model.SelectActor(nil)
    end
    self:refreshViews()
end

function ISPNCPuppetOperaDebugWindow:onTopAction(button)
    local id = button and button.internal or ""
    local accepted
    local reason
    if id == "create" then
        accepted, reason = Model.CreateNew()
    elseif id == "duplicate" then
        accepted, reason = Model.DuplicateBlueprint()
    elseif id == "save" then
        accepted, reason = Model.SaveDraft()
    elseif id == "reset" then
        accepted, reason = Model.ResetDraft()
    end
    if not accepted then
        self:setEditorStatus(reason, true)
    else
        self:setEditorStatus(id .. "_complete")
    end
    self:refreshViews()
    local snapshot = Client.GetSnapshot and Client.GetSnapshot() or nil
    if accepted and snapshot and snapshot.preview == true then
        self:requestPlacementPreview()
    end
end

function ISPNCPuppetOperaDebugWindow:prepareRuntime()
    local saved, saveReason = Model.SaveDraft()
    if not saved then
        self:setEditorStatus(saveReason, true)
        return nil
    end
    local schemaOK, runtimeReason, normalized = Model.GetValidation()
    if not schemaOK then
        self:setEditorStatus(runtimeReason, true)
        return nil
    end
    if runtimeReason then
        self:setEditorStatus(
            "not_server_approved:" .. tostring(runtimeReason),
            true
        )
        return nil
    end
    return normalized
end

function ISPNCPuppetOperaDebugWindow:requestPlacementPreview(force)
    if not Client.StartPlacementPreview then
        self:setEditorStatus("placement_preview_unavailable", true)
        return false
    end
    local schemaOK, runtimeReason, normalized = Model.GetValidation()
    if not schemaOK then
        self:setEditorStatus(runtimeReason, true)
        return false
    end
    if runtimeReason then
        self:setEditorStatus(
            "not_server_approved:" .. tostring(runtimeReason),
            true
        )
        return false
    end
    local bindings, bindingReason = Model.GetRuntimeActorBindings()
    if not bindings then
        self:setEditorStatus(
            "placement_preview_blocked:" .. tostring(bindingReason),
            true
        )
        return false
    end
    local key = Model.GetBlueprintID() .. ":"
        .. tostring(Model.GetChangeSerial())
    local accepted, reason = Client.StartPlacementPreview(
        Model.GetBlueprintID(),
        normalized,
        bindings,
        key,
        force == true
    )
    if not accepted then self:setEditorStatus(reason, true) end
    return accepted == true
end

function ISPNCPuppetOperaDebugWindow:onControl(button)
    local id = button and button.internal or ""
    local blueprintID = Model.GetBlueprintID()
    local definition
    if id == "play" or id == "replay" then
        self:clearEditorStatus()
        definition = self:prepareRuntime()
        if definition then
            local bindings, bindingReason = Model.GetRuntimeActorBindings()
            if not bindings then
                self:setEditorStatus(bindingReason, true)
            elseif id == "play" then
                local accepted, reason = Client.Start(blueprintID, nil,
                    self.loopEnabled, definition, bindings)
                if not accepted then self:setEditorStatus(reason, true) end
            else
                local accepted, reason = Client.Replay(blueprintID, nil,
                    self.loopEnabled, definition, bindings)
                if not accepted then self:setEditorStatus(reason, true) end
            end
        end
    elseif id == "loop" then
        self.loopEnabled = not self.loopEnabled
        button:setTitle(
            tr("UI_PNC_PuppetOpera_Loop", "Loop")
                .. ": " .. (self.loopEnabled and "ON" or "OFF")
        )
    elseif id == "stop" then
        Client.Stop()
    elseif id == "trace" then
        Client.DumpTrace()
    elseif id == "clear" then
        Client.ClearStatus()
        self:clearEditorStatus()
    end
    self:refreshViews()
end

function ISPNCPuppetOperaDebugWindow:prerender()
    PsychopatzWindow.prerender(self)
    self.refreshCounter = self.refreshCounter + 1
    if self.refreshCounter % 10 == 0
        and not (self.layoutTab and self.layoutTab.liveDragPending)
    then
        self:refreshViews()
        if Client.RefreshPlacementPreview then
            Client.RefreshPlacementPreview(false)
        end
    end
end

function ISPNCPuppetOperaDebugWindow:render()
    PsychopatzWindow.render(self)
    local status, runtimeError = Client.GetStatus()
    local editorMessage = self.editorStatus
        or (Model.GetEditorStatus and Model.GetEditorStatus())
        or nil
    local runtimeLabel = tr("UI_PNC_PuppetOpera_RuntimeStatus", "runtime")
    local editorLabel = tr("UI_PNC_PuppetOpera_EditorStatus", "editor")
    local message = runtimeLabel .. "=" .. tostring(status)
        .. (runtimeError and " " .. tostring(runtimeError) or "")
    if editorMessage then
        message = message .. " | " .. editorLabel .. "="
            .. tostring(editorMessage)
    end
    local statusY = self.showDescription and (self.descriptionY or 34)
        or math.max(1, (self.actionY or self:getHeight()) - 16)
    if self.showDescription then
        local description = Layout.Ellipsize(TEXT_DESCRIPTION, UIFont.Small,
            math.floor(self:getWidth() * 0.54))
        self:drawText(
            description,
            12, self.descriptionY or 34,
            0.62, 0.76, 0.84, 1,
            UIFont.Small
        )
    end
    self:drawTextRight(
        Layout.Ellipsize(message, UIFont.Small,
            math.floor(self:getWidth() * 0.42)),
        self:getWidth() - 12,
        statusY,
        runtimeError and 1.00 or editorMessage and 1.00 or 0.72,
        runtimeError and 0.55 or editorMessage and 0.55 or 0.78,
        runtimeError and 0.55 or editorMessage and 0.55 or 0.84,
        1,
        UIFont.Small
    )
end

function ISPNCPuppetOperaDebugWindow:close()
    if Client and Client.StopPlacementPreview then
        Client.StopPlacementPreview()
    end
    if Client and Client.StopPreview then Client.StopPreview() end
    self:setVisible(false)
    self:removeFromUIManager()
    WindowAPI.instance = nil
end

function WindowAPI.Open(contextEntry)
    if not PNC.Client or not PNC.Client.CanUseDebug
        or PNC.Client.CanUseDebug() ~= true
    then
        return nil
    end
    local window = WindowAPI.instance
    if not window then
        window = UI.NewWindow(ISPNCPuppetOperaDebugWindow, {
            title = TEXT_TITLE,
            resizable = true,
            responsiveSpec = {
                width = 1160,
                height = 760,
                minWidth = 1,
                minHeight = 1,
                maxWidth = 1600,
                maxHeight = 1080,
            },
        })
        window:initialise()
        window:instantiate()
        WindowAPI.instance = window
    end
    if Model.ResetEditorSelection then
        Model.ResetEditorSelection()
    end
    if Model.ClearActorBindings then
        Model.ClearActorBindings()
    end
    -- A context-menu actor is only an opening context. Do not silently bind
    -- it to a scene slot; the builder must begin neutral and require an
    -- explicit drag/target selection so multi-actor drafts remain auditable.
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:refreshViews()
    Client.Refresh()
    return window
end

return WindowAPI
