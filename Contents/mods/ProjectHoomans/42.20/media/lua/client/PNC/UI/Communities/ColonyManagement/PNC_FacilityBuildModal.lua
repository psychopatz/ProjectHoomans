require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.FacilityBuildUI = PNC.FacilityBuildUI or {}

local BuildUI = PNC.FacilityBuildUI
BuildUI.previousWindow = BuildUI.previousWindow or nil
BuildUI.previousWindowWasVisible = BuildUI.previousWindowWasVisible or false
BuildUI.lastOpenArgs = BuildUI.lastOpenArgs or nil
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local ImageResolver = UI.ImageResolver
    or require "PsychopatzCore/UI/Components/PsychopatzImageResolver"

local CATEGORY_ORDER = { "housing", "food", "technology", "utilities",
    "production" }
local CATEGORY_LABELS = {
    housing = "HOUSING", food = "FOOD", production = "PRODUCTION",
    technology = "TECHNOLOGY", utilities = "UTILITIES",
}
local PAGE_SIZE = 4
local FACILITY_WINDOW_SPEC = {
    -- Logical pixels scaled from PsychopatzCore's 1920x1080 baseline.
    width = 1180,
    height = 760,
    minWidth = 760,
    minHeight = 540,
    maxWidth = 1440,
    maxHeight = 920,
    screenMargin = 24,
}

local function facilityWindowSpec()
    local spec = {}
    for key, value in pairs(FACILITY_WINDOW_SPEC) do spec[key] = value end
    return spec
end

BuildUI.WindowSpec = facilityWindowSpec

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == key then return fallback end
    return value
end

local function canUseDebug()
    local client = PNC.Client
    return client and client.CanUseDebug
        and client.CanUseDebug() == true
end

local function playerCount(fullType)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local inventory = player and player.getInventory and player:getInventory() or nil
    local values = inventory and inventory.getItemsFromType
        and inventory:getItemsFromType(fullType, true) or nil
    return values and values.size and values:size() or 0
end

local function humanizeIdentifier(value)
    local text = tostring(value or "")
    text = text:match("([^%.]+)$") or text
    text = string.gsub(text, "[_%-]+", " ")
    if text == "" then return text end
    return string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2)
end

local function stockpileCount(storage, fullType)
    if type(fullType) == "table" then
        local best = 0
        for _, candidate in ipairs(fullType) do
            best = math.max(best, stockpileCount(storage, candidate))
        end
        return best
    end
    local total = 0
    for _, row in ipairs(storage and storage.rows or {}) do
        if tostring(row.fullType or "") == tostring(fullType or "") then
            total = total + math.max(0, math.floor(tonumber(row.quantity) or 0))
        end
    end
    return total
end

local function buildDescriptorFor(definition)
    if not definition or definition.directWorkstation ~= true then return nil end
    local objectInfoName = definition.buildRecipeObjectInfoName
        or definition.entityScript
    local catalog = PNC.BuildRecipeCatalog
    if not catalog then return nil end
    local aliases = {
        objectInfoName,
        definition.entityScript,
        definition.stationId,
        tr(definition.displayNameKey, humanizeIdentifier(definition.id)),
    }
    if catalog.Queries and catalog.Queries.FindForAliases then
        local descriptor = catalog.Queries.FindForAliases(aliases)
        if descriptor then return descriptor end
    end
    if catalog.Get and objectInfoName then
        local descriptor = catalog.Get(objectInfoName)
        if descriptor then return descriptor end
    end
    if catalog.Queries and catalog.Queries.FindForObjectInfo
        and objectInfoName
    then
        local descriptor = catalog.Queries.FindForObjectInfo(objectInfoName)
        if descriptor then return descriptor end
    end
    if catalog.Queries and catalog.Queries.FindNativeObjectInfo
        and objectInfoName
    then
        local info = catalog.Queries.FindNativeObjectInfo(objectInfoName)
        if info then
            return {
                objectInfoName = tostring(objectInfoName),
                displayName = tr(definition.displayNameKey,
                    humanizeIdentifier(definition.id)),
                category = definition.category,
                nativeObjectInfo = info,
                nativeOnly = true,
                requirements = {},
            }
        end
    end
    return nil
end

local function descriptorTexture(descriptor)
    return descriptor and ImageResolver.Resolve(descriptor) or nil
