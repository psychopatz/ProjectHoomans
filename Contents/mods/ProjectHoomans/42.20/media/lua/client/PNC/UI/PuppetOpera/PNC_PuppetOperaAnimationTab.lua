-- Existing animation catalogs presented as assignable Puppet Opera tracks.

require "ISUI/ISPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local addDetail = UI.AddKeyValue

local function resizeRows(list, itemHeight)
    if not list then return end
    itemHeight = math.max(1, math.floor(itemHeight))
    list.itemheight = itemHeight
    for _, item in ipairs(list.items or {}) do
        item.height = itemHeight
    end
    if list.setScrollHeight then
        list:setScrollHeight(#(list.items or {}) * itemHeight)
    end
end

local function tr(key, fallback)
    local translation = PNC.Translation
    local value = translation and translation.GetKey
        and translation.GetKey(key, fallback) or fallback
    if not value or value == "" or value == key then return fallback end
    return value
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function conditionText(condition)
    return tostring(condition.name or "?") .. "="
        .. tostring(condition.value or "?")
end

local function selectorText(entry)
    local values = {}
    for _, condition in ipairs(entry.conditions or {}) do
        if condition.name ~= "PNCActor" and condition.name ~= "BumpType"
        then
            values[#values + 1] = conditionText(condition)
        end
    end
    return table.concat(values, ", ")
end

local function drawCatalogItem(list, y, row, alternate)
    local entry = row.item
    local selected = list.selected == row.index
    if selected then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.38, 0.20, 0.48, 0.82)
    elseif alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20)
    end
    local width = math.max(32, list:getWidth() - 16)
    local title = Layout.Ellipsize(
        tostring(entry.node or entry.file or "?"),
        UIFont.Small,
        width
    )
    local clip = Layout.Ellipsize(
        tostring(entry.anim or "(no direct clip)"),
        UIFont.Small,
        width
    )
    local selector = selectorText(entry)
    list:drawText(title, 8, y + 4,
        entry.playable and 0.92 or 0.62,
        entry.playable and 0.94 or 0.62,
        entry.playable and 1.00 or 0.62, 1, UIFont.Small)
    list:drawText(clip, 8, y + 21,
        0.62, 0.82, 0.95, 1, UIFont.Small)
    list:drawText(
        Layout.Ellipsize(
            selector ~= "" and selector or tostring(entry.path or "-"),
            UIFont.Small,
            math.max(32, list:getWidth() - 16)
        ),
        8, y + 38,
        0.66, 0.70, 0.74, 1, UIFont.Small
    )
    local approved = entry.puppetOperaApproved == true
    list:drawTextRight(
        approved and "SERVER OK" or "catalog",
        list:getWidth() - 8,
        y + 4,
        approved and 0.42 or 0.70,
        approved and 0.92 or 0.72,
        approved and 0.58 or 0.72,
        1,
        UIFont.Small
    )
    return y + list.itemheight
end

ISPNCPuppetOperaAnimationTab = ISPanel:derive(
    "ISPNCPuppetOperaAnimationTab")

function ISPNCPuppetOperaAnimationTab:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCPuppetOperaAnimationTab:createChildren()
    ISPanel.createChildren(self)
    self.search = UI.CreateTextEntry(self, {
        clearButton = true,
        width = 100,
        height = 26,
        onTextChange = function()
            self:updateQuery()
            self:refreshCatalog()
        end,
    })
    self.filter = ISComboBox:new(0, 0, 190, 26, self,
        ISPNCPuppetOperaAnimationTab.onFilterChanged)
    self.filter:initialise()
    self.filter:instantiate()
    self:addChild(self.filter)

    self.list = UI.CreateList(self, {
        itemHeight = 56,
        doDrawItem = drawCatalogItem,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 25,
        valueXRatio = 0.34,
        valueXMax = 108,
        ellipsize = true,
        labelX = 8,
        labelY = 6,
        valueY = 6,
        drawSelection = false,
    })
    self.assignButton = UI.CreateButton(self, {
        id = "assign",
        title = tr("UI_PNC_PuppetOpera_AssignSelectedBeat",
            "Assign to selected beat"),
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return ISPNCPuppetOperaAnimationTab.onAction(self, button)
        end),
        variant = "selected",
    })
    self.previewButton = UI.CreateButton(self, {
        id = "preview",
        title = tr("UI_PNC_PuppetOpera_Preview", "Preview selected"),
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return ISPNCPuppetOperaAnimationTab.onAction(self, button)
        end),
        variant = "quiet",
    })
    self.stopPreviewButton = UI.CreateButton(self, {
        id = "stop_preview",
        title = tr("UI_PNC_PuppetOpera_StopPreview", "Stop preview"),
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return ISPNCPuppetOperaAnimationTab.onAction(self, button)
        end),
        variant = "danger",
    })
    self.loopPreviewButton = UI.CreateButton(self, {
        id = "loop_preview",
        title = tr("UI_PNC_PuppetOpera_LoopPreview", "Loop preview: OFF"),
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return ISPNCPuppetOperaAnimationTab.onAction(self, button)
        end),
        variant = "quiet",
    })
    self.catalogName = "player"
    self.targets = {}
    self.ownerWindow = nil
    self:rebuildFilter()
