local Panes = {}
local MINIMUM_MATERIAL_WIDTH = 320
local MINIMUM_QUEUE_WIDTH = 220
local SPLITTER_HIT_WIDTH = 16

function Panes.Apply(window, content, Layout, metrics)
    local gap = metrics.gap
    local width = metrics.width
    local cardsY = metrics.cardsY
    local detailsHeight = metrics.detailsHeight
    local lowerHeight = metrics.lowerHeight
    local cardsHeight = metrics.cardsHeight
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
    local splitterWidth = Layout.Pixels(SPLITTER_HIT_WIDTH,
        window.uiScale or 1)
    -- Clamp the split so the requirements pane can never be squeezed to zero
    -- or pushed left of the content rect by a narrow window.
    local split = Layout.HorizontalSplit({
        x = content.x,
        y = lowerY,
        width = width,
        height = lowerHeight,
    }, {
        -- metrics.gap is already scaled by the Base layout. Keep the Core
        -- splitter from scaling that value a second time, while still
        -- scaling the pane minimums with this window.
        scale = 1,
        gap = gap,
        firstRatio = window.baseBuildingLowerSplitRatio or 0.66,
        minFirst = Layout.Pixels(MINIMUM_MATERIAL_WIDTH,
            window.uiScale or 1),
        minSecond = Layout.Pixels(MINIMUM_QUEUE_WIDTH,
            window.uiScale or 1),
    })
    local materialWidth = split.first.width
    local queueWidth = split.second.width
    window.baseBuildingLowerSplitAvailable = split.available
    window.baseBuildingLowerSplitRatio = split.first.width / split.available
    -- The lists carry their own 25px section heading; layoutContent() offsets
    -- the rows below it. Without it the rows drew inside the heading band,
    -- which is what made REQUIREMENTS and BLUEPRINT QUEUE look misplaced.
    if window.layoutPane then
        window:layoutPane(window.baseBuildingMaterialPane, content.x, lowerY,
            materialWidth, lowerHeight)
        window:layoutPane(window.baseBuildingNativeQueuePane,
            split.second.x, lowerY, queueWidth, lowerHeight)
    else
        Layout.SetBounds(window.baseBuildingMaterialPane, content.x, lowerY,
            materialWidth, lowerHeight)
        Layout.SetBounds(window.baseBuildingNativeQueuePane,
            split.second.x, lowerY, queueWidth, lowerHeight)
        if window.baseBuildingMaterialPane.layoutContent then
            window.baseBuildingMaterialPane:layoutContent()
        end
        if window.baseBuildingNativeQueuePane.layoutContent then
            window.baseBuildingNativeQueuePane:layoutContent()
        end
    end

    local divider = window.baseBuildingLowerSplitDivider
    if divider then
        Layout.SetBounds(divider,
            content.x + split.first.width
                + math.floor((split.gap - splitterWidth) / 2),
            lowerY, splitterWidth, lowerHeight)
        divider:setRange(split.minimumFirst, split.maximumFirst)
        divider:setValue(split.first.width, true)
        divider:bringToTop()
    end
end

return Panes
