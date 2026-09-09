require "PsychopatzCore/UI/PsychopatzUI"

local LayoutModel = {}
local Layout = PsychopatzCore.UI.Layout

function LayoutModel.Apply(window, content)
    local gap = Layout.Pixels(8, window.uiScale)
    local buttonHeight = Layout.Pixels(28, window.uiScale)
    local width, height = content.width, content.height
    local categories = {}
    for _, button in ipairs(window.baseBuildingCategoryButtons or {}) do
        if button:getIsVisible() then categories[#categories + 1] = button end
    end
    local categoryGap = Layout.Pixels(6, window.uiScale)
    local minimumCategoryWidth = Layout.Pixels(112, window.uiScale)
    local categoryColumns = math.max(1, math.floor((width + categoryGap)
        / (minimumCategoryWidth + categoryGap)))
    categoryColumns = math.min(categoryColumns,
        math.max(1, #categories))
    local categoryWidth = math.max(Layout.Pixels(92, window.uiScale),
        math.floor((width - categoryGap * (categoryColumns - 1))
            / categoryColumns))
    for index, button in ipairs(categories) do
        local row = math.floor((index - 1) / categoryColumns)
        local column = (index - 1) % categoryColumns
        Layout.SetBounds(button, content.x + column
            * (categoryWidth + categoryGap), content.y + row
            * (buttonHeight + categoryGap), categoryWidth, buttonHeight)
    end
    local categoryRows = #categories > 0
        and math.ceil(#categories / categoryColumns) or 0
    local categoryHeight = categoryRows > 0
        and categoryRows * buttonHeight + (categoryRows - 1) * categoryGap or 0
    local toolbarY = content.y + categoryHeight + gap
    local searchWidth = math.max(Layout.Pixels(150, window.uiScale),
        math.floor(width * 0.42))
    Layout.SetBounds(window.baseBuildingSearch, content.x, toolbarY,
        searchWidth, buttonHeight)
    local pageWidth = Layout.Pixels(36, window.uiScale)
    Layout.SetBounds(window.baseBuildingPrevious, content.x + width
        - pageWidth * 2 - gap, toolbarY, pageWidth, buttonHeight)
    Layout.SetBounds(window.baseBuildingNext, content.x + width - pageWidth,
        toolbarY, pageWidth, buttonHeight)

    local footerHeight = buttonHeight
    local detailsHeight = math.max(Layout.Pixels(64, window.uiScale),
        math.min(Layout.Pixels(82, window.uiScale), math.floor(height * 0.16)))
    local lowerHeight = math.max(Layout.Pixels(96, window.uiScale),
        math.min(Layout.Pixels(170, window.uiScale), math.floor(height * 0.30)))
    local cardsY = toolbarY + buttonHeight + gap
    local cardsBottom = content.y + height - footerHeight - detailsHeight
        - lowerHeight - gap * 4
    local cardsHeight = math.max(Layout.Pixels(110, window.uiScale),
        cardsBottom - cardsY)
    local cards = {}
    for _, card in ipairs(window.baseBuildingCards or {}) do
        if card:getIsVisible() then cards[#cards + 1] = card end
    end
    local columns = math.min(4, math.max(1, #cards))
    local cardWidth = math.max(1, math.floor((width - gap * (columns - 1))
        / columns))
    for index, card in ipairs(cards) do
        Layout.SetBounds(card, content.x + (index - 1)
            * (cardWidth + gap), cardsY, cardWidth, cardsHeight)
    end
    local detailsY = cardsY + cardsHeight + gap
    Layout.SetBounds(window.baseBuildingDetails, content.x, detailsY,
        width, detailsHeight)
    local lowerY = detailsY + detailsHeight + gap
    local queueWidth = math.max(Layout.Pixels(220, window.uiScale),
        math.floor(width * 0.34))
    Layout.SetBounds(window.baseBuildingMaterialPane, content.x, lowerY,
        width - queueWidth - gap, lowerHeight)
    Layout.SetBounds(window.baseBuildingNativeQueuePane,
        content.x + width - queueWidth, lowerY, queueWidth, lowerHeight)
    local footerY = content.y + height - footerHeight
    local controls = { window.baseBuildingBuildButton,
        window.baseBuildingDebugButton, window.baseBuildingCancelPlacement,
        window.baseBuildingQueueOverlay }
    local x = content.x
    for _, control in ipairs(controls) do
        if control:getIsVisible() then
            local desired = control == window.baseBuildingBuildButton
                and Layout.Pixels(120, window.uiScale)
                or Layout.Pixels(132, window.uiScale)
            Layout.SetBounds(control, x, footerY, desired, footerHeight)
            x = x + desired + gap
        end
    end
    local cancelWidth = Layout.Pixels(110, window.uiScale)
    Layout.SetBounds(window.baseBuildingCloseButton,
        content.x + width - cancelWidth, footerY, cancelWidth, footerHeight)
    local pageCount = tonumber(window.baseBuildingPageCount) or 1
    window.baseBuildingPrevious:setVisible(pageCount > 1)
    window.baseBuildingNext:setVisible(pageCount > 1)
    window.baseBuildingPrevious:setEnable(window.baseBuildingPage > 1)
    window.baseBuildingNext:setEnable(window.baseBuildingPage < pageCount)
end

return LayoutModel
