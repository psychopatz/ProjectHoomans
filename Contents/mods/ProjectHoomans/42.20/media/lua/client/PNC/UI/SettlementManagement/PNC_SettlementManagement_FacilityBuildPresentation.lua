-- Facility build window presentation and selection.
--
-- This provider owns child controls, responsive layout, category navigation,
-- selection state, and description rendering. The modal root retains class
-- setup and lifecycle while the interaction provider owns build requests.

local BuildUI = PNC.FacilityBuildUI
local Internal = BuildUI.Internal
local UI = Internal.UI
local Layout = Internal.Layout
local Theme = Internal.Theme
local tr = Internal.Translate
local canUseDebug = Internal.CanUseDebug
local FacilityCard = Internal.FacilityCard
local CATEGORY_ORDER = Internal.CategoryOrder
local CATEGORY_LABELS = Internal.CategoryLabels
local PAGE_SIZE = Internal.PageSize
local fontHeight = Internal.CardFontHeight
local textWidth = Internal.CardTextWidth
local fitText = Internal.CardFitText
local wrapText = Internal.CardWrapText

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


local function layoutFacilityCategories(self, rect, gap, categoryHeight)
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
    return categoryAreaHeight
end

local function collectVisibleFacilityCards(self)
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
    return pageCount, visible
end

local function prepareFacilityFooter(self, rect, gap, buttonHeight, pageCount)
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
    -- The failure line shares the description block so the footer and cards
    -- keep their spacing whether or not a build error is showing.
    local errorLines = {}
    if self.buildError and tostring(self.buildError) ~= "" then
        errorLines = wrapText(tostring(self.buildError), descriptionFont,
            rect.width, 1)
    end
    self.descriptionLines = descriptionLines
    self.buildErrorLines = errorLines
    local descriptionHeight = (#descriptionLines + #errorLines)
        * descriptionLineHeight
    local footerY = rect.y + rect.height - footerHeight
    local descriptionY = footerY - descriptionHeight
    local cardsBottom = descriptionY
        - (descriptionHeight > 0 and gap or 0)
    return pageFooterRows, footerHeight, footerY, cardsBottom
end

local function layoutFacilityCards(self, rect, gap, cardsY, cardsBottom, visible)
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
end

local function layoutFacilityControls(self, rect, gap, buttonHeight, footerY, pageFooterRows, pageCount)
    local debugVisible = canUseDebug()
    self.debugMaterialsButton:setVisible(debugVisible)
    self.debugMaterialsButton:setEnable(debugVisible
        and self.selectedOption ~= nil)

    -- Paging gets its own footer row. Sharing the action row made the
    -- controls overlap when the available window geometry is too narrow.
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

function ISPNCFacilityBuildWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 18, bottom = 12 })
    local gap = Layout.Pixels(10, self.uiScale)
    local buttonHeight = Layout.Pixels(30, self.uiScale)
    local categoryHeight = Layout.Pixels(28, self.uiScale)
    local categoryAreaHeight = layoutFacilityCategories(self, rect, gap, categoryHeight)
    local pageCount, visible = collectVisibleFacilityCards(self)
    local pageFooterRows, footerHeight, footerY, cardsBottom =
        prepareFacilityFooter(self, rect, gap, buttonHeight, pageCount)
    local cardsY = rect.y + categoryAreaHeight + gap
    layoutFacilityCards(self, rect, gap, cardsY, cardsBottom, visible)
    layoutFacilityControls(self, rect, gap, buttonHeight, footerY, pageFooterRows, pageCount)
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
    self.buildError = nil
    if self.confirmButton then
        self.confirmButton:setEnable(option and option.enabled == true)
    end
    if self.debugMaterialsButton then
        self.debugMaterialsButton:setEnable(canUseDebug() and option ~= nil)
    end
end

-- Show why a build attempt was rejected instead of silently closing. The
-- reason may be a settlement reason code or a raw placement code.

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
        local errorLines = self.buildErrorLines or {}
        if #errorLines > 0 then
            local danger = Theme.colors.danger
            for index, line in ipairs(errorLines) do
                self:drawText(line, self.descriptionX,
                    self.descriptionY
                        + (#self.descriptionLines + index - 1) * lineHeight,
                    danger.r, danger.g, danger.b, danger.a or 1, UIFont.Small)
            end
        end
    end
end


return BuildUI

