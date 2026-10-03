local Window = ISPNCUniqueNPCEditorWindow
local Internal = Window.Internal or {}
local Model = Internal.Model
local tr = Internal.tr
local text = Internal.text
local comboData = Internal.comboData
local collectionIDs = Internal.collectionIDs
local removeCollection = Internal.removeCollection

function Window:buildDetails()
    local draft = self.draft
    local preview = self:effectiveDraft()
    local record = preview and preview.runtimeRecord or nil
    local survivor = record and record.identity and record.identity.survivor
        or draft.identity and draft.identity.survivor or {}
    local rows = {}
    local first, last = Model.NameParts(draft)
    local randomLabel = tr("UI_PNC_UniqueNPCEditor_Random", "Random")
    local noneLabel = tr("UI_PNC_UniqueNPCEditor_None", "None")
    local function selectedValue(value)
        if value == nil then return randomLabel end
        if value == "" then return noneLabel end
        return value
    end
    local skinValue
    local skinTone = survivor.skinTexture
        and string.match(tostring(survivor.skinTexture), "Body0(%d+)$")
    if survivor.skinColor then
        skinValue = tr("UI_PNC_UniqueNPCEditor_LegacySkin",
            "Legacy custom tone")
    elseif skinTone then
        skinValue = tr("UI_PNC_UniqueNPCEditor_SkinTone_" .. skinTone,
            "Tone " .. skinTone)
    else
        skinValue = randomLabel
    end
    local function add(label, value, kind, key, removable)
        rows[#rows + 1] = {
            label = label, value = value == nil and "—" or text(value),
            kind = kind or "field", key = key or label,
            removable = removable == true,
        }
    end
    add(tr("UI_PNC_UniqueNPCEditor_Forename", "First name"), first)
    add(tr("UI_PNC_UniqueNPCEditor_Surname", "Surname"), last)
    add(tr("UI_PNC_UniqueNPCEditor_Gender", "Gender"),
        draft.isFemale and tr("UI_PNC_UniqueNPCEditor_Female", "Female")
            or tr("UI_PNC_UniqueNPCEditor_Male", "Male"))
    add(tr("UI_PNC_UniqueNPCEditor_Archetype", "Archetype"), draft.archetypeID)
    add(tr("UI_PNC_UniqueNPCEditor_Faction", "Faction ID"), draft.factionID)
    add(tr("UI_PNC_UniqueNPCEditor_Hair", "Hair"),
        selectedValue(survivor.hairModel))
    add(tr("UI_PNC_UniqueNPCEditor_Beard", "Beard"),
        selectedValue(survivor.beardModel))
    add(tr("UI_PNC_UniqueNPCEditor_SkinColor", "Skin color"), skinValue)
    add(tr("UI_PNC_UniqueNPCEditor_EquipmentMode", "Equipment"),
        draft.equipmentSpawnMode)
    for _, skillID in ipairs(collectionIDs(draft.skillLevels, true)) do
        add("Skill / " .. skillID, draft.skillLevels[skillID],
            "skill", skillID, true)
    end
    for _, traitID in ipairs(collectionIDs(draft.npcTraits)) do
        add("NPC trait / " .. traitID, "Enabled", "npcTrait", traitID, true)
    end
    for _, traitID in ipairs(collectionIDs(draft.vanillaTraits)) do
        add("Vanilla trait / " .. traitID, "Enabled", "vanillaTrait", traitID, true)
    end
    for _, traitID in ipairs(collectionIDs(draft.dynamicTraits)) do
        add("Dynamic trait / " .. traitID, "Enabled", "dynamicTrait", traitID, true)
    end
    for _, item in ipairs(Model.ListAuthoredItems(preview)) do
        add("Item / " .. text(item.type),
            "x" .. text(item.stack or 1), "item", item.runtimeID, true)
    end
    return rows
end

