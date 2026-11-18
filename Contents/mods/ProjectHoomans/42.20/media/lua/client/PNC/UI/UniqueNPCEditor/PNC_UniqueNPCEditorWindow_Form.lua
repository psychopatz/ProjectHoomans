local Window = ISPNCNPCAuthoringEditor
local Internal = Window.Internal or {}
local UI = Internal.UI
local tr = Internal.tr
local comboData = Internal.comboData
local addLabel = Internal.addLabel
local newCombo = Internal.newCombo
local addOptions = Internal.addOptions
local selectCombo = Internal.selectCombo
local archetypeOptions = Internal.archetypeOptions
local skillOptions = Internal.skillOptions
local npcTraitOptions = Internal.npcTraitOptions
local vanillaTraitOptions = Internal.vanillaTraitOptions
local appearanceOptions = Internal.appearanceOptions
local beardOptions = Internal.beardOptions
local Profile = Internal.Presentation

function Window:addTextRow(id, key, fallback,
    onlyNumbers, nameField, fieldID)
    local row = { id = id, fieldID = fieldID or id, label = tr(key, fallback) }
    local parent = self.controlParent or self.formView or self
    row.labelControl = addLabel(parent, row.label)
    row.entry = UI.CreateTextEntry(parent, {
        onlyNumbers = onlyNumbers == true,
        maxTextLength = 160,
    })
    PNC.NPCAuthoringFields.BindText(self, row.entry, row.fieldID)
    self.coreRows[#self.coreRows + 1] = row
    return row.entry
end

function Window:addComboRow(id, key, fallback, fieldID)
    local row = { id = id, fieldID = fieldID or id, label = tr(key, fallback) }
    local parent = self.controlParent or self.formView or self
    row.labelControl = addLabel(parent, row.label)
    row.entry = id == "gender" and PNC.NPCAuthoringFields.Gender(self, parent)
        or id == "equipmentMode" and PNC.NPCAuthoringFields.Choice(self, parent, ISPNCNPCAuthoringEditor.onComboChanged)
        or newCombo(parent, ISPNCNPCAuthoringEditor.onComboChanged, self)
    row.entry.pncKind = id
    self.coreRows[#self.coreRows + 1] = row
    return row.entry
end

function Window:addRepeaterRow(id, key, fallback,
    entries, buttonKey, fieldID)
    local parent = self.controlParent or self.formView or self
    local row = {
        id = id,
        fieldID = fieldID or id,
        label = tr(key, fallback),
        labelControl = addLabel(parent, tr(key, fallback)),
        entries = entries,
    }
    row.button = UI.CreateButton(parent, {
        id = "add_" .. id,
        title = tr(buttonKey, "ADD"),
        target = self,
        onclick = ISPNCNPCAuthoringEditor.onAction,
        variant = "primary",
    })
    return row
end

function Window:refreshArchetypeOptions()
    if PNC.LoadArchetypes then PNC.LoadArchetypes() end
    local current = self.draft and self.draft.archetypeID or "General"
    addOptions(self.archetypeCombo, archetypeOptions())
    selectCombo(self.archetypeCombo, current)
end

function Window:refreshGenderOptions()
    if self.genderCombo.buttons then self.genderCombo:selectData(self.draft.isFemale); return end
    addOptions(self.genderCombo, {
        { id = true, label = tr("UI_PNC_UniqueNPCEditor_Female", "Female") },
        { id = false, label = tr("UI_PNC_UniqueNPCEditor_Male", "Male") },
    })
end

function Window:refreshEquipmentOptions()
    addOptions(self.equipmentModeCombo, {
        { id = "none", label = tr("UI_PNC_UniqueNPCEditor_EquipmentNone", "None") },
        { id = "melee", label = tr("UI_PNC_UniqueNPCEditor_EquipmentMelee", "Melee") },
        { id = "ranged", label = tr("UI_PNC_UniqueNPCEditor_EquipmentRanged", "Ranged") },
        { id = "both", label = tr("UI_PNC_UniqueNPCEditor_EquipmentBoth", "Melee + ranged") },
    })
end

function Window:refreshStyleOptions()
    local female = self.draft and self.draft.isFemale == true
    local survivor = self.draft and self.draft.identity
        and self.draft.identity.survivor or {}
    PNC.NPCAuthoringFields.Options(self, self.hairCombo, appearanceOptions(female), survivor.hairModel)
    PNC.NPCAuthoringFields.Options(self, self.beardCombo, beardOptions(female), survivor.beardModel)
    self.beardCombo:setEnabled(not female)
    if self.appearanceTab and self.appearanceTab.refreshHairBeardOptions then
        self.appearanceTab:refreshHairBeardOptions()
    end
end

function Window:refreshRepeaterOptions()
    addOptions(self.skillCombo, skillOptions())
    local levels = {}
    for level = 0, 10 do levels[#levels + 1] = {
        id = level, label = tostring(level),
    } end
    addOptions(self.skillLevelCombo, levels)
    addOptions(self.npcTraitCombo, npcTraitOptions())
    addOptions(self.dynamicTraitCombo, npcTraitOptions())
    addOptions(self.vanillaTraitCombo, vanillaTraitOptions())
end

function Window:onComboChanged(combo)
    if self.syncing or not self.draft then return end
    if combo and combo.pncKind == "gender" and self:fieldCapability("identity.isFemale").editable == false then
        self:syncControls(); return
    end
    local kind = combo and combo.pncKind
    if kind == "gender" then
        self.draft.isFemale = comboData(combo) == true
        local survivor = self.draft.identity.survivor
        local compatible = survivor.hairModel == nil
        for _, option in ipairs(appearanceOptions(self.draft.isFemale)) do
            if option.id == survivor.hairModel then compatible = true end
        end
        self.draft.authoringClears = self.draft.authoringClears or {}
        if not compatible then
            survivor.hairModel = nil
            self.draft.authoringClears["appearance.hairModel"] = true
        end
        if self.draft.isFemale then survivor.beardModel = "" end
        self:refreshStyleOptions()
        if self.appearanceTab and self.appearanceTab.refreshGenderOptions then
            self.appearanceTab:refreshGenderOptions()
        end
    elseif kind == "hair" then
        self.draft.appearanceAuthored.hairModel = true
    elseif kind == "beard" then
        self.draft.appearanceAuthored.beardModel = true
    end
    self:onFormChanged(false)
end

