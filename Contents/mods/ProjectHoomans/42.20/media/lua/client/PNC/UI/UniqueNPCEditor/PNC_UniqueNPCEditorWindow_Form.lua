local Window = ISPNCUniqueNPCEditorWindow
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

function Window:addTextRow(id, key, fallback,
    onlyNumbers, nameField)
    local row = { id = id, label = tr(key, fallback) }
    local parent = self.formView or self
    row.labelControl = addLabel(parent, row.label)
    row.entry = UI.CreateTextEntry(parent, {
        onlyNumbers = onlyNumbers == true,
        maxTextLength = 160,
        onTextChange = function()
            -- Text edits update the existing preview in place.  Only the
            -- explicit RANDOMIZE action is allowed to roll fallback values.
            self:onFormChanged(false)
        end,
    })
    self.coreRows[#self.coreRows + 1] = row
    return row.entry
end

function Window:addComboRow(id, key, fallback)
    local row = { id = id, label = tr(key, fallback) }
    local parent = self.formView or self
    row.labelControl = addLabel(parent, row.label)
    row.entry = newCombo(parent,
        ISPNCUniqueNPCEditorWindow.onComboChanged, self)
    row.entry.pncKind = id
    self.coreRows[#self.coreRows + 1] = row
    return row.entry
end

function Window:addRepeaterRow(id, key, fallback,
    entries, buttonKey)
    local parent = self.formView or self
    local row = {
        id = id,
        label = tr(key, fallback),
        labelControl = addLabel(parent, tr(key, fallback)),
        entries = entries,
    }
    row.button = UI.CreateButton(parent, {
        id = "add_" .. id,
        title = tr(buttonKey, "ADD"),
        target = self,
        onclick = ISPNCUniqueNPCEditorWindow.onAction,
        variant = "primary",
    })
    return row
end

function Window:refreshArchetypeOptions()
    if PNC.LoadArchetypes then pcall(PNC.LoadArchetypes) end
    local current = self.draft and self.draft.archetypeID or "General"
    addOptions(self.archetypeCombo, archetypeOptions())
    selectCombo(self.archetypeCombo, current)
end

function Window:refreshGenderOptions()
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
    addOptions(self.hairCombo, appearanceOptions(female))
    addOptions(self.beardCombo, beardOptions(female))
    selectCombo(self.hairCombo, survivor.hairModel)
    selectCombo(self.beardCombo, survivor.beardModel)
    self.beardCombo:setEnabled(not female)
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
    local kind = combo and combo.pncKind
    if kind == "gender" then
        self.draft.isFemale = comboData(combo) == true
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