end

local function recipeFor(definition, descriptor)
    if descriptor and type(descriptor.requirements) == "table" then
        return descriptor.requirements
    end
    local recipe = definition and (definition.buildCosts
        or definition.buildCost) or {}
    if recipe.fullType then return { recipe } end
    return recipe
end

local function costTypes(cost)
    if type(cost) ~= "table" then return {} end
    if type(cost.itemTypes) == "table" and #cost.itemTypes > 0 then
        return cost.itemTypes
    end
    local fullType = cost.fullType or cost.itemType
    return fullType and { tostring(fullType) } or {}
end

local function costLabel(cost)
    local labels = {}
    for _, fullType in ipairs(costTypes(cost)) do
        labels[#labels + 1] = getItemNameFromFullType
            and tostring(getItemNameFromFullType(fullType) or fullType)
            or tostring(fullType)
    end
    return table.concat(labels, " / ")
end

local function productionCategory(definition, descriptor, primarySkill)
    local work = PNC.WorkDefinitions
    local valid = {}
    for _, skillId in ipairs(work and work.CRAFTING_SKILL_ORDER or {}) do
        valid[tostring(skillId)] = true
    end
    local nativeCategory = descriptor and tostring(descriptor.category or "")
    if nativeCategory ~= "" and valid[nativeCategory] then
        return nativeCategory
    end
    if definition and definition.directWorkstation == true
        and primarySkill and valid[tostring(primarySkill)]
    then
        return tostring(primarySkill)
    end
    return tostring(definition and definition.category or "production")
end

local function themeColor(name, fallback)
    return Theme.colors and Theme.colors[name] or fallback
end

local function fontHeight(font)
    if type(Theme.FontHeight) == "function" then
        local ok, value = pcall(Theme.FontHeight, font)
        if ok and tonumber(value) then return tonumber(value) end
    end
    return 16
end

local function textWidth(font, value)
    value = tostring(value or "")
    if type(Theme.TextWidth) == "function" then
        local ok, width = pcall(Theme.TextWidth, font, value)
        if ok and tonumber(width) then return tonumber(width) end
    end
    return #value * 7
end

local function fitText(value, font, maxWidth)
    local text = tostring(value or "")
    local width = math.max(1, tonumber(maxWidth) or 1)
    if textWidth(font, text) <= width then return text end
    local suffix = "..."
    local candidate = text
    while #candidate > 0 do
        candidate = string.sub(candidate, 1, #candidate - 1)
        if textWidth(font, candidate .. suffix) <= width then
            return candidate .. suffix
        end
    end
    return suffix
end

local function wrapText(value, font, maxWidth, maxLines)
    local text = tostring(value or "")
    local width = math.max(1, tonumber(maxWidth) or 1)
    local limit = math.max(1, math.floor(tonumber(maxLines) or 1))
    local lines, current = {}, ""
    if text == "" then return { "" } end
    for word in string.gmatch(text, "%S+") do
        local candidate = current == "" and word or current .. " " .. word
        if current == "" or textWidth(font, candidate) <= width then
            current = candidate
        else
            lines[#lines + 1] = current
            current = word
        end
    end
    if current ~= "" then lines[#lines + 1] = current end
    if #lines <= limit then return lines end
    local output = {}
    for index = 1, limit do output[index] = lines[index] end
    output[limit] = fitText(output[limit] .. " " .. lines[limit + 1],
        font, width)
    return output
end

local function drawCentered(element, value, y, font, tint, centerX, maxWidth)
    local text = fitText(value, font, maxWidth)
    element:drawTextCentre(text, centerX, y,
        tint.r, tint.g, tint.b, tint.a or 1, font)
end

local FacilityCard = ISPanel:derive("PNCFacilityBuildCard")

function FacilityCard:onMouseDown()
    self.owner:setSelected(self.option.id)
    return true
end

function FacilityCard:render()
    ISPanel.render(self)
    local option = self.option or {}
    local selected = self.owner.selectedId == option.id
    local border = selected and themeColor("accent",
        { r = 0.2, g = 0.72, b = 0.82, a = 1 })
        or themeColor("border", { r = 0.23, g = 0.28, b = 0.32, a = 0.9 })
    local textTint = option.enabled
        and themeColor("text", { r = 0.91, g = 0.94, b = 0.96, a = 1 })
        or themeColor("textMuted", { r = 0.58, g = 0.65, b = 0.7, a = 1 })
    local warning = themeColor("warning", { r = 0.94, g = 0.7, b = 0.27, a = 1 })
    local muted = themeColor("textMuted", { r = 0.58, g = 0.65, b = 0.7, a = 1 })
    local statusTint = option.enabled
        and themeColor("success", { r = 0.39, g = 0.78, b = 0.48, a = 1 })
        or themeColor("danger", { r = 0.94, g = 0.36, b = 0.31, a = 1 })
    local padding = 10
    local contentWidth = math.max(1, self.width - padding * 2)
    local titleFont, metaFont = UIFont.Small, UIFont.Small
    local titleHeight, lineHeight = fontHeight(titleFont),
        math.max(14, fontHeight(metaFont))
    -- Give the native build image a real visual area. Keep the metadata below
    -- it so tall object textures never collide with the title or requirements.
    local imageHeight = math.max(42, math.min(136,
        math.floor(self.height * 0.44)))
    local imageY, textY = 6, imageHeight + 8

    self:drawRect(0, 0, self.width, self.height, selected and 0.92 or 0.78,
        0.045, 0.06, 0.07)
    self:drawRectBorder(0, 0, self.width, self.height,
        border.a or 1, border.r, border.g, border.b)
    ImageResolver.Draw(self, option.texture, padding, imageY,
        contentWidth, imageHeight, option.enabled and 1 or 0.42)

    local titleLines = wrapText(option.name, titleFont, contentWidth, 2)
    for index, line in ipairs(titleLines) do
        drawCentered(self, line, textY + (index - 1) * titleHeight,
            titleFont, textTint, self.width / 2, contentWidth)
    end
    textY = textY + math.max(1, #titleLines) * titleHeight + 3
    drawCentered(self, option.costText, textY, metaFont, warning,
        self.width / 2, contentWidth)
    textY = textY + lineHeight
    drawCentered(self, option.sourceText, textY, metaFont, muted,
        self.width / 2, contentWidth)
    textY = textY + lineHeight
    drawCentered(self, option.skillText, textY, metaFont, muted,
        self.width / 2, contentWidth)
    textY = textY + lineHeight
    drawCentered(self, option.status, textY, metaFont, statusTint,
        self.width / 2, contentWidth)
end

function FacilityCard:new(x, y, width, height, owner, option)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self); self.__index = self
    object.owner, object.option = owner, option
    object.background = false
    return object
end

ISPNCFacilityBuildWindow = PsychopatzWindow:derive("ISPNCFacilityBuildWindow")

function ISPNCFacilityBuildWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCFacilityBuildWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.cards = {}
    for _, option in ipairs(self.options) do
        local card = FacilityCard:new(0, 0, 1, 1, self, option)
        card:initialise(); card:instantiate(); self:addChild(card)
        self.cards[#self.cards + 1] = card
    end
    self.categoryButtons = {}
    local available = {}
    for _, option in ipairs(self.options) do available[option.category] = true end
    local categoryOrder = {}
    for _, category in ipairs(CATEGORY_ORDER) do
        categoryOrder[#categoryOrder + 1] = category
    end
    for _, category in ipairs(PNC.WorkDefinitions
        and PNC.WorkDefinitions.CRAFTING_SKILL_ORDER or {}) do
        categoryOrder[#categoryOrder + 1] = category
    end
    for _, category in ipairs(categoryOrder) do
        if available[category] then
            local button = UI.CreateButton(self, {
                id = "category:" .. category,
                title = tr("UI_PNC_Facility_Category_" .. category,
                    CATEGORY_LABELS[category] or string.upper(category)),
                target = self, onclick = ISPNCFacilityBuildWindow.onAction,
            })
            button.facilityCategory = category
            self.categoryButtons[#self.categoryButtons + 1] = button
        end
    end
    self.confirmButton = UI.CreateButton(self, {
        id = "build", title = tr("UI_PNC_Facility_BuildConfirm", "BUILD"),
        target = self, onclick = ISPNCFacilityBuildWindow.onAction,
        variant = "success",
    })
    self.debugMaterialsButton = UI.CreateButton(self, {
        id = "debug_materials",
        title = tr("UI_PNC_Facility_DebugGiveMaterials", "GIVE MATERIALS"),
        target = self, onclick = ISPNCFacilityBuildWindow.onAction,
        variant = "warning",
    })
    self.cancelButton = UI.CreateButton(self, {
        id = "cancel", title = tr("UI_Cancel", "CANCEL"), target = self,
        onclick = ISPNCFacilityBuildWindow.onAction, variant = "danger",
    })
    self.previousPageButton = UI.CreateButton(self, {
        id = "page_previous", title = "<", target = self,
        onclick = ISPNCFacilityBuildWindow.onAction, variant = "quiet",
    })
    self.nextPageButton = UI.CreateButton(self, {
        id = "page_next", title = ">", target = self,
        onclick = ISPNCFacilityBuildWindow.onAction, variant = "quiet",
    })
    self:setCategory(self.options[1] and self.options[1].category or nil)
    if self.focusDefinitionId then
        local focused
        for _, option in ipairs(self.options) do
            if tostring(option.id) == tostring(self.focusDefinitionId) then
                focused = option; break
            end
        end
        if focused then
            self:setCategory(focused.category)
            self:setSelected(focused.id)
        end
    end
    self:requestResponsiveLayout(true)
end

function ISPNCFacilityBuildWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 18, bottom = 12 })
    local gap = Layout.Pixels(10, self.uiScale)
    local buttonHeight = Layout.Pixels(30, self.uiScale)
    local categoryHeight = Layout.Pixels(28, self.uiScale)
    local minimumCategoryWidth = Layout.Pixels(108, self.uiScale)
    local categoryColumns = math.max(1, math.floor((rect.width + gap)
        / (minimumCategoryWidth + gap)))
    categoryColumns = math.max(1, math.min(#self.categoryButtons,
        categoryColumns))
    local categoryWidth = math.floor((rect.width
        - gap * math.max(0, categoryColumns - 1))
        / math.max(1, categoryColumns))
    local categoryRows = math.max(1, math.ceil(#self.categoryButtons
        / math.max(1, categoryColumns)))
    local categoryAreaHeight = categoryRows * categoryHeight
        + gap * math.max(0, categoryRows - 1)
    for index, button in ipairs(self.categoryButtons) do
        local column = (index - 1) % categoryColumns
        local row = math.floor((index - 1) / categoryColumns)
        Layout.SetBounds(button,
            rect.x + column * (categoryWidth + gap),
            rect.y + row * (categoryHeight + gap),
            categoryWidth, categoryHeight)
    end
    local categoryCards, visible = {}, {}
    for _, card in ipairs(self.cards) do
        if card.option.category == self.selectedCategory then
            categoryCards[#categoryCards + 1] = card
        end
    end
    local pageCount = math.max(1, math.ceil(#categoryCards / PAGE_SIZE))
    self.categoryPage = math.max(1, math.min(pageCount,
        tonumber(self.categoryPage) or 1))
    local first = (self.categoryPage - 1) * PAGE_SIZE + 1
    local last = math.min(#categoryCards, first + PAGE_SIZE - 1)
    for _, card in ipairs(self.cards) do card:setVisible(false) end
    for index = first, last do
        local card = categoryCards[index]
        local shown = card ~= nil
        card:setVisible(shown)
        if shown then visible[#visible + 1] = card end
    end

    local pageFooterRows = pageCount > 1 and 2 or 1
    local footerHeight = pageFooterRows * buttonHeight
        + gap * math.max(0, pageFooterRows - 1)
    local descriptionFont = UIFont.Small
    local descriptionLineHeight = math.max(14, fontHeight(descriptionFont))
    local descriptionLines = {}
    local selectedDescription = self.selectedOption
        and tostring(self.selectedOption.description or "") or ""
    if selectedDescription ~= "" then
        descriptionLines = wrapText(selectedDescription, descriptionFont,
            rect.width, 2)
    end
    self.descriptionLines = descriptionLines
    local descriptionHeight = #descriptionLines * descriptionLineHeight
    local footerY = rect.y + rect.height - footerHeight
    local descriptionY = footerY - descriptionHeight
    local cardsBottom = descriptionY
        - (descriptionHeight > 0 and gap or 0)
    local cardsY = rect.y + categoryAreaHeight + gap
    local columns = math.min(4, math.max(1, #visible))
    local width = math.floor((rect.width - gap * (columns - 1)) / columns)
    local rows = math.max(1, math.ceil(#visible / columns))
    local cardsHeight = math.floor((cardsBottom - cardsY
        - gap * math.max(0, rows - 1)) / rows)
    -- The responsive minimum keeps this area usable at supported resolutions.
    -- This guard also prevents a manually shrunk window from making the
    -- cards push into the description or footer.
    cardsHeight = math.max(1, math.min(Layout.Pixels(330, self.uiScale),
        cardsHeight))
    for index, card in ipairs(visible) do
        local column = (index - 1) % columns
        local row = math.floor((index - 1) / columns)
        Layout.SetBounds(card, rect.x + column * (width + gap),
            cardsY + row * (cardsHeight + gap), width, cardsHeight)
    end
    self.descriptionX = rect.x
    self.descriptionY = cardsY + rows * cardsHeight
        + gap * rows

    local debugVisible = canUseDebug()
    self.debugMaterialsButton:setVisible(debugVisible)
    self.debugMaterialsButton:setEnable(debugVisible
        and self.selectedOption ~= nil)

    -- Paging gets its own footer row. Sharing the action row made the
    -- controls overlap whenever a legacy narrow geometry was restored.
    local actionY = footerY + (pageFooterRows - 1) * (buttonHeight + gap)
    local confirmWidth = Layout.Pixels(130, self.uiScale)
    local debugWidth = Layout.Pixels(160, self.uiScale)
    local cancelWidth = Layout.Pixels(110, self.uiScale)
    local actionX = rect.x
    Layout.SetBounds(self.confirmButton, actionX, actionY,
        confirmWidth, buttonHeight)
    actionX = actionX + confirmWidth + gap
    if debugVisible then
        Layout.SetBounds(self.debugMaterialsButton, actionX, actionY,
            debugWidth, buttonHeight)
        actionX = actionX + debugWidth + gap
    end
    local cancelX = rect.x + rect.width - cancelWidth
    -- If the user manually shrinks the window below the responsive minimum,
    -- flow CANCEL after the other actions instead of drawing over them.
    if cancelX < actionX then cancelX = actionX end
    Layout.SetBounds(self.cancelButton, cancelX, actionY,
        cancelWidth, buttonHeight)
    if pageCount > 1 then
        local pageButtonWidth = Layout.Pixels(36, self.uiScale)
        local pageWidth = pageButtonWidth * 2 + gap
        local pageX = rect.x + math.floor((rect.width - pageWidth) / 2)
        Layout.SetBounds(self.previousPageButton, pageX, footerY,
            pageButtonWidth, buttonHeight)
        Layout.SetBounds(self.nextPageButton,
            pageX + pageButtonWidth + gap, footerY,
            pageButtonWidth, buttonHeight)
    end
    self.previousPageButton:setEnable(self.categoryPage > 1)
    self.nextPageButton:setEnable(self.categoryPage < pageCount)
    self.previousPageButton:setVisible(pageCount > 1)
    self.nextPageButton:setVisible(pageCount > 1)
end

function ISPNCFacilityBuildWindow:setCategory(category)
    self.selectedCategory = category
    self.categoryPage = 1
    local first
    for _, option in ipairs(self.options) do
        if option.category == category then first = option; break end
    end
    for _, button in ipairs(self.categoryButtons or {}) do
        UI.SetButtonVariant(button, button.facilityCategory == category
            and "selected" or "quiet")
    end
    self:setSelected(first and first.id or nil)
    self:requestResponsiveLayout(true)
end

function ISPNCFacilityBuildWindow:setCategoryPage(page)
    self.categoryPage = math.max(1, math.floor(tonumber(page) or 1))
    local wanted, count = (self.categoryPage - 1) * PAGE_SIZE + 1, 0
    for _, option in ipairs(self.options) do
        if option.category == self.selectedCategory then
            count = count + 1
            if count == wanted then self:setSelected(option.id); break end
        end
    end
    self:requestResponsiveLayout(true)
end

function ISPNCFacilityBuildWindow:setSelected(id)
    self.selectedId = id
    local option
    for _, value in ipairs(self.options) do
        if value.id == id then option = value; break end
    end
    self.selectedOption = option
    if self.confirmButton then
        self.confirmButton:setEnable(option and option.enabled == true)
    end
    if self.debugMaterialsButton then
        self.debugMaterialsButton:setEnable(canUseDebug() and option ~= nil)
    end
end

function ISPNCFacilityBuildWindow:prerender()
    self:refreshFromSnapshot()
    PsychopatzWindow.prerender(self)
    local option = self.selectedOption
    if option and self.descriptionY and self.descriptionLines then
        local color = Theme.colors.textMuted
        local lineHeight = math.max(14, fontHeight(UIFont.Small))
        for index, line in ipairs(self.descriptionLines) do
            self:drawText(line, self.descriptionX,
                self.descriptionY + (index - 1) * lineHeight,
                color.r, color.g, color.b, color.a or 1, UIFont.Small)
        end
    end
end

function ISPNCFacilityBuildWindow:onAction(button)
    local category = tostring(button.internal or ""):match("^category:(.+)$")
    if category then self:setCategory(category); return end
    if button.internal == "page_previous" then
        self:setCategoryPage((self.categoryPage or 1) - 1); return
    end
    if button.internal == "page_next" then
        self:setCategoryPage((self.categoryPage or 1) + 1); return
    end
    if button.internal == "debug_materials" then
        if canUseDebug() and self.selectedOption then
            local client = PNC.Client
            if client and client.RequestDebugFacilityMaterials then
                local ok = client.RequestDebugFacilityMaterials({
                    definitionId = self.selectedOption.id,
                })
                if ok ~= false then
                    self.debugMaterialsPending = true
                    self.debugMaterialsButton:setEnable(false)
                end
            end
        end
        return
    end
    if button.internal == "build" and self.selectedOption
        and self.selectedOption.enabled
    then
        local started = self.onConfirm
            and self.onConfirm(self.selectedOption.id)
        if started == false then return end
        self:close(started ~= true)
        return
    end
    self:close()
end

function ISPNCFacilityBuildWindow:close(restorePrevious)
    self:setVisible(false); self:removeFromUIManager()
    if BuildUI.instance == self then BuildUI.instance = nil end
    if restorePrevious ~= false and BuildUI.RestorePrevious then
        BuildUI.RestorePrevious()
    end
end

function ISPNCFacilityBuildWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self); self.__index = self
    object.options = options.options or {}
    object.onConfirm = options.onConfirm
    object.focusDefinitionId = options.focusDefinitionId
    object.settlement = options.settlement
    object.storage = options.storage
    object.research = options.research
    object.snapshotRevision = tonumber(options.snapshotRevision) or 0
    object.debugMaterialsPending = false
    object.openArgs = options.openArgs
    return object
end

local function technologyKnown(research, technologyId)
    if not technologyId then return true end
    for _, id in ipairs(research and research.learnedTechnologyIds or {}) do
        if tostring(id) == tostring(technologyId) then return true end
    end
    return false
end

local function stockpileState(settlement)
    local exists, built = false, false
    for _, facility in ipairs(settlement and settlement.facilities or {}) do
        if facility.definitionId == "stockpile" then
            exists = true
            built = facility.constructionState == nil
                or facility.constructionState == "BUILT"
            break
        end
    end
    return exists, built
end

local function facilitySkillProfile(definition)
    local work = PNC.WorkDefinitions
    local profile = work and work.GetStationSkillProfile
        and work.GetStationSkillProfile(definition and definition.stationId)
        or nil
    if type(profile) == "table" and #profile > 0 then return profile end
    return definition and definition.specializationSkills or {}
end

local function buildOptions(settlement, storage, research)
    local values = {}
    local ids = {}
    for id, _ in pairs(PNC.FacilityDefinitions.ByID or {}) do ids[#ids + 1] = id end
    table.sort(ids)
    local stockpileExists, stockpileBuilt = stockpileState(settlement)
    for _, id in ipairs(ids) do
        local definition = PNC.FacilityDefinitions.Get(id)
        local level = PNC.FacilityDefinitions.GetLevel(id, 1)
        if definition and definition.legacyOnly ~= true then
        local buildDescriptor = buildDescriptorFor(definition)
        local skillProfile = facilitySkillProfile(definition)
        local primarySkill = skillProfile[1]
        local skillLabel = primarySkill
            and PNC.WorkDefinitions.GetProductionSkillLabel(primarySkill)
            or tr("UI_PNC_Facility_SkillOther", "Other production")
        local costParts, sourceParts = {}, {}
        local affordable = true
        local costs = recipeFor(definition, buildDescriptor)
        for _, cost in ipairs(costs) do
            local required = math.max(0, math.floor(tonumber(
                cost.amount or cost.quantity) or 0))
            local types = costTypes(cost)
            local stored = stockpileCount(storage, types)
            local fromPlayer = definition.bootstrapFromPlayer == true
                and playerCount(types[1]) or 0
            local available = definition.bootstrapFromPlayer == true
                and fromPlayer or stored
            if available < required then affordable = false end
            costParts[#costParts + 1] = tostring(required) .. " "
                .. costLabel(cost) .. " (" .. tostring(available)
                .. " " .. tr("UI_PNC_Facility_MaterialTotal", "total") .. ")"
            sourceParts[#sourceParts + 1] = tostring(available) .. " "
                .. (definition.bootstrapFromPlayer == true
                    and tr("UI_PNC_Facility_MaterialPlayer", "player")
                    or tr("UI_PNC_Facility_MaterialStockpile", "stockpile"))
        end
        local hqReady = (tonumber(settlement.hqLevel) or 0)
            >= (tonumber(level and level.requiredHQLevel) or 1)
        local technologyReady = technologyKnown(research,
            definition.requiredTechnology)
        local recipeReady = definition.directWorkstation ~= true
            or (buildDescriptor ~= nil and buildDescriptor.nativeOnly ~= true)
        local prerequisiteReady = id == "stockpile" or stockpileBuilt
        local singletonReady = id ~= "stockpile" or not stockpileExists
        local status = not singletonReady and tr(
                "UI_PNC_Facility_StockpileExists", "ALREADY BUILT OR PLANNED")
            or not prerequisiteReady and tr(
                "UI_PNC_Facility_StockpileRequired", "BUILD STOCKPILE FIRST")
            or not recipeReady and tr(
                "UI_PNC_Facility_BuildRecipeUnavailable",
                "BUILD RECIPE UNAVAILABLE")
            or hqReady and affordable and technologyReady
            and tr("UI_PNC_Facility_Available", "AVAILABLE")
            or not hqReady and tr("UI_PNC_Facility_RequiresHQ", "HQ LEVEL TOO LOW")
            or not technologyReady and tr("UI_PNC_Facility_RequiresTechnology",
                "RESEARCH REQUIRED")
            or tr("UI_PNC_Facility_MissingMaterials", "NEED MORE MATERIALS")
        values[#values + 1] = {
            id = id,
            category = productionCategory(definition, buildDescriptor,
                primarySkill),
            name = buildDescriptor and buildDescriptor.displayName
                or tr(definition.displayNameKey, id),
            description = tr(definition.descriptionKey, id),
            texture = descriptorTexture(buildDescriptor)
                or getTexture and definition.iconPath
                and getTexture(definition.iconPath) or nil,
            costText = table.concat(costParts, " | "),
            sourceText = table.concat(sourceParts, " | "),
            skillText = tr("UI_PNC_Facility_Skill", "SKILL") .. ": "
                .. skillLabel,
            productionSkillId = primarySkill,
            productionSkills = skillProfile,
            buildRecipe = buildDescriptor,
            buildRecipeObjectInfoName = buildDescriptor
                and buildDescriptor.objectInfoName or nil,
            buildMaterials = costs,
            requiredTechnology = definition.requiredTechnology,
            directWorkstation = definition.directWorkstation == true,
            enabled = recipeReady and hqReady and affordable and technologyReady
                and prerequisiteReady and singletonReady,
            status = status,
        }
        end
    end
    table.sort(values, function(left, right)
        local leftSkill = PNC.WorkDefinitions and PNC.WorkDefinitions.CRAFTING_SKILL_ORDER
            or {}
        local function rank(option)
            for index, skill in ipairs(leftSkill) do
                if skill == option.productionSkillId then return index end
            end
            return #leftSkill + 1
        end
        local leftRank, rightRank = rank(left), rank(right)
        if leftRank ~= rightRank then return leftRank < rightRank end
        if tostring(left.category) ~= tostring(right.category) then
            return tostring(left.category) < tostring(right.category)
        end
        return tostring(left.name) < tostring(right.name)
    end)
    return values
end

BuildUI.BuildOptions = buildOptions

function ISPNCFacilityBuildWindow:refreshFromSnapshot()
    local client = PNC.ColonyManagementClient
    if not client or type(client.ReadSnapshot) ~= "function" then return end
    local update = client.ReadSnapshot()
    local revision = tonumber(update and update.revision) or 0
    if revision <= (tonumber(self.snapshotRevision) or 0) then return end
    local snapshot = update.snapshot or {}
    local settlement = snapshot.settlement
    if not settlement then return end
    if self.settlement and self.settlement.id
        and tostring(self.settlement.id) ~= tostring(settlement.id)
    then return end

    local selectedId = self.selectedId
    local options = buildOptions(settlement,
        snapshot.storage or self.storage, snapshot.research or self.research)
    local byId = {}
    for _, option in ipairs(options) do byId[option.id] = option end
    for _, card in ipairs(self.cards or {}) do
        local id = card.option and card.option.id
        card.option = id and byId[id] or card.option
    end
    self.options = options
    self.settlement = settlement
    self.storage = snapshot.storage or self.storage
    self.research = snapshot.research or self.research
    if BuildUI.lastOpenArgs then
        BuildUI.lastOpenArgs.settlement = self.settlement
        BuildUI.lastOpenArgs.storage = self.storage
        BuildUI.lastOpenArgs.research = self.research
    end
    self.snapshotRevision = revision
    self.debugMaterialsPending = false
    self:setSelected(selectedId)
    self:requestResponsiveLayout(true)
end

function BuildUI.RestorePrevious()
    local previous = BuildUI.previousWindow
    local shouldRestore = BuildUI.previousWindowWasVisible
    BuildUI.previousWindow = nil
    BuildUI.previousWindowWasVisible = false
    if not previous or not shouldRestore then return end
    if type(previous.addToUIManager) == "function" then
        previous:addToUIManager()
    end
    if type(previous.setVisible) == "function" then
        previous:setVisible(true)
    end
    if type(previous.bringToTop) == "function" then
        previous:bringToTop()
    end
end

function BuildUI.Reopen()
    local args = BuildUI.lastOpenArgs
    if not args then return nil end
    return BuildUI.Open(args.settlement, args.onConfirm, args.storage,
        args.research, args.focusDefinitionId)
end

function BuildUI.Open(settlement, onConfirm, storage, research,
    focusDefinitionId)
    if not settlement then return nil end
    if BuildUI.instance then BuildUI.instance:close(false) end
    if not BuildUI.previousWindow then
        local colonyUI = PNC.ColonyManagementUI
        local previous = colonyUI and colonyUI.instance or nil
        if previous and previous ~= BuildUI.instance then
            BuildUI.previousWindow = previous
            BuildUI.previousWindowWasVisible = type(previous.isVisible)
                ~= "function" or previous:isVisible()
            if type(previous.setVisible) == "function" then
                previous:setVisible(false)
            end
            if type(previous.removeFromUIManager) == "function" then
                previous:removeFromUIManager()
            end
        end
    end
    BuildUI.lastOpenArgs = {
        settlement = settlement, onConfirm = onConfirm,
        storage = storage, research = research,
        focusDefinitionId = focusDefinitionId,
    }
    local options = buildOptions(settlement, storage, research)
    local spec = facilityWindowSpec()
    local bounds = Layout.ResolveWindow(spec)
    local window = ISPNCFacilityBuildWindow:new(
        bounds.x, bounds.y, bounds.width, bounds.height, {
            title = tr("UI_PNC_Facility_BuildTitle", "BUILD A BUILDING"),
            options = options, onConfirm = onConfirm,
            focusDefinitionId = focusDefinitionId,
            responsiveSpec = spec,
            -- This modal should follow the current screen, not restore the
            -- old 520x360 geometry that caused the clipped build screen.
            persistenceKey = false,
            resizable = true,
            settlement = settlement, storage = storage, research = research,
            snapshotRevision = PNC.Network and PNC.Network.ClientState
                and PNC.Network.ClientState.colonyManagementRevision or 0,
            openArgs = BuildUI.lastOpenArgs,
        })
    window:initialise(); window:instantiate(); window:addToUIManager()
    window:setVisible(true)
    if window.setAlwaysOnTop then window:setAlwaysOnTop(true) end
    window:bringToTop(); BuildUI.instance = window
    return window
end

return BuildUI
