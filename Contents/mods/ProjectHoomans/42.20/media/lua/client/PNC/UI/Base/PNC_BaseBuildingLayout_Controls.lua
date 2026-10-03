require "PsychopatzCore/UI/PsychopatzUI"

local Controls = {}
local UI = PsychopatzCore.UI
local Theme = UI.Theme

function Controls.ApplyCategories(window, content, Layout, gap, buttonHeight, width)
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
    return toolbarY
end

function Controls.BuildFooter(window, content, Layout, width, height, gap,
    buttonHeight, toolbarY)
    local footerActions = {}
    for _, control in ipairs({ window.baseBuildingBuildButton,
        window.baseBuildingDebugButton, window.baseBuildingCancelPlacement,
        window.baseBuildingQueueOverlay }) do
        if control and control:getIsVisible() then
            footerActions[#footerActions + 1] = control
        end
    end
    local cancelWidth = Layout.Pixels(110, window.uiScale)
    local controlPadding = Layout.Pixels(30, window.uiScale)
    local minimumControl = Layout.Pixels(104, window.uiScale)
    local maximumControl = Layout.Pixels(220, window.uiScale)
    local titleFont = Theme and Theme.Font and Theme.Font(window.uiScale)
        or (UIFont and UIFont.Small) or nil
    local function controlWidth(control)
        local title = control and control.title
        local measured = 0
        if type(title) == "string" and title ~= ""
            and titleFont and Theme and type(Theme.TextWidth) == "function"
        then
            measured = tonumber(Theme.TextWidth(titleFont, title)) or 0
        end
        return math.max(minimumControl, math.min(maximumControl,
            math.floor(measured + controlPadding)))
    end
    -- Every row reserves the CANCEL column, so the right-aligned CANCEL can
    -- never overlap an action button.
    local rowLimit = math.max(minimumControl,
        width - cancelWidth - Layout.Pixels(12, window.uiScale))
    local footerRows, currentRow = {}, nil
    for _, control in ipairs(footerActions) do
        local controlWidthValue = controlWidth(control)
        local extra = currentRow and #currentRow.items > 0 and gap or 0
        if not currentRow or (currentRow.width + extra + controlWidthValue
            > rowLimit and #currentRow.items > 0)
        then
            currentRow = { width = 0, items = {} }
            footerRows[#footerRows + 1] = currentRow
            extra = 0
        end
        currentRow.items[#currentRow.items + 1] = {
            control = control, width = controlWidthValue,
        }
        currentRow.width = currentRow.width + extra + controlWidthValue
    end
    if #footerRows == 0 then footerRows[1] = { width = 0, items = {} } end

    --[[
        Vertical budget.

        The bands are carved out of one remaining height instead of each
        clamping itself with its own floor. The previous floors could exceed the
        space left by the footer, which pushed the requirements and blueprint
        bands into the footer (and each other) at smaller window sizes.
    ]]
    local footerHeight = buttonHeight * #footerRows
        + gap * math.max(0, #footerRows - 1)
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

    return {
        width = width,
        height = height,
        gap = gap,
        buttonHeight = buttonHeight,
        cancelWidth = cancelWidth,
        footerRows = footerRows,
        footerHeight = footerHeight,
        cardsY = cardsY,
        footerY = footerY,
        detailsHeight = detailsHeight,
        lowerHeight = lowerHeight,
        cardsHeight = cardsHeight,
    }
end

function Controls.ApplyFooter(window, content, Layout, metrics)
    local width = metrics.width
    local gap = metrics.gap
    local buttonHeight = metrics.buttonHeight
    local cancelWidth = metrics.cancelWidth
    local footerRows = metrics.footerRows
    local footerHeight = metrics.footerHeight
    local footerY = metrics.footerY
    for rowIndex, row in ipairs(footerRows) do
        local rowY = footerY + (rowIndex - 1) * (buttonHeight + gap)
        local x = content.x
        for _, entry in ipairs(row.items) do
            Layout.SetBounds(entry.control, x, rowY, entry.width, buttonHeight)
            x = x + entry.width + gap
        end
    end
    Layout.SetBounds(window.baseBuildingCloseButton,
        content.x + width - cancelWidth,
        footerY + (footerHeight - buttonHeight), cancelWidth, buttonHeight)
    local pageCount = tonumber(window.baseBuildingPageCount) or 1
    window.baseBuildingPrevious:setVisible(pageCount > 1)
    window.baseBuildingNext:setVisible(pageCount > 1)
    window.baseBuildingPrevious:setEnable(window.baseBuildingPage > 1)
    window.baseBuildingNext:setEnable(window.baseBuildingPage < pageCount)
end

return Controls
