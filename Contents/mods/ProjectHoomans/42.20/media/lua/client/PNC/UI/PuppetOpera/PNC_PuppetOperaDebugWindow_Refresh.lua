-- Model-to-widget refresh projection for the Puppet Opera scene builder.

PNC = PNC or {}

local Internal = PNC.PuppetOperaDebugWindow.Internal
local Model = Internal.Model
local tr = Internal.tr
local Class = ISPNCPuppetOperaDebugWindow

local function setComboSelection(combo, selected)
    combo.selected = tonumber(selected) or 1
end

function Class:refreshBlueprints()
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
    if #self.blueprints > 0 then
        setComboSelection(self.blueprintCombo, selectedIndex)
    end
end

function Class:refreshAnimationTabs()
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

function Class:refreshActorSlots()
    local selectedID = Model.GetSelectedActorID()
    self.actorSlots = Model.GetActorRows(Model.GetSnapshot())
    self.actorCombo:clear()
    self.actorCombo:addOption(Internal.TEXT_NO_ACTOR)
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

function Class:refreshViews()
    if Model.BeginRefresh then Model.BeginRefresh() end
    self:refreshBlueprints()
    self:refreshActorSlots()
    self:refreshAnimationTabs()
    if Model.RefreshPreflight then Model.RefreshPreflight(false) end
    if Model.InvalidateRefreshCache then Model.InvalidateRefreshCache() end
    self.layoutTab:refresh()
    self.playerAnimationTab:refreshCatalog()
    self.npcAnimationTab:refreshCatalog()
    self.beatsTab:refresh()
    self.traceTab:refresh()
    if Model.EndRefresh then Model.EndRefresh() end
end

return Class
