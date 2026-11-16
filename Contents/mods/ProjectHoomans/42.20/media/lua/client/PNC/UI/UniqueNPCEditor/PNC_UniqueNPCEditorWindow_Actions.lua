local Window = ISPNCNPCAuthoringEditor
local Internal = Window.Internal or {}
local Model = Internal.Model
local tr = Internal.tr
local fieldText = Internal.fieldText
local setField = Internal.setField
local comboData = Internal.comboData
local addOptions = Internal.addOptions
local selectCombo = Internal.selectCombo
local appearanceOptions = Internal.appearanceOptions
local beardOptions = Internal.beardOptions
local Storage = Internal.Storage
local Profile = Internal.Presentation

local function setControlEnabled(control, enabled)
    if not control then return end
    if control.setEnabled then control:setEnabled(enabled == true)
    elseif control.setEnable then control:setEnable(enabled == true) end
end

local function sourceLabel(capability)
    return capability and capability.editable == false
        and capability.sourceLabel or nil
end

local function updatePresentation(self)
    for _, row in ipairs(self.coreRows or {}) do
        local fieldID = row.fieldID or row.id
        local capability = self:fieldCapability(fieldID)
        capability = capability or { visible = true, editable = true }
        local label = Profile and Profile.Label(fieldID) or row.label
        local help = sourceLabel(capability)
        if help then label = label .. " (" .. tostring(help) .. ")" end
        row.label = label
        if row.labelControl then
            if Internal.UI and Internal.UI.SetLabelText then
                Internal.UI.SetLabelText(row.labelControl, label)
            elseif row.labelControl.setName then
                row.labelControl:setName(label)
            end
        end
        if row.labelControl and row.labelControl.setVisible then
            row.labelControl:setVisible(capability.visible ~= false)
        end
        if row.entry and row.entry.setVisible then
            row.entry:setVisible(capability.visible ~= false)
        end
        setControlEnabled(row.entry,
            capability.visible ~= false and capability.editable ~= false)
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
    if self.appearanceTab then
        local skin = self:fieldCapability("appearance.skinTexture")
        local skinColor = self:fieldCapability("appearance.skinColor")
        local enabled = skin.editable ~= false and skinColor.editable ~= false
        if self.appearanceTab.skinModeCombo then
            setControlEnabled(self.appearanceTab.skinModeCombo, enabled)
        end
        if self.appearanceTab.skinLabel and Internal.UI
            and Internal.UI.SetLabelText
        then
            local label = Profile.Label("appearance.skinTexture")
            local help = sourceLabel(skin) or sourceLabel(skinColor)
            if help then label = label .. " (" .. tostring(help) .. ")" end
            Internal.UI.SetLabelText(self.appearanceTab.skinLabel, label)
        end
    end
end

function Window:pullForm()
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
        survivor.hairModel = comboData(self.hairCombo)
        survivor.beardModel = comboData(self.beardCombo)
        self.draft.authoringClears = self.draft.authoringClears or {}
        if survivor.hairModel == "__random" then survivor.hairModel = nil end
        if survivor.beardModel == "__random" then survivor.beardModel = nil end
        if survivor.hairModel == nil then
            self.draft.authoringClears["appearance.hairModel"] = true
        else
            self.draft.authoringClears["appearance.hairModel"] = nil
        end
        if survivor.beardModel == nil then
            self.draft.authoringClears["appearance.beardModel"] = true
        else
            self.draft.authoringClears["appearance.beardModel"] = nil
        end
        self.draft.equipmentSpawnMode = comboData(self.equipmentModeCombo)
            or "none"
        self:commitAdapterDraft()
        return
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
    survivor.hairModel = comboData(self.hairCombo)
    survivor.beardModel = comboData(self.beardCombo)
    self.draft.authoringClears = self.draft.authoringClears or {}
    if survivor.hairModel == "__random" then survivor.hairModel = nil end
    if survivor.beardModel == "__random" then survivor.beardModel = nil end
    if survivor.hairModel == nil then
        self.draft.authoringClears["appearance.hairModel"] = true
    else
        self.draft.authoringClears["appearance.hairModel"] = nil
    end
    if survivor.beardModel == nil then
        self.draft.authoringClears["appearance.beardModel"] = true
    else
        self.draft.authoringClears["appearance.beardModel"] = nil
    end
    self.draft.equipmentSpawnMode = comboData(self.equipmentModeCombo) or "none"
    self.draft._dirty = true
end

function Window:syncControls()
    local survivor = self.draft.identity and self.draft.identity.survivor or {}
    local first, last = Model.NameParts(self.draft)
    setField(self.forenameEntry, first)
    setField(self.nicknameEntry, self.draft.identity
        and self.draft.identity.nickname or "")
    setField(self.surnameEntry, last)
    selectCombo(self.genderCombo, self.draft.isFemale == true)
    selectCombo(self.archetypeCombo, self.draft.archetypeID or "General")
    setField(self.factionEntry, self.draft.factionID)
    addOptions(self.hairCombo, appearanceOptions(self.draft.isFemale == true))
    addOptions(self.beardCombo, beardOptions(self.draft.isFemale == true))
    selectCombo(self.hairCombo, survivor.hairModel)
    selectCombo(self.beardCombo, survivor.beardModel)
    self.beardCombo:setEnabled(self.draft.isFemale ~= true)
    selectCombo(self.equipmentModeCombo,
        self.draft.equipmentSpawnMode or "none")
    updatePresentation(self)
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
    if action == "new" then
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
        self:pullForm()
        self:adoptPreview()
        Model.Randomize(self.draft)
        self.previewDraft = nil
        self:syncControls()
        self:refreshPreview(true)
    elseif action == "save" or action == "produce" then
        self:pullForm()
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
        self:pullForm()
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
        self:pullForm()
        self:adoptPreview()
        self:showTab("Appearance")
    elseif action == "remove_detail" then
        self:removeSelectedDetail()
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
        self.inspectorVisible = not (self.inspectorVisible == true)
        if self.details then self.details:setVisible(self.inspectorVisible) end
        self:requestResponsiveLayout(true)
        self:refreshDetails()
    end
end

