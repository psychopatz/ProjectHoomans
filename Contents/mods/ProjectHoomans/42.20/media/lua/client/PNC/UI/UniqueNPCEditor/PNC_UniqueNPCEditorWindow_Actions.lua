local Window = ISPNCUniqueNPCEditorWindow
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

function ISPNCUniqueNPCEditorWindow:pullForm()
    local survivor = self.draft.identity.survivor
    local first = fieldText(self.forenameEntry):trim()
    local last = fieldText(self.surnameEntry):trim()
    survivor.forename = first ~= "" and first or nil
    survivor.surname = last ~= "" and last or nil
    self.draft.displayName = first ~= "" and last ~= ""
        and first .. " " .. last or first .. last
    local gender = comboData(self.genderCombo)
    self.draft.isFemale = gender == true
    self.draft.archetypeID = comboData(self.archetypeCombo) or "General"
    self.draft.factionID = fieldText(self.factionEntry):trim()
    self.draft.factionID = self.draft.factionID ~= "" and self.draft.factionID or nil
    survivor.hairModel = comboData(self.hairCombo)
    survivor.beardModel = comboData(self.beardCombo)
    if survivor.hairModel == "__random" then survivor.hairModel = nil end
    if survivor.beardModel == "__random" then survivor.beardModel = nil end
    self.draft.equipmentSpawnMode = comboData(self.equipmentModeCombo) or "none"
    self.draft._dirty = true
end

function ISPNCUniqueNPCEditorWindow:syncControls()
    local survivor = self.draft.identity and self.draft.identity.survivor or {}
    local first, last = Model.NameParts(self.draft)
    setField(self.forenameEntry, first)
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
end

function ISPNCUniqueNPCEditorWindow:showTab(tabID)
    local name = tabID == "Appearance"
        and self.appearanceTabName or self.generalTabName
    if self.tabPanel and name then
        self.tabPanel:activateView(name)
    end
    return self.tabPanel and self.tabPanel:getActiveView() or nil
end

function ISPNCUniqueNPCEditorWindow:onAction(button)
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
    end
end

