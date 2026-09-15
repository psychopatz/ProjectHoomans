require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/UI/Components/PsychopatzPortraitPanel"
require "ISUI/ISLabel"
require "ISUI/ISComboBox"
require "ISUI/ISPanel"
require "ISUI/ISTabPanel"
require "PNC/Core/Archetypes/Registry/PNC_Archetypes"
require "PNC/Core/Skills/PNC_SkillCatalog"
require "PNC/Core/Traits/PNC_NPCTraitRegistry"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorModel"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCEditorStorage"
require "PNC/UI/UniqueNPCEditor/PNC_UniqueNPCAppearanceWindow"
require "PNC/UI/Inventory/PNC_InventoryWindow"

PNC = PNC or {}
PNC.UniqueNPCEditorUI = PNC.UniqueNPCEditorUI or {}

local EditorUI = PNC.UniqueNPCEditorUI
local Model = PNC.UniqueNPCEditorModel
local Storage = PNC.UniqueNPCEditorStorage
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme
local Archetypes = PNC.Archetypes

local function tr(key, fallback)
    local value = getText and PNC.Translation.GetKey(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function text(value)
    if value == nil then return "" end
    return tostring(value)
end

local function fieldText(entry)
    return entry and entry.getText and entry:getText() or ""
end

local function setField(entry, value)
    if entry and entry.setText then entry:setText(text(value)) end
end

-- ISComboBox:getSelectedData() assumes selected is a valid option index.
-- Newly-created combos start at 0, so every read goes through this guard.
local function comboData(combo)
    local selected = combo and combo.getSelected and combo:getSelected()
        or combo and combo.selected
    local options = combo and combo.options
    if type(selected) ~= "number" or selected < 1
        or type(options) ~= "table" or not options[selected]
    then
        return nil
    end
    return options[selected].data
end

local function clearCombo(combo)
    if not combo then return end
    combo:clear()
    combo.selected = 0
end

local function selectCombo(combo, value)
    local found = false
    if not combo then return end
    if value ~= nil then
        combo:selectData(value)
        for _, optionValue in ipairs(combo.options or {}) do
            if optionValue.data == value then
                found = true
                break
            end
        end
        if not found and combo.addOptionWithData then
            combo:addOptionWithData(
                tr("UI_PNC_UniqueNPCEditor_Unavailable", "Unavailable: ")
                    .. tostring(value),
                value
            )
            combo:selectData(value)
        end
    end
    if combo.selected == 0 and combo.options and combo.options[1] then
        combo.selected = 1
    end
end

local function addLabel(parent, value)
    local label = ISLabel:new(0, 0, 24, tostring(value or ""),
        0.72, 0.78, 0.84, 1, UIFont.Small, true)
    label:initialise()
    if UI.SetLabelTheme then UI.SetLabelTheme(label, "textMuted") end
    parent:addChild(label)
    return label
end

local function newCombo(parent, callback, target)
    local combo = ISComboBox:new(0, 0, 1, 1, target or parent, callback)
    combo:initialise()
    combo:instantiate()
    parent:addChild(combo)
    return combo
end

local function archetypeOptions()
    local output = {}
    local seen = {}
    local registered = Archetypes and Archetypes.List
        and Archetypes.List() or {}
    for id, definition in pairs(registered) do
        id = tostring(id)
        if not seen[id] then
            output[#output + 1] = {
                id = id,
                label = tostring(definition and definition.label or id),
            }
            seen[id] = true
        end
    end
    if not seen.General then
        output[#output + 1] = { id = "General", label = "General" }
    end
    table.sort(output, function(left, right)
        return string.lower(left.label) < string.lower(right.label)
    end)
    return output
end

local function skillOptions()
    local output = {}
    local groups = PNC.SkillCatalog and PNC.SkillCatalog.GetGroups
        and PNC.SkillCatalog.GetGroups() or {}
    for _, group in ipairs(groups) do
        for _, skill in ipairs(group.skills or {}) do
            output[#output + 1] = {
                id = tostring(skill.id),
                label = tostring(skill.display or skill.id),
            }
        end
    end
    table.sort(output, function(left, right)
        return string.lower(left.label) < string.lower(right.label)
    end)
    return output
end

local function npcTraitOptions()
    local output = {}
    local definitions = PNC.NPCTraits and PNC.NPCTraits.GetDefinitions
        and PNC.NPCTraits.GetDefinitions() or {}
    for _, definition in ipairs(definitions) do
        output[#output + 1] = {
            id = tostring(definition.id),
            label = tr(definition.labelKey, definition.label or definition.id),
        }
    end
    table.sort(output, function(left, right)
        return string.lower(left.label) < string.lower(right.label)
    end)
    return output
end

local function vanillaTraitOptions()
    local output = {}
    local ok
    local traitList
    if not CharacterTraitDefinition
        or not CharacterTraitDefinition.getTraits
    then
        return output
    end
    ok, traitList = pcall(CharacterTraitDefinition.getTraits)
    if not ok or not traitList then return output end
    for index = 0, traitList:size() - 1 do
        local trait = traitList:get(index)
        local traitType
        local traitID
        local label
        if trait then
            ok, traitType = pcall(trait.getType, trait)
            if ok and traitType and traitType.getName then
                ok, traitID = pcall(traitType.getName, traitType)
            end
            ok, label = pcall(trait.getLabel, trait)
            if ok and traitID and label then
                output[#output + 1] = {
                    id = tostring(traitID), label = tostring(label),
                }
            end
        end
    end
    table.sort(output, function(left, right)
        return string.lower(left.label) < string.lower(right.label)
    end)
    return output
end

local function appearanceOptions(isFemale)
    local output = {
        { id = "__random", label = tr("UI_PNC_UniqueNPCEditor_Random", "Random") },
        { id = "", label = tr("UI_PNC_UniqueNPCEditor_None", "None") },
    }
    if type(getAllHairStyles) ~= "function" then return output end
    local ok, styles = pcall(getAllHairStyles, isFemale == true)
    if not ok or not styles then return output end
    for index = 0, styles:size() - 1 do
        local id = tostring(styles:get(index))
        if id == "" then
            -- The empty native style is represented by the explicit None
            -- option above so it cannot be confused with Random.
            id = nil
        end
        local allowed = true
        if id and getHairStylesInstance then
            local instance = getHairStylesInstance()
            local style = isFemale and instance:FindFemaleStyle(id)
                or instance:FindMaleStyle(id)
            allowed = style and not style:isNoChoose()
        end
        if id and allowed then
            output[#output + 1] = {
                id = id,
                label = id == "" and tr("IGUI_Hair_Bald", "Bald")
                    or tr("IGUI_Hair_" .. id, id),
            }
        end
    end
    return output
end

local function beardOptions(isFemale)
    if isFemale then
        return { { id = "", label = tr("IGUI_Beard_None", "None") } }
    end
    local output = {
        { id = "__random", label = tr("UI_PNC_UniqueNPCEditor_Random", "Random") },
        { id = "", label = tr("UI_PNC_UniqueNPCEditor_None", "None") },
    }
    if type(getAllBeardStyles) ~= "function" then return output end
    local ok, styles = pcall(getAllBeardStyles)
    if not ok or not styles then return output end
    for index = 0, styles:size() - 1 do
        local id = tostring(styles:get(index))
        if id ~= "" then
            output[#output + 1] = {
                id = id,
                label = tr("IGUI_Beard_" .. id, id),
            }
        end
    end
    return output
end

local function outfitOptions(isFemale)
    local output = {
        { id = nil, label = tr("UI_characreation_clothing_none", "None") },
    }
    if type(getAllOutfits) ~= "function" then return output end
    local ok, outfits = pcall(getAllOutfits, isFemale == true)
    if not ok or not outfits then return output end
    for index = 0, outfits:size() - 1 do
        local id = tostring(outfits:get(index))
        output[#output + 1] = { id = id, label = id }
    end
    return output
end

local function addOptions(combo, options)
    clearCombo(combo)
    for _, option in ipairs(options or {}) do
        combo:addOptionWithData(option.label, option.id)
    end
end

local function collectionIDs(source, valueEntries)
    local output = {}
    local seen = {}
    if type(source) ~= "table" then return output end
    if #source > 0 then
        for _, id in ipairs(source) do
            id = tostring(id)
            if id ~= "" and not seen[id] then
                output[#output + 1] = id
                seen[id] = true
            end
        end
    else
        for id, enabled in pairs(source) do
            if (enabled == true
                or valueEntries and tonumber(enabled) ~= nil)
                and not seen[tostring(id)]
            then
                output[#output + 1] = tostring(id)
                seen[tostring(id)] = true
            end
        end
    end
    table.sort(output)
    return output
end

local function addCollection(source, id)
    local output = {}
    for _, value in ipairs(collectionIDs(source)) do output[value] = true end
    if id and id ~= "" then output[tostring(id)] = true end
    return output
end

local function removeCollection(source, id)
    local output = {}
    for _, value in ipairs(collectionIDs(source)) do
        if tostring(value) ~= tostring(id) then output[value] = true end
    end
    for _, _ in pairs(output) do return output end
    return nil
end

local function drawDetail(list, y, entry, alternate)
    local item = entry.item or {}
    local selected = list.selected == entry.index
    local muted = Theme.colors.textMuted
    local color = selected and Theme.colors.text or muted
    UI.DrawListSelection(list, y, list.itemheight, selected, alternate)
    list:drawText(Layout.Ellipsize(item.label or "", UIFont.Small,
        list:getWidth() * 0.46), 8, y + 5,
        color.r, color.g, color.b, color.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(text(item.value), UIFont.Small,
        list:getWidth() * 0.48), list:getWidth() * 0.50, y + 5,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Small)
    return y + list.itemheight
end

ISPNCUniqueNPCEditorWindow = PsychopatzWindow:derive(
    "ISPNCUniqueNPCEditorWindow")

function ISPNCUniqueNPCEditorWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCUniqueNPCEditorWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.draft = Model.New()
    self.previewDraft = nil
    self.coreRows = {}
    self.addRows = {}
    self.toolbar = {}
    for _, button in ipairs({
        { "new", "UI_PNC_UniqueNPCEditor_New", "NEW", "quiet" },
        { "load", "UI_PNC_UniqueNPCEditor_Load", "LOAD", "quiet" },
        { "save", "UI_PNC_UniqueNPCEditor_Save", "SAVE", "quiet" },
        { "produce", "UI_PNC_UniqueNPCEditor_Produce", "PRODUCE", "primary" },
        { "randomize", "UI_PNC_UniqueNPCEditor_Randomize", "RANDOMIZE", "selected" },
        { "inventory", "UI_PNC_UniqueNPCEditor_Inventory", "INVENTORY", "selected" },
    }) do
        local control = UI.CreateButton(self, {
            id = button[1],
            title = tr(button[2], button[3]),
            target = self,
            onclick = ISPNCUniqueNPCEditorWindow.onAction,
            variant = button[4],
        })
        self.toolbar[#self.toolbar + 1] = control
        self[button[1] .. "Button"] = control
    end

    self.tabPanel = ISTabPanel:new(0, 0, 1, 1)
    self.tabPanel:initialise()
    self.tabPanel:instantiate()
    self.tabPanel.tabPadX = Layout.Pixels(10, self.uiScale)
    self.tabPanel.equalTabWidth = false
    self.tabPanel.allowDraggingTabs = false
    self.tabPanel.allowTornOffTabs = false
    self:addChild(self.tabPanel)

    self.formView = ISPanel:new(0, 0, 1, 1)
    self.formView:initialise()
    self.formView:instantiate()
    self.formView:noBackground()
    self.generalTabName = tr("UI_PNC_UniqueNPCEditor_GeneralTab", "GENERAL")
    self.tabPanel:addView(self.generalTabName, self.formView)

    self.appearanceTab = ISPNCUniqueNPCAppearanceWindow:new(0, 0, 1, 1)
    self.appearanceTab.parentEditor = self
    self.appearanceTab.draft = self.draft
    self.appearanceTab.uiScale = self.uiScale
    self.appearanceTab:initialise()
    self.appearanceTab:instantiate()
    self.appearanceTabName = tr(
        "UI_PNC_UniqueNPCEditor_AppearanceTab", "APPEARANCE")
    self.tabPanel:addView(self.appearanceTabName, self.appearanceTab)

    self.fileLabel = addLabel(self.formView,
        tr("UI_PNC_UniqueNPCEditor_LoadFile", "Load draft"))
    self.fileCombo = newCombo(self.formView, nil)

    self.forenameEntry = self:addTextRow("forename",
        "UI_PNC_UniqueNPCEditor_Forename", "First name", false, true)
    self.surnameEntry = self:addTextRow("surname",
        "UI_PNC_UniqueNPCEditor_Surname", "Surname", false, true)
    self.genderCombo = self:addComboRow("gender",
        "UI_PNC_UniqueNPCEditor_Gender", "Gender")
    self.archetypeCombo = self:addComboRow("archetype",
        "UI_PNC_UniqueNPCEditor_Archetype", "Archetype")
    self.factionEntry = self:addTextRow("faction",
        "UI_PNC_UniqueNPCEditor_Faction", "Faction ID", false, false)
    self.hairCombo = self:addComboRow("hair",
        "UI_PNC_UniqueNPCEditor_Hair", "Hair")
    self.beardCombo = self:addComboRow("beard",
        "UI_PNC_UniqueNPCEditor_Beard", "Beard")
    self.equipmentModeCombo = self:addComboRow("equipmentMode",
        "UI_PNC_UniqueNPCEditor_EquipmentMode", "Equipment")

    self.skillCombo = newCombo(self.formView, nil)
    self.skillLevelCombo = newCombo(self.formView, nil)
    self.addRows[#self.addRows + 1] = self:addRepeaterRow("skill",
        "UI_PNC_UniqueNPCEditor_AddSkill", "Skill", {
            self.skillCombo, self.skillLevelCombo,
        }, "UI_PNC_UniqueNPCEditor_Add")
    self.npcTraitCombo = newCombo(self.formView, nil)
    self.addRows[#self.addRows + 1] = self:addRepeaterRow("npcTrait",
        "UI_PNC_UniqueNPCEditor_AddNPCTrait", "NPC trait",
        { self.npcTraitCombo }, "UI_PNC_UniqueNPCEditor_Add")
    self.vanillaTraitCombo = newCombo(self.formView, nil)
    self.addRows[#self.addRows + 1] = self:addRepeaterRow("vanillaTrait",
        "UI_PNC_UniqueNPCEditor_AddVanillaTrait", "Vanilla trait",
        { self.vanillaTraitCombo }, "UI_PNC_UniqueNPCEditor_Add")
    self.dynamicTraitCombo = newCombo(self.formView, nil)
    self.addRows[#self.addRows + 1] = self:addRepeaterRow("dynamicTrait",
        "UI_PNC_UniqueNPCEditor_AddDynamicTrait", "Dynamic trait",
        { self.dynamicTraitCombo }, "UI_PNC_UniqueNPCEditor_Add")

    self.details = UI.CreateList(self.formView, {
        itemHeight = Layout.Pixels(25, self.uiScale),
        doDrawItem = drawDetail,
    })
    self.removeButton = UI.CreateButton(self.formView, {
        id = "remove_detail",
        title = tr("UI_PNC_UniqueNPCEditor_Remove", "REMOVE"),
        target = self,
        onclick = ISPNCUniqueNPCEditorWindow.onAction,
        variant = "quiet",
    })
    self.resetDetailsButton = UI.CreateButton(self.formView, {
        id = "reset_details",
        title = tr("UI_PNC_UniqueNPCEditor_ResetDetails", "RESET DETAILS"),
        target = self,
        onclick = ISPNCUniqueNPCEditorWindow.onAction,
        variant = "quiet",
    })
    self.statusLabel = addLabel(self.formView, "")
    self.portraitPanel = UI.PortraitPanel:new(0, 0, 260, 390, {
        zoom = -3,
        yOffset = 0,
        direction = IsoDirections and IsoDirections.S,
        animSetName = false,
        stateName = "idle",
        animate = true,
    })
    self.portraitPanel:initialise()
    self.portraitPanel:instantiate()
    self:addChild(self.portraitPanel)

    self:refreshArchetypeOptions()
    self:refreshGenderOptions()
    self:refreshEquipmentOptions()
    self:refreshStyleOptions()
    self:refreshRepeaterOptions()
    self:refreshFiles()
    self:requestResponsiveLayout(true)
    self:syncControls()
    self:refreshPreview(true)
end

function ISPNCUniqueNPCEditorWindow:addTextRow(id, key, fallback,
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

function ISPNCUniqueNPCEditorWindow:addComboRow(id, key, fallback)
    local row = { id = id, label = tr(key, fallback) }
    local parent = self.formView or self
    row.labelControl = addLabel(parent, row.label)
    row.entry = newCombo(parent,
        ISPNCUniqueNPCEditorWindow.onComboChanged, self)
    row.entry.pncKind = id
    self.coreRows[#self.coreRows + 1] = row
    return row.entry
end

function ISPNCUniqueNPCEditorWindow:addRepeaterRow(id, key, fallback,
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

function ISPNCUniqueNPCEditorWindow:refreshArchetypeOptions()
    if PNC.LoadArchetypes then pcall(PNC.LoadArchetypes) end
    local current = self.draft and self.draft.archetypeID or "General"
    addOptions(self.archetypeCombo, archetypeOptions())
    selectCombo(self.archetypeCombo, current)
end

function ISPNCUniqueNPCEditorWindow:refreshGenderOptions()
    addOptions(self.genderCombo, {
        { id = true, label = tr("UI_PNC_UniqueNPCEditor_Female", "Female") },
        { id = false, label = tr("UI_PNC_UniqueNPCEditor_Male", "Male") },
    })
end

function ISPNCUniqueNPCEditorWindow:refreshEquipmentOptions()
    addOptions(self.equipmentModeCombo, {
        { id = "none", label = tr("UI_PNC_UniqueNPCEditor_EquipmentNone", "None") },
        { id = "melee", label = tr("UI_PNC_UniqueNPCEditor_EquipmentMelee", "Melee") },
        { id = "ranged", label = tr("UI_PNC_UniqueNPCEditor_EquipmentRanged", "Ranged") },
        { id = "both", label = tr("UI_PNC_UniqueNPCEditor_EquipmentBoth", "Melee + ranged") },
    })
end

function ISPNCUniqueNPCEditorWindow:refreshStyleOptions()
    local female = self.draft and self.draft.isFemale == true
    local survivor = self.draft and self.draft.identity
        and self.draft.identity.survivor or {}
    addOptions(self.hairCombo, appearanceOptions(female))
    addOptions(self.beardCombo, beardOptions(female))
    selectCombo(self.hairCombo, survivor.hairModel)
    selectCombo(self.beardCombo, survivor.beardModel)
    self.beardCombo:setEnabled(not female)
end

function ISPNCUniqueNPCEditorWindow:refreshRepeaterOptions()
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

function ISPNCUniqueNPCEditorWindow:onComboChanged(combo)
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

function ISPNCUniqueNPCEditorWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 58, bottom = 12 })
    local toolbar = Layout.Flow(self.toolbar, {
        x = rect.x, y = rect.y, width = rect.width,
    }, { scale = self.uiScale, minWidth = 86, gap = 6 })
    local leftGap = Layout.Pixels(10, self.uiScale)
    local portraitWidth = math.min(Layout.Pixels(280, self.uiScale),
        math.max(Layout.Pixels(220, self.uiScale), math.floor(rect.width * 0.30)))
    local leftWidth = rect.width - portraitWidth - leftGap
    local top = toolbar.bottom + Layout.Pixels(8, self.uiScale)
    local availableHeight = math.max(Layout.Pixels(160, self.uiScale),
        rect.y + rect.height - top)
    local stacked = leftWidth < Layout.Pixels(430, self.uiScale)
    local tabHeight = availableHeight
    local portraitX
    local portraitY = top
    local portraitHeight = availableHeight
    if stacked then
        leftWidth = rect.width
        portraitWidth = rect.width
        tabHeight = math.max(Layout.Pixels(230, self.uiScale),
            math.floor((availableHeight - leftGap) * 0.62))
        tabHeight = math.min(tabHeight,
            math.max(Layout.Pixels(1, self.uiScale), availableHeight - leftGap))
        portraitY = top + tabHeight + leftGap
        portraitHeight = math.max(Layout.Pixels(120, self.uiScale),
            availableHeight - tabHeight - leftGap)
        portraitX = rect.x
    else
        portraitX = rect.x + leftWidth + leftGap
    end
    Layout.SetBounds(self.tabPanel, rect.x, top, leftWidth, tabHeight)
    local viewHeight = math.max(Layout.Pixels(1, self.uiScale),
        tabHeight - self.tabPanel.tabHeight)
    Layout.SetBounds(self.formView, 0, self.tabPanel.tabHeight,
        leftWidth, viewHeight)
    Layout.SetBounds(self.appearanceTab, 0, self.tabPanel.tabHeight,
        leftWidth, viewHeight)
    self.appearanceTab.uiScale = self.uiScale
    if self.appearanceTab.onResponsiveLayout then
        self.appearanceTab:onResponsiveLayout()
    end

    local formWidth = leftWidth
    local formHeight = viewHeight
    local y = Layout.Pixels(10, self.uiScale)
    local smallHeight = Layout.Pixels(26, self.uiScale)
    local rowHeight = Layout.Pixels(29, self.uiScale)
    local labelWidth = Layout.Pixels(88, self.uiScale)
    local columnGap = Layout.Pixels(8, self.uiScale)
    local twoColumns = formWidth >= Layout.Pixels(600, self.uiScale)
    local columnWidth = twoColumns
        and math.floor((formWidth - columnGap) / 2) or formWidth
    local inputWidth = math.max(Layout.Pixels(1, self.uiScale),
        columnWidth - labelWidth)
    Layout.SetBounds(self.fileLabel, 0, y, labelWidth, smallHeight)
    Layout.SetBounds(self.fileCombo, labelWidth, y,
        formWidth - labelWidth, smallHeight)
    y = y + smallHeight + Layout.Pixels(24, self.uiScale)
    local identityY = y
    for index, row in ipairs(self.coreRows) do
        local column = twoColumns and (index - 1) % 2 or 0
        local rowIndex = twoColumns
            and math.floor((index - 1) / 2) or index - 1
        local x = column * (columnWidth + columnGap)
        local rowY = identityY + rowIndex * rowHeight
        Layout.SetBounds(row.labelControl, x, rowY, labelWidth, smallHeight)
        Layout.SetBounds(row.entry, x + labelWidth, rowY,
            inputWidth, smallHeight)
    end
    local identityRows = twoColumns
        and math.ceil(#self.coreRows / 2) or #self.coreRows
    local addY = identityY + identityRows * rowHeight
        + Layout.Pixels(28, self.uiScale)
    local addControlWidth = formWidth - labelWidth
    for index, row in ipairs(self.addRows) do
        local rowY = addY + (index - 1) * rowHeight
        Layout.SetBounds(row.labelControl, 0, rowY, labelWidth, smallHeight)
        local buttonWidth = Layout.Pixels(54, self.uiScale)
        local buttonX = formWidth - buttonWidth
        Layout.SetBounds(row.button, buttonX, rowY, buttonWidth, smallHeight)
        local available = math.max(Layout.Pixels(1, self.uiScale),
            addControlWidth - buttonWidth - columnGap)
        local entryX = labelWidth
        if #row.entries == 2 then
            local each = math.max(Layout.Pixels(1, self.uiScale),
                math.floor((available - columnGap) / 2))
            Layout.SetBounds(row.entries[1], entryX, rowY, each, smallHeight)
            Layout.SetBounds(row.entries[2], entryX + each + columnGap,
                rowY, each, smallHeight)
        else
            Layout.SetBounds(row.entries[1], entryX, rowY,
                available, smallHeight)
        end
    end
    local detailsY = addY + #self.addRows * rowHeight
        + Layout.Pixels(25, self.uiScale)
    local buttonHeight = Layout.Pixels(26, self.uiScale)
    local detailsButtonsY = formHeight - buttonHeight
    local detailsHeight = math.max(Layout.Pixels(70, self.uiScale),
        detailsButtonsY - detailsY - Layout.Pixels(5, self.uiScale))
    Layout.SetBounds(self.details, 0, detailsY, formWidth, detailsHeight)
    local resetWidth = Layout.Pixels(120, self.uiScale)
    local removeWidth = Layout.Pixels(75, self.uiScale)
    Layout.SetBounds(self.resetDetailsButton, 0, detailsButtonsY,
        resetWidth, buttonHeight)
    Layout.SetBounds(self.removeButton,
        resetWidth + columnGap, detailsButtonsY,
        removeWidth, buttonHeight)
    Layout.SetBounds(self.statusLabel,
        resetWidth + removeWidth + columnGap * 2,
        detailsButtonsY, formWidth - resetWidth - removeWidth - columnGap * 2,
        buttonHeight)
    self.portraitPanel:setVisible(true)
    Layout.SetBounds(self.portraitPanel, portraitX, portraitY,
        portraitWidth, portraitHeight)
    if self.portraitPanel.setPortraitBounds then
        self.portraitPanel:setPortraitBounds(portraitX, portraitY,
            portraitWidth, portraitHeight)
    end
    self.layout = {
        x = rect.x, y = top, leftWidth = leftWidth,
        addY = addY, detailsY = detailsY, portraitX = portraitX,
        portraitWidth = portraitWidth,
        twoColumns = twoColumns, stacked = stacked,
    }
end

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

function ISPNCUniqueNPCEditorWindow:setStatus(value)
    self.statusText = tostring(value or "")
    if self.statusLabel and UI.SetLabelText then
        UI.SetLabelText(self.statusLabel, self.statusText)
    end
end

function ISPNCUniqueNPCEditorWindow:effectiveDraft()
    return self.previewDraft or self.draft
end

function ISPNCUniqueNPCEditorWindow:buildDetails()
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

function ISPNCUniqueNPCEditorWindow:refreshDetails()
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

function ISPNCUniqueNPCEditorWindow:refreshPreview(force)
    self.previewDraft = Model.UpdatePreviewDraft(self.previewDraft, self.draft)
    local valid, reason = Model.Validate(self.draft)
    local previewRecord, previewReason = Model.EnsureRuntimeRecord(
        self.previewDraft, force == true)
    local rendered = false
    if previewRecord then
        local spec = Model.BuildPortraitSpec(self.previewDraft)
        rendered = self.portraitPanel:setTarget(
            nil, spec, force == true) == true
    end
    self:refreshDetails()
    if valid and rendered then
        self:setStatus(tr("UI_PNC_UniqueNPCEditor_Ready", "Draft ready"))
    elseif rendered then
        self:setStatus(tr("UI_PNC_UniqueNPCEditor_PreviewOnly",
            "Preview only - enter a first name and surname before saving"))
    else
        self:setStatus(tostring(previewReason or reason
            or "preview unavailable"):gsub("_", " "))
    end
end

function ISPNCUniqueNPCEditorWindow:onFormChanged(force)
    self:pullForm()
    self:refreshPreview(force == true)
end

function ISPNCUniqueNPCEditorWindow:onAppearanceChanged()
    self.previewDraft = nil
    self:syncControls()
    if self.appearanceTab then
        self.appearanceTab.draft = self.draft
        if self.appearanceTab.syncFromDraft then
            self.appearanceTab:syncFromDraft()
        end
    end
    self:refreshPreview(false)
end

function ISPNCUniqueNPCEditorWindow:showTab(tabID)
    local name = tabID == "Appearance"
        and self.appearanceTabName or self.generalTabName
    if self.tabPanel and name then
        self.tabPanel:activateView(name)
    end
    return self.tabPanel and self.tabPanel:getActiveView() or nil
end

function ISPNCUniqueNPCEditorWindow:adoptPreview()
    if self.previewDraft and self.previewDraft.runtimeRecord then
        self.draft.runtimeRecord = self.previewDraft.runtimeRecord
        self.draft.id = Model.BuildID(self.draft)
    end
end

function ISPNCUniqueNPCEditorWindow:refreshFiles()
    if not self.fileCombo then return end
    local previous = comboData(self.fileCombo)
    clearCombo(self.fileCombo)
    for _, entry in ipairs(Storage.List()) do
        self.fileCombo:addOptionWithData(
            tostring(entry.label or entry.fileName), entry.fileName)
    end
    selectCombo(self.fileCombo, previous)
end

function ISPNCUniqueNPCEditorWindow:loadSelected()
    local fileName = comboData(self.fileCombo)
    local draft
    local reason
    if not fileName then
        self:setStatus(tr("UI_PNC_UniqueNPCEditor_SelectFile",
            "Choose a saved draft first"))
        return false
    end
    draft, reason = Storage.LoadFile(fileName)
    if not draft then
        self:setStatus(tostring(reason or "load failed"))
        return false
    end
    self.draft = draft
    self.previewDraft = nil
    if self.appearanceTab then self.appearanceTab.draft = self.draft end
    self:syncControls()
    if self.appearanceTab and self.appearanceTab.syncFromDraft then
        self.appearanceTab:syncFromDraft()
    end
    self:refreshPreview(true)
    return true
end

function ISPNCUniqueNPCEditorWindow:addSkill()
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

function ISPNCUniqueNPCEditorWindow:addTrait(kind, combo)
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

function ISPNCUniqueNPCEditorWindow:removeSelectedDetail()
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

function ISPNCUniqueNPCEditorWindow:resetDetails()
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

function ISPNCUniqueNPCEditorWindow:render()
    PsychopatzWindow.render(self)
    if self.layout then
        UI.DrawSectionTitle(self,
            tr("UI_PNC_UniqueNPCEditor_Preview", "PREVIEW"),
            self.layout.portraitX,
            self.layout.y - Layout.Pixels(18, self.uiScale),
            self.layout.portraitWidth)
    end
end

function ISPNCUniqueNPCEditorWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    EditorUI.instance = nil
end

function ISPNCUniqueNPCEditorWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function EditorUI.Open()
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        return nil
    end
    local window = EditorUI.instance
    if not window then
        window = UI.NewWindow(ISPNCUniqueNPCEditorWindow, {
            title = tr("UI_PNC_UniqueNPCEditor_Title", "UNIQUE NPC CREATOR"),
            resizable = true,
            responsiveSpec = {
                width = 1040, height = 760, minWidth = 820, minHeight = 620,
                maxWidth = 1600, maxHeight = 1100,
            },
        })
        window:initialise()
        window:instantiate()
        window:addToUIManager()
        EditorUI.instance = window
    else
        window:addToUIManager()
        window:setVisible(true)
        window:bringToTop()
    end
    return window
end

function EditorUI.Toggle()
    if EditorUI.instance and EditorUI.instance:getIsVisible() then
        EditorUI.instance:close()
        return false
    end
    return EditorUI.Open() ~= nil
end

return EditorUI
