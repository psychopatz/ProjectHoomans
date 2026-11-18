local Window = ISPNCNPCAuthoringEditor
local Internal = Window.Internal or {}
local Model = Internal.Model
local tr = Internal.tr
local fieldText = Internal.fieldText
local comboData = Internal.comboData
local addOptions = Internal.addOptions
local selectCombo = Internal.selectCombo
local appearanceOptions = Internal.appearanceOptions
local beardOptions = Internal.beardOptions
local Storage = Internal.Storage
local Profile = Internal.Presentation

local function readStyle(combo, survivor, key, clears)
    local value = comboData(combo)
    if value == "__current" then return end
    survivor[key] = value ~= "__random" and value or nil
    clears["appearance." .. key] = value == "__random" and true or nil
end

local function setControlEnabled(control, enabled)
    if not control then return end
    if control.setEnabled then control:setEnabled(enabled == true)
    elseif control.setEnable then control:setEnable(enabled == true) end
end

local function setLabelText(control, value)
    if not control then return end
    if Internal.UI and Internal.UI.SetLabelText then
        Internal.UI.SetLabelText(control, tostring(value or ""))
    elseif control.setName then
        control:setName(tostring(value or ""))
    end
end

local function companionRowVisible(self, row, capability)
    if capability.visible == false then return false end
    if self.presentationMode == "companion"
        and (row.id == "hair" or row.id == "beard")
    then
        -- Hair and beard are shared controls, composed in the normal
        -- Appearance tab for character creation rather than repeated in
        -- General.
        return false
    end
    return true
end

local function updatePresentation(self)
    for _, row in ipairs(self.coreRows or {}) do
        local fieldID = row.fieldID or row.id
        local capability = self:fieldCapability(fieldID)
        capability = capability or { visible = true, editable = true }
        local visible = companionRowVisible(self, row, capability)
        local label = Profile and Profile.Label(fieldID) or row.label
        row.label = label
        setLabelText(row.labelControl, label)
        row.labelControl:setVisible(visible)
        row.entry:setVisible(visible)
        PNC.NPCAuthoringFields.Lock(self, row.entry, fieldID, row.entry.parent or self.formView)
    end
    for _, row in ipairs(self.addRows or {}) do
        local capability = self:fieldCapability(row.fieldID or row.id)
        capability = capability or { visible = true, editable = true }
        if row.labelControl and row.labelControl.setVisible then
            row.labelControl:setVisible(capability.visible ~= false)
        end
        for _, entry in ipairs(row.entries or {}) do
            if entry and entry.setVisible then
                entry:setVisible(capability.visible ~= false)
            end
            setControlEnabled(entry,
                capability.visible ~= false and capability.editable ~= false)
        end
        setControlEnabled(row.button,
            capability.visible ~= false and capability.editable ~= false)
    end

end