function Window:refreshDetails()
    if not self.details then return end
    local previous = self.details:getItem()
    local previousKey = previous and previous.item
        and previous.item.kind .. ":" .. text(previous.item.key) or nil
    self.details:clear()
    self.detailRows = self:buildDetails()
    for _, row in ipairs(self.detailRows) do
        self.details:addItem(row.label, row)
    end
    self.details.selected = 0
    for index, row in ipairs(self.detailRows) do
        local desired = self.pendingDetailKey
        if (desired and desired == row.kind .. ":" .. text(row.key))
            or (not desired and previousKey
                and previousKey == row.kind .. ":" .. text(row.key))
        then
            self.details.selected = index
            break
        end
    end
    if self.details.selected == 0 and #self.detailRows > 0 then
        self.details.selected = 1
    end
    if self.pendingDetailKey and self.details.ensureVisible then
        self.details:ensureVisible(self.details.selected)
    end
    self.pendingDetailKey = nil
    local selected = self.details:getItem()
    local enabled = selected and selected.item and selected.item.removable == true
    if self.removeButton then self.removeButton:setEnable(enabled == true) end
end

function Window:addSkill()
    local skill = comboData(self.skillCombo)
    local level = comboData(self.skillLevelCombo)
    if not skill or level == nil then
        self:setStatus(tr("UI_PNC_UniqueNPCEditor_SelectSkill",
            "Choose a skill and level"))
        return
    end
    local ok, reason, id = Model.TryAddSkill(
        self.draft, skill, tonumber(level) or 0)
    if not ok then
        self:setStatus(tostring(reason or "skill rejected"):gsub("_", " "))
        return
    end
    self.pendingDetailKey = "skill:" .. tostring(id)
    self:refreshPreview(false)
    self:setStatus("Skill added")
end

function Window:addTrait(kind, combo)
    local id = comboData(combo)
    if not id then
        self:setStatus(tr("UI_PNC_UniqueNPCEditor_SelectTrait",
            "Choose a trait first"))
        return
    end
    local ok, reason, normalized = Model.TryAddTrait(
        self.draft,
        kind == "npcTrait" and "npc"
            or kind == "vanillaTrait" and "vanilla" or "dynamic",
        id)
    if not ok then
        self:setStatus(tostring(reason or "trait rejected"):gsub("_", " "))
        return
    end
    self.pendingDetailKey = kind .. ":" .. tostring(normalized or id)
    self:refreshPreview(false)
    self:setStatus("Trait added")
end

function Window:removeSelectedDetail()
    local selected = self.details and self.details:getItem()
    local row = selected and selected.item or nil
    if not row or not row.removable then return end
    if row.kind == "skill" then
        if self.draft.skillLevels then self.draft.skillLevels[row.key] = nil end
        self.draft.authoredFields = self.draft.authoredFields or {}
        self.draft.authoredFields.skillLevels = true
    elseif row.kind == "item" then
        if Model.RemoveInventoryItem(self:effectiveDraft(), row.key) then
            self:adoptPreview()
            Model.SyncFromRuntime(self.draft)
        end
    else
        local field = row.kind == "npcTrait" and "npcTraits"
            or row.kind == "vanillaTrait" and "vanillaTraits"
            or "dynamicTraits"
        self.draft[field] = removeCollection(self.draft[field], row.key)
        self.draft.authoredFields = self.draft.authoredFields or {}
        self.draft.authoredFields[field] = true
    end
    self.draft._dirty = true
    self:refreshPreview(false)
end

function Window:resetDetails()
    self.draft.skillLevels = nil
    self.draft.npcTraits = nil
    self.draft.vanillaTraits = nil
    self.draft.dynamicTraits = nil
    self.draft.authoredFields = self.draft.authoredFields or {}
    self.draft.authoredFields.skillLevels = true
    self.draft.authoredFields.npcTraits = true
    self.draft.authoredFields.vanillaTraits = true
    self.draft.authoredFields.dynamicTraits = true
    self.draft._dirty = true
    self:refreshPreview(false)
end

