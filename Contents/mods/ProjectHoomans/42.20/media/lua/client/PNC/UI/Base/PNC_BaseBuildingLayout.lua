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

    --[[
        Vertical budget.

        The bands are carved out of one remaining height instead of each
        clamping itself with its own floor. The previous floors could exceed the
        space left by the footer, which pushed the requirements and blueprint
        bands into the footer (and each other) at smaller window sizes.
    ]]
    local footerHeight = buttonHeight
    local cardsY = toolbarY + buttonHeight + gap
    local footerY = content.y + height - footerHeight
    local remaining = footerY - cardsY - gap * 3
    local detailsHeight = math.max(Layout.Pixels(52, window.uiScale),
        math.min(Layout.Pixels(72, window.uiScale), math.floor(height * 0.14)))
    local lowerHeight = math.max(Layout.Pixels(96, window.uiScale),
        math.min(Layout.Pixels(170, window.uiScale), math.floor(height * 0.30)))
    local minimumCards = Layout.Pixels(96, window.uiScale)
    local cardsHeight = remaining - detailsHeight - lowerHeight
    if cardsHeight < minimumCards then
        -- Take the shortfall from the lower band first, then the details band.
        local deficit = minimumCards - cardsHeight
        local lowerFloor = Layout.Pixels(72, window.uiScale)
        local lowerCut = math.min(deficit, math.max(0, lowerHeight - lowerFloor))
        lowerHeight = lowerHeight - lowerCut
        deficit = deficit - lowerCut
        local detailsFloor = Layout.Pixels(38, window.uiScale)
        local detailsCut = math.min(deficit,
            math.max(0, detailsHeight - detailsFloor))
        detailsHeight = detailsHeight - detailsCut
        deficit = deficit - detailsCut
        cardsHeight = remaining - detailsHeight - lowerHeight
        if deficit > 0 then
            -- Genuinely too short: keep the bands inside the window and let
            -- the lists absorb the loss rather than overlapping the footer.
            cardsHeight = math.max(1, cardsHeight)
        end
    end
    local cards = {}
    for _, card in ipairs(window.baseBuildingCards or {}) do
        if card:getIsVisible() then cards[#cards + 1] = card end
    end
    local columns = math.min(4, math.max(1, #cards))
    -- Never stretch a single facility across the whole window: a full-width
    -- card centres its text over empty space and reads as a broken layout.
    local maxCardWidth = Layout.Pixels(300, window.uiScale)
    local cardWidth = math.floor((width - gap * (columns - 1)) / columns)
    cardWidth = math.max(1, math.min(cardWidth, maxCardWidth))
    local rowWidth = cardWidth * columns + gap * (columns - 1)
    local cardX = content.x + math.max(0, math.floor((width - rowWidth) / 2))
    for index, card in ipairs(cards) do
        Layout.SetBounds(card, cardX + (index - 1) * (cardWidth + gap),
            cardsY, cardWidth, cardsHeight)
    end
    local detailsY = cardsY + cardsHeight + gap
    Layout.SetBounds(window.baseBuildingDetails, content.x, detailsY,
        width, detailsHeight)
    local lowerY = detailsY + detailsHeight + gap
    -- Clamp the split so the requirements pane can never be squeezed to zero
    -- or pushed left of the content rect by a narrow window.
    local queueWidth = math.min(
        math.max(Layout.Pixels(220, window.uiScale),
            math.floor(width * 0.34)),
        math.max(Layout.Pixels(140, window.uiScale),
            math.floor(width * 0.5)))
    local materialWidth = math.max(1, width - queueWidth - gap)
    -- The lists carry their own 25px section heading; layoutContent() offsets
    -- the rows below it. Without it the rows drew inside the heading band,
    -- which is what made REQUIREMENTS and BLUEPRINT QUEUE look misplaced.
    if window.layoutPane then
        window:layoutPane(window.baseBuildingMaterialPane, content.x, lowerY,
            materialWidth, lowerHeight)
        window:layoutPane(window.baseBuildingNativeQueuePane,
            content.x + materialWidth + gap, lowerY, queueWidth, lowerHeight)
    else
        Layout.SetBounds(window.baseBuildingMaterialPane, content.x, lowerY,
            materialWidth, lowerHeight)
        Layout.SetBounds(window.baseBuildingNativeQueuePane,
            content.x + materialWidth + gap, lowerY, queueWidth, lowerHeight)
        if window.baseBuildingMaterialPane.layoutContent then
            window.baseBuildingMaterialPane:layoutContent()
        end
        if window.baseBuildingNativeQueuePane.layoutContent then
            window.baseBuildingNativeQueuePane:layoutContent()
        end
    end
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