function Window:pullForm()
    if not self.draft then return false end
    local previousDraft = self.draft
    local previousEdits = self.textEdits
    self.draft = PNC.NPCAuthoring.Registry.Copy(previousDraft)
    self.draft.runtimeRecord = previousDraft.runtimeRecord
    self.textEdits = {}
    if self.presentationAdapter then
        local survivor = self.draft.identity.survivor
        local previousNickname = self.draft.identity.nickname
        local first = fieldText(self.forenameEntry):trim()
        local nickname = fieldText(self.nicknameEntry):trim()
        local last = fieldText(self.surnameEntry):trim()
        survivor.forename = first ~= "" and first or nil
        survivor.surname = last ~= "" and last or nil
        self.draft.identity.nickname = nickname ~= "" and nickname or nil
        self.draft.nicknameCleared = nickname == ""
            and previousNickname ~= nil
        self.draft.displayName = first ~= "" and last ~= ""
            and first .. " " .. last or first .. last
        self.draft.archetypeID = comboData(self.archetypeCombo) or "General"
        self.draft.authoringClears = self.draft.authoringClears or {}
        readStyle(self.hairCombo, survivor, "hairModel", self.draft.authoringClears)
        readStyle(self.beardCombo, survivor, "beardModel", self.draft.authoringClears)
        self.draft.equipmentSpawnMode = comboData(self.equipmentModeCombo)
            or "none"
        local valid, reason = Model.BuildBlueprint(self.draft)
        if not valid then
            self.draft, self.textEdits = previousDraft, previousEdits
            self:setStatus(tostring(reason)); return false, reason
        end
        local _, commitReason = self:commitAdapterDraft()
        if commitReason then
            self.draft, self.textEdits = previousDraft, previousEdits
            self:setStatus(tostring(commitReason)); return false, commitReason
        end
        return true
    end
    local survivor = self.draft.identity.survivor
    local previousNickname = self.draft.identity.nickname
    local first = fieldText(self.forenameEntry):trim()
    local last = fieldText(self.surnameEntry):trim()
    survivor.forename = first ~= "" and first or nil
    survivor.surname = last ~= "" and last or nil
    self.draft.displayName = first ~= "" and last ~= ""
        and first .. " " .. last or first .. last
    local nickname = fieldText(self.nicknameEntry):trim()
    self.draft.identity.nickname = nickname ~= "" and nickname or nil
    self.draft.nicknameCleared = nickname == ""
        and previousNickname ~= nil
    local gender = comboData(self.genderCombo)
    self.draft.isFemale = gender == true
    self.draft.archetypeID = comboData(self.archetypeCombo) or "General"
    self.draft.factionID = fieldText(self.factionEntry):trim()
    self.draft.factionID = self.draft.factionID ~= "" and self.draft.factionID or nil
    self.draft.authoringClears = self.draft.authoringClears or {}
    readStyle(self.hairCombo, survivor, "hairModel", self.draft.authoringClears)
    readStyle(self.beardCombo, survivor, "beardModel", self.draft.authoringClears)
    self.draft.equipmentSpawnMode = comboData(self.equipmentModeCombo) or "none"
    local valid, reason = Model.BuildBlueprint(self.draft)
    if not valid then
        self.draft, self.textEdits = previousDraft, previousEdits
        self:setStatus(tostring(reason)); return false, reason
    end
    self.draft._dirty = true
    return true
end

function Window:syncControls()
    if not self.draft then return end
    self.syncing = true
    local survivor = self.draft.identity and self.draft.identity.survivor or {}
    local first, last = Model.NameParts(self.draft)
    PNC.NPCAuthoringFields.SyncText(self, self.forenameEntry, first)
    PNC.NPCAuthoringFields.SyncText(self, self.nicknameEntry, self.draft.identity
        and self.draft.identity.nickname or "")
    PNC.NPCAuthoringFields.SyncText(self, self.surnameEntry, last)
    selectCombo(self.genderCombo, self.draft.isFemale == true)
    selectCombo(self.archetypeCombo, self.draft.archetypeID or "General")
    PNC.NPCAuthoringFields.SyncText(self, self.factionEntry, self.draft.factionID)
    PNC.NPCAuthoringFields.Options(self, self.hairCombo, appearanceOptions(self.draft.isFemale == true), survivor.hairModel)
    PNC.NPCAuthoringFields.Options(self, self.beardCombo, beardOptions(self.draft.isFemale == true), survivor.beardModel)
    self.beardCombo:setEnabled(self.draft.isFemale ~= true)
    selectCombo(self.equipmentModeCombo,
        self.draft.equipmentSpawnMode or "none")
    updatePresentation(self)
    if self.appearanceTab then
        self.appearanceTab.draft = self.draft
        if self.appearanceTab.refreshGenderOptions then self.appearanceTab:refreshGenderOptions() end
    end
    self:refreshConfiguredDetails()
    if self.refreshLoadoutPage then self:refreshLoadoutPage() end
    self.syncing = false
    if self.pages then self:requestResponsiveLayout() end
end

function Window:showTab(tabID)
    local name = tabID == "Appearance"
        and self.appearanceTabName or self.generalTabName
    if self.tabPanel and name then
        self.tabPanel:activateView(name)
    end
    return self.tabPanel and self.tabPanel:getActiveView() or nil
end