end

function ISPNCPuppetOperaAnimationTab:setContext(window, catalogName)
    self.ownerWindow = window
    self.catalogName = catalogName or self.catalogName
    self:rebuildFilter()
    self:refreshCatalog()
end

function ISPNCPuppetOperaAnimationTab:updateQuery()
    local model = self.ownerWindow and self.ownerWindow.model
    if not model then return end
    if self.catalogName == "player" then
        model.SetPlayerQuery(self.search:getText())
    else
        model.SetNPCQuery(self.search:getText())
    end
end

function ISPNCPuppetOperaAnimationTab:rebuildFilter()
    if not self.filter or not self.ownerWindow then return end
    self.filter:clear()
    if self.catalogName == "player" then
        self.filter:addOption(tr("UI_PNC_PuppetOpera_PlayerCatalog",
            "Player catalog"))
        self.filter:addOption(tr("UI_PNC_PuppetOpera_ZombieSourceBridges",
            "Player-compatible bridges"))
        self.filter.selected = self.ownerWindow.model.GetPlayerSource() == "bridge"
            and 2 or 1
    else
        self.filter:addOption(tr("UI_PNC_PuppetOpera_AllStates",
            "All states"))
        self.states = self.ownerWindow.model.GetNPCStates()
        for _, state in ipairs(self.states) do
            self.filter:addOption(tostring(state))
        end
        local selected = self.ownerWindow.model.GetNPCState()
        self.filter.selected = 1
        for index, state in ipairs(self.states) do
            if state == selected then self.filter.selected = index + 1 end
        end
    end
end

function ISPNCPuppetOperaAnimationTab:onFilterChanged()
    if not self.ownerWindow then return end
    if self.catalogName == "player" then
        self.ownerWindow.model.SetPlayerSource(
            tonumber(self.filter.selected) == 2 and "bridge" or "player"
        )
    else
        local selected = tonumber(self.filter.selected) or 1
        self.ownerWindow.model.SetNPCState(
            selected <= 1 and nil or self.states[selected - 1]
        )
    end
    self:refreshCatalog()
end

function ISPNCPuppetOperaAnimationTab:refreshTargets()
    -- Actor identity is selected once by the parent window. Keeping a second
    -- target selector here made it possible to preview one live body and
    -- assign another scene slot, which was the source of the old ambiguity.
    self.targets = {}
end

function ISPNCPuppetOperaAnimationTab:onTargetChanged()
    return false
end

function ISPNCPuppetOperaAnimationTab:getSelectedEntry()
    local row = self.list and self.list:getItem() or nil
    return row and row.item or nil
end

function ISPNCPuppetOperaAnimationTab:refreshCatalog()
    if not self.list or not self.ownerWindow then return end
    local model = self.ownerWindow.model
    local previous = self:getSelectedEntry()
    local previousID = previous and (
        self.catalogName == "player"
            and model.PlayerEntryID(previous)
            or model.NPCEntryID(previous)
    ) or nil
    self.list:clear()
    local entries = self.catalogName == "player"
        and model.GetPlayerCatalogEntries()
        or model.GetNPCCatalogEntries()
    for _, entry in ipairs(entries) do
        entry.puppetOperaApproved = self.catalogName == "player"
            and model.IsPlayerEntryServerApproved(entry)
            or model.IsNPCEntryServerApproved(entry)
        self.list:addItem(
            tostring(entry.node or entry.file or "entry"),
            entry
        )
        local currentID = self.catalogName == "player"
            and model.PlayerEntryID(entry)
            or model.NPCEntryID(entry)
        if previousID and currentID == previousID then
            self.list.selected = #self.list.items
        end
    end
    if #self.list.items > 0 and (tonumber(self.list.selected) or 0) < 1 then
        self.list.selected = 1
    end
    self.visibleCount = #self.list.items
    self:refreshTargets()
    self:refreshDetails()
end

