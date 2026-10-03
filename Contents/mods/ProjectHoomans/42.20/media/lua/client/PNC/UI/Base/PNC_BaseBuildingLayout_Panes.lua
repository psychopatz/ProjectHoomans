local Panes = {}

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

end

return Panes
