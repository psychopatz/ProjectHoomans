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
local TEXT_NO_NPC = tr(
    "UI_PNC_PuppetOpera_NoNPC",
    "Select a nearby live NPC"
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
    self.selectedNPC = nil
    self.editorStatus = nil
    self.refreshCounter = 0

    self.blueprintCombo = ISComboBox:new(0, 0, 1, 1, self,
        ISPNCPuppetOperaDebugWindow.onBlueprintChanged)
    self.blueprintCombo:initialise()
    self.blueprintCombo:instantiate()
    self:addChild(self.blueprintCombo)

    self.npcCombo = ISComboBox:new(0, 0, 1, 1, self,
        ISPNCPuppetOperaDebugWindow.onNPCChanged)
    self.npcCombo:initialise()
    self.npcCombo:instantiate()
    self:addChild(self.npcCombo)

    self.topButtons = {}
    for _, definition in ipairs({
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
    local pad = Layout.Pixels(10, scale)
    local gap = Layout.Pixels(8, scale)
    local toolbarHeight = Layout.Pixels(30, scale)
    local width = self:getWidth()
    local height = self:getHeight()
    -- Keep editor controls below the native collapsable-window title bar.
    -- Placing the combos at y=6 made them overlap the close/pin controls on
    -- narrow windows, which looked like a clipped toolbar rather than a
    -- resizable scene builder.
    local rowY = self:titleBarHeight() + Layout.Pixels(6, scale)
    local innerWidth = math.max(1, width - pad * 2)
    local comboWidth = math.floor((innerWidth - gap) / 2)
    Layout.SetBounds(self.blueprintCombo, pad, rowY,
        comboWidth, toolbarHeight)
    Layout.SetBounds(self.npcCombo, pad + comboWidth + gap, rowY,
        math.max(1, innerWidth - comboWidth - gap), toolbarHeight)

    local topRowY = rowY + toolbarHeight + gap
    local topButtonWidth = math.floor((innerWidth - gap * 2) / 3)
    for index, button in ipairs(self.topButtons) do
        Layout.SetBounds(button,
            pad + (index - 1) * (topButtonWidth + gap),
            topRowY,
            topButtonWidth,
            toolbarHeight)
    end

    local descriptionY = topRowY + toolbarHeight + Layout.Pixels(4, scale)
    local tabTop = descriptionY + Layout.Pixels(22, scale)
    local bottomColumns = width >= Layout.Pixels(900, scale) and 6 or 3
    local bottomRows = math.ceil(#self.controls / bottomColumns)
    local bottom = bottomRows * toolbarHeight
        + (bottomRows - 1) * gap + pad
    Layout.SetBounds(self.tabPanel, pad, tabTop,
        innerWidth,
        math.max(1, height - tabTop - bottom))
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
            height - bottom + row * (toolbarHeight + gap),
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

function ISPNCPuppetOperaDebugWindow:refreshNPCs()
    local selectedID = Model.GetSelectedNPCID()
    self.npcs = Model.GetNearbyNPCs(Model.GetActorDiscoveryRadius())
    self.npcCombo:clear()
    local selectedIndex = nil
    for index, npc in ipairs(self.npcs) do
        self.npcCombo:addOptionWithData(
            tostring(npc.name or npc.id)
                .. "  [" .. tostring(npc.id) .. "]",
            npc.id
        )
        if selectedID and tostring(npc.id) == tostring(selectedID) then
            selectedIndex = index
        end
    end
    if #self.npcs == 0 then
        self.npcCombo:addOption(TEXT_NO_NPC)
        setComboSelection(self.npcCombo, 1)
        self.selectedNPC = nil
        Model.SetSelectedNPC(nil)
        return
    end
    selectedIndex = selectedIndex or 1
    setComboSelection(self.npcCombo, selectedIndex)
    self.selectedNPC = self.npcs[selectedIndex]
    if self.selectedNPC then Model.SetSelectedNPC(self.selectedNPC.id) end
end

function ISPNCPuppetOperaDebugWindow:refreshViews()
    self:refreshBlueprints()
    self:refreshNPCs()
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

function ISPNCPuppetOperaDebugWindow:onNPCChanged()
    self:clearEditorStatus()
    local index = tonumber(self.npcCombo.selected) or 1
    self.selectedNPC = self.npcs and self.npcs[index] or nil
    if self.selectedNPC then
        local accepted, reason = Model.SelectLiveActor(self.selectedNPC.id)
        if not accepted then self:setEditorStatus(reason, true) end
    else
        Model.SetSelectedNPC(nil)
    end
    self:refreshViews()
end

function ISPNCPuppetOperaDebugWindow:onTopAction(button)
    local id = button and button.internal or ""
    local accepted
    local reason
    if id == "duplicate" then
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
                Client.Start(blueprintID, nil, self.loopEnabled,
                    definition, bindings)
            else
                Client.Replay(blueprintID, nil, self.loopEnabled,
                    definition, bindings)
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
    local description = Layout.Ellipsize(TEXT_DESCRIPTION, UIFont.Small,
        math.floor(self:getWidth() * 0.54))
    self:drawText(
        description,
        12, self.descriptionY or 34,
        0.62, 0.76, 0.84, 1,
        UIFont.Small
    )
    self:drawTextRight(
        Layout.Ellipsize(message, UIFont.Small,
            math.floor(self:getWidth() * 0.42)),
        self:getWidth() - 12,
        self.descriptionY or 34,
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
                minWidth = 980,
                minHeight = 620,
                maxWidth = 1600,
                maxHeight = 1080,
            },
        })
        window:initialise()
        window:instantiate()
        WindowAPI.instance = window
    end
    if contextEntry and contextEntry.id then
        Model.SetSelectedNPC(contextEntry.id)
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:refreshViews()
    Client.Refresh()
    return window
end

return WindowAPI