function ISPNCPuppetOperaAnimationTab:refreshDetails()
    if not self.details then return end
    self.details:clear()
    local entry = self:getSelectedEntry()
    if not entry then
        addDetail(self.details, "Selection", "No matching catalog entry", true)
        return
    end
    local model = self.ownerWindow.model
    local approved = self.catalogName == "player"
        and model.IsPlayerEntryServerApproved(entry)
        or model.IsNPCEntryServerApproved(entry)
    local actorID = model.GetActorForCatalog(self.catalogName)
    local selectedActor
    for _, row in ipairs(model.GetActorRows(model.GetSnapshot())) do
        if actorID and tostring(row.id) == tostring(actorID) then
            selectedActor = row
            break
        end
    end
    addDetail(self.details, "Actor slot",
        selectedActor and selectedActor.label or "No actor slot selected",
        selectedActor == nil)
    addDetail(self.details, "Scene slot", actorID or "-", actorID == nil)
    addDetail(self.details, "Kind",
        selectedActor and selectedActor.kind or "unbound",
        selectedActor == nil or selectedActor.kind == "unbound")
    addDetail(self.details, "Binding",
        selectedActor and (selectedActor.liveName or selectedActor.bindingID)
            or "-",
        selectedActor == nil or not selectedActor.bindingID)
    addDetail(self.details, "Live ID",
        selectedActor and selectedActor.liveID or "-",
        selectedActor == nil or not selectedActor.liveID)
    if actorID then
        addDetail(self.details, "Assignment", model.GetSelectionSummary(actorID))
    end
    addDetail(self.details, "Catalog", self.catalogName)
    local capability = entry.puppetOperaCapability
    addDetail(self.details, "Capability",
        capability and capability.id or "unregistered",
        not capability or capability.scenePolicy ~= "scene_approved")
    addDetail(self.details, "Scene policy",
        capability and capability.scenePolicy or "preview_only",
        not capability or capability.scenePolicy ~= "scene_approved")
    if capability and capability.warning then
        addDetail(self.details, "Safety note", capability.warning, true)
    end
    addDetail(self.details, "State", entry.state)
    addDetail(self.details, "Source", entry.source or entry.folder)
    local route = entry.route
    if self.catalogName == "npc" then
        route = model.EntryBumpType(entry)
            and "zombie_bump -> XML" or "native clip preview only"
    end
    addDetail(self.details, "Route", route or "player_action")
    if self.catalogName == "player" and entry.bridgePath then
        addDetail(self.details, "Bridge", entry.bridgePath)
    end
    addDetail(self.details, "Node", entry.node)
    addDetail(self.details, "Clip", entry.anim or "(none)", not entry.anim)
    addDetail(self.details, "File", entry.path or entry.file)
    if self.catalogName == "player" then
        addDetail(self.details, "Action", entry.action or entry.emote or "-")
        addDetail(self.details, "Mode", entry.mode)
        addDetail(self.details, "Entry ID", model.PlayerEntryID(entry))
        addDetail(self.details, "MP policy",
            approved
                and "server-approved" or "local preview only",
            not approved)
    else
        local bump = model.EntryBumpType(entry)
        local selectors = selectorText(entry)
        addDetail(self.details, "BumpType", bump or "-", not bump)
        addDetail(self.details, "Selectors",
            selectors ~= "" and selectors or "none",
            selectors ~= "")
        addDetail(self.details, "Direct route",
            bump and (entry.puppetOperaDirect and "yes"
                or "requires selectors") or "preview only",
            not (bump and entry.puppetOperaDirect))
        addDetail(self.details, "Entry ID", model.NPCEntryID(entry))
        addDetail(self.details, "MP policy",
            approved
                and "server-approved" or "local preview only",
            not approved)
    end
    addDetail(self.details, "Playback",
        (entry.looped and "looped" or "one-shot") .. " @ "
            .. tostring(entry.speed or 1.0))
    addDetail(self.details, "Events", tostring(#(entry.events or {})))
end

function ISPNCPuppetOperaAnimationTab:onAction(button)
    if not self.ownerWindow then return false end
    if button and button.internal == "loop_preview" then
        local client = PNC.PuppetOpera.Client
        local enabled = not client.GetPreviewLoopEnabled()
        client.SetPreviewLoopEnabled(enabled)
        button:setTitle(tr("UI_PNC_PuppetOpera_LoopPreview", "Loop preview")
            .. ": " .. (enabled and "ON" or "OFF"))
        self.ownerWindow:setEditorStatus(
            enabled and "preview_loop_enabled" or "preview_loop_disabled")
        return true
    end
    local entry = self:getSelectedEntry()
    if not entry then return false end
    local model = self.ownerWindow.model
    if button and button.internal == "preview" then
        local target, targetReason = model.GetPreviewTarget(self.catalogName)
        if not target then
            self.ownerWindow:setEditorStatus(targetReason, true)
            return false
        end
        local accepted
        local reason
        if self.catalogName == "player" then
            accepted, reason = PNC.PuppetOpera.Client.PreviewPlayer(entry)
        else
            if not target.body or not target.record then
                self.ownerWindow:setEditorStatus(
                    "animation_target_npc_not_local", true)
                return false
            end
            accepted, reason = PNC.PuppetOpera.Client.PreviewNPC(
                entry,
                target.liveID,
                target.body,
                target.record
            )
        end
        self.ownerWindow:setEditorStatus(
            accepted and "preview_started" or reason,
            not accepted
        )
        self.ownerWindow:refreshViews()
        return accepted == true
    end
    if button and button.internal == "stop_preview" then
        PNC.PuppetOpera.Client.StopPreview()
        self.ownerWindow:setEditorStatus("preview_stopped")
        self.ownerWindow:refreshViews()
        return true
    end
    local actorID = model.GetActorForCatalog(self.catalogName)
    if not actorID then
        self.ownerWindow:setEditorStatus("no_matching_scene_actor", true)
        return false
    end
    local accepted, reason = model.AssignAnimation(actorID, entry)
    if not accepted then
        self.ownerWindow:setEditorStatus(reason)
        return false
    end
    self.ownerWindow:setEditorStatus("assigned:" .. actorID)
    self.ownerWindow:refreshViews()
    return true
end

function ISPNCPuppetOperaAnimationTab:onResponsiveLayout()
    local pad = Layout.Pixels(8, self.ownerWindow and self.ownerWindow.uiScale)
    local scale = self.ownerWindow and self.ownerWindow.uiScale
    local controlHeight = Layout.Pixels(26, scale)
    resizeRows(self.list, Layout.Pixels(56, scale))
    resizeRows(self.details, Layout.Pixels(25, scale))
    if self.list then self.list.uiScale = scale end
    if self.details then self.details.uiScale = scale end
    local available = math.max(1, self:getWidth() - pad * 2)
    local filterWidth = math.min(Layout.Pixels(190, scale),
        math.max(Layout.Pixels(96, scale), math.floor(available * 0.36)))
    local searchWidth = math.max(1, available - filterWidth - pad)
    local top = pad + controlHeight + pad
    local split = math.floor(self:getWidth() * 0.50)
    split = math.max(1, math.min(split, self:getWidth() - 1))
    Layout.SetBounds(self.search, pad, pad, searchWidth,
        controlHeight)
    Layout.SetBounds(self.filter, pad + searchWidth + pad, pad,
        math.max(1, math.min(filterWidth,
            self:getWidth() - pad * 2 - searchWidth - pad)), controlHeight)
    local footer = Layout.Pixels(38, scale)
    local contentHeight = math.max(1, self:getHeight() - top - footer)
    local narrow = self:getWidth() < Layout.Pixels(600, scale)
    if narrow then
        local listHeight = math.max(1, math.floor(contentHeight * 0.48))
        Layout.SetBounds(self.list, pad, top,
            available, listHeight)
        Layout.SetBounds(self.details, pad, top + listHeight + pad,
            available, math.max(1, contentHeight - listHeight - pad))
    else
        Layout.SetBounds(self.list, pad, top,
            math.max(1, split - pad * 2), contentHeight)
        Layout.SetBounds(self.details, split + pad, top,
            math.max(1, self:getWidth() - split - pad * 2), contentHeight)
    end
    local buttonGap = pad
    local buttonWidth = math.max(1, math.floor((available - buttonGap * 3) / 4))
    local buttonY = self:getHeight() - Layout.Pixels(34,
        self.ownerWindow and self.ownerWindow.uiScale)
    Layout.SetBounds(self.assignButton, pad, buttonY,
        buttonWidth,
        controlHeight)
    Layout.SetBounds(self.previewButton, pad + buttonWidth + buttonGap,
        buttonY, buttonWidth,
        controlHeight)
    Layout.SetBounds(self.loopPreviewButton,
        pad + (buttonWidth + buttonGap) * 2, buttonY,
        buttonWidth, controlHeight)
    Layout.SetBounds(self.stopPreviewButton,
        pad + (buttonWidth + buttonGap) * 3, buttonY,
        math.max(1, available - (buttonWidth + buttonGap) * 3),
        controlHeight)
end

return ISPNCPuppetOperaAnimationTab