function ISPNCNPCAuthoringEditor:onAction(button)
    local action = button and button.internal or ""
    if not self.draft and action ~= "new" then return end
    if action == "rotate_left" or action == "rotate_right" then
        local directions = { IsoDirections.S, IsoDirections.SW, IsoDirections.W, IsoDirections.NW,
            IsoDirections.N, IsoDirections.NE, IsoDirections.E, IsoDirections.SE }
        self.portraitDirectionIndex = ((self.portraitDirectionIndex or 1) - 1
            + (action == "rotate_left" and -1 or 1)) % #directions + 1
        self.portraitPanel.direction = directions[self.portraitDirectionIndex]
        if self.portraitPanel.modelView then
            self.portraitPanel.modelView:setDirection(self.portraitPanel.direction)
        end
    elseif action == "zoom_in" or action == "zoom_out" then
        self.portraitPanel.zoom = math.max(-10, math.min(15,
            (self.portraitPanel.zoom or -3) + (action == "zoom_in" and 1 or -1)))
        if self.portraitPanel.modelView then self.portraitPanel.modelView:setZoom(self.portraitPanel.zoom) end
    elseif action == "preview" then
        self.previewExpanded = not self.previewExpanded
        self:requestResponsiveLayout()
    elseif action == "new" then
        self.textEdits = {}
        self.debugRosterID = "current"
        self.draft = Model.New()
        self.previewDraft = nil
        if self.appearanceTab then self.appearanceTab.draft = self.draft end
        self:refreshArchetypeOptions()
        self:syncControls()
        if self.appearanceTab and self.appearanceTab.refreshGenderOptions then
            self.appearanceTab:refreshGenderOptions()
        end
        self:refreshPreview(true)
    elseif action == "load" then
        self:loadSelected()
    elseif action == "randomize" then
        if not PNC.NPCAuthoringFields.CanRandomize(self) then return end
        if self:pullForm() == false then return end
        self:adoptPreview()
        Model.Randomize(self.draft)
        self.previewDraft = nil
        self:syncControls()
        self:refreshPreview(true)
    elseif action == "save" or action == "produce" then
        if self:pullForm() == false then return end
        self:adoptPreview()
        local ok, reason = Storage.Save(self.draft, action == "produce")
        self:setStatus(ok
            and ((action == "produce"
                and tr("UI_PNC_UniqueNPCEditor_Produced", "Produced ")
                or tr("UI_PNC_UniqueNPCEditor_Saved", "Saved "))
                .. tostring(reason))
            or tostring(reason or "save failed"))
        self:refreshFiles()
        self:refreshPreview(false)
    elseif action == "inventory" then
        if self:pullForm() == false then return end
        self:adoptPreview()
        local valid = Model.Validate(self.draft)
        if valid then
            Model.EnsureRuntimeRecord(self.draft, false)
            PNC.InventoryWindow.OpenLocalDraft(self.draft)
        else
            self:setStatus(tr("UI_PNC_UniqueNPCEditor_NameRequired",
                "Enter a first name and surname first"))
        end
    elseif action == "appearance" then
        if self:pullForm() == false then return end
        self:adoptPreview()
        self:showTab("Appearance")
    elseif action == "remove_detail" then
        self:removeSelectedDetail()
    elseif action == "remove_configured" then
        self:removeSelectedConfigured()
    elseif action == "reset_details" then
        self:resetDetails()
    elseif action == "add_skill" then
        self:addSkill()
    elseif action == "add_npcTrait" then
        self:addTrait("npcTrait", self.npcTraitCombo)
    elseif action == "add_vanillaTrait" then
        self:addTrait("vanillaTrait", self.vanillaTraitCombo)
    elseif action == "add_dynamicTrait" then
        self:addTrait("dynamicTrait", self.dynamicTraitCombo)
    elseif action == "inspector" then
        if self.pages then
            for _, view in ipairs(self.tabPanel.viewList) do
                if view.view == self.pages.relations then self.tabPanel:activateView(view.name) end
            end
        end
        self.inspectorVisible = not (self.inspectorVisible == true)
        if self.details then self.details:setVisible(self.inspectorVisible) end
        self:requestResponsiveLayout(true)
        self:refreshDetails()
    end
end

