local Layout = {}

local function applyToolbar(window, LayoutApi, content, width, gap, debugAvailable)
    local buttons = {
        window.buildPlace,
        window.buildCancelPlacement,
    }
    if debugAvailable then buttons[#buttons + 1] = window.buildGetItems end
    buttons[#buttons + 1] = window.buildQueueOverlay
    buttons[#buttons + 1] = window.buildCancelOrder
    local buttonColumns = width < 800 and 2 or #buttons
    local buttonRows = width < 800
        and math.floor((#buttons + buttonColumns - 1) / buttonColumns) or 1
    local buttonHeight = 27
    local toolbarHeight = buttonRows * buttonHeight
        + (buttonRows - 1) * gap
    for index, control in ipairs(buttons) do
        local row = math.floor((index - 1) / buttonColumns)
        local column = (index - 1) % buttonColumns
        local remaining = #buttons - row * buttonColumns
        local columnsInRow = math.min(buttonColumns, remaining)
        local buttonWidth = math.floor((width
            - gap * (columnsInRow - 1)) / columnsInRow)
        local x = content.x + column * (buttonWidth + gap)
        LayoutApi.SetBounds(control, x, content.y + row
            * (buttonHeight + gap), buttonWidth, buttonHeight)
    end

    return toolbarHeight
end

local function applyCompactLayout(
    window, LayoutApi, content, top, width, height, gap
)
    -- Small screens use a 2x2 grid.  This keeps the recipe name column
    -- readable while retaining the queue and stock information below it.
    local categoryWidth = math.floor(width * 0.25)
    categoryWidth = math.max(1, math.min(categoryWidth,
        math.max(1, width - gap - 1)))
    local recipeX = content.x + categoryWidth + gap
    local recipeWidth = math.max(1, width - categoryWidth - gap)
    local topHeight = math.floor((height - gap) * 0.54)
    topHeight = math.max(1, math.min(topHeight, height))
    local bottomY = top + topHeight + gap
    local bottomHeight = math.max(1, height - topHeight - gap)
    local queueWidth = math.floor((width - gap) * 0.58)
    queueWidth = math.max(1, math.min(queueWidth,
        math.max(1, width - gap - 1)))
    local materialX = content.x + queueWidth + gap
    local materialWidth = math.max(1, width - queueWidth - gap)
    local controlHeight = 27
    local controlGap = 6
    local favoriteWidth = 112
    local filterWidth = 126
    local searchWidth = math.max(80, recipeWidth - favoriteWidth
        - filterWidth - controlGap * 2)
    local favoriteX = recipeX + searchWidth + controlGap
    local filterX = favoriteX + favoriteWidth + controlGap
    LayoutApi.SetBounds(window.buildCategoryList, content.x, top,
        categoryWidth, topHeight)
    LayoutApi.SetBounds(window.buildSearch, recipeX, top, searchWidth,
        controlHeight)
    LayoutApi.SetBounds(window.buildFavoriteButton, favoriteX, top,
        favoriteWidth, controlHeight)
    LayoutApi.SetBounds(window.buildFavoritesFilter, filterX, top,
        filterWidth, controlHeight)
    local recipeListTop = top + controlHeight + controlGap
    LayoutApi.SetBounds(window.buildRecipeList, recipeX, recipeListTop,
        recipeWidth, math.max(1, topHeight - controlHeight - controlGap))
    LayoutApi.SetBounds(window.buildQueueList, content.x, bottomY,
        queueWidth, bottomHeight)
    LayoutApi.SetBounds(window.buildMaterialList, materialX, bottomY,
        materialWidth, bottomHeight)
    if window.buildRecipePreview then
        window.buildRecipePreview:setVisible(false)
    end
    return
end

local function applyWideLayout(
    window, LayoutApi, content, top, width, height, gap
)
    local left = math.floor(width * 0.20)
    local middle = math.floor(width * 0.39)
    local right = math.max(1, width - left - middle - gap * 2)
    local middleX = content.x + left + gap
    local rightX = middleX + middle + gap
    LayoutApi.SetBounds(window.buildCategoryList, content.x, top, left, height)
    local controlHeight = 27
    local controlGap = 6
    local favoriteWidth = 112
    local filterWidth = 126
    local searchWidth = math.max(80, middle - favoriteWidth - filterWidth
        - controlGap * 2)
    local favoriteX = middleX + searchWidth + controlGap
    local filterX = favoriteX + favoriteWidth + controlGap
    LayoutApi.SetBounds(window.buildSearch, middleX, top, searchWidth,
        controlHeight)
    LayoutApi.SetBounds(window.buildFavoriteButton, favoriteX, top,
        favoriteWidth, controlHeight)
    LayoutApi.SetBounds(window.buildFavoritesFilter, filterX, top,
        filterWidth, controlHeight)
    local recipeListTop = top + controlHeight + controlGap
    LayoutApi.SetBounds(window.buildRecipeList, middleX, recipeListTop, middle,
        math.max(1, height - controlHeight - controlGap))
    local previewHeight = math.max(130, math.min(210,
        math.floor(height * 0.30)))
    if window.buildRecipePreview then
        LayoutApi.SetBounds(window.buildRecipePreview, rightX, top, right,
            previewHeight)
        window.buildRecipePreview:setVisible(window.tab == "buildings")
    end
    local lowerTop = top + previewHeight + gap
    local lowerHeight = math.max(1, height - previewHeight - gap)
    local queueHeight = math.max(1, math.floor(lowerHeight * 0.48))
    LayoutApi.SetBounds(window.buildQueueList, rightX, lowerTop, right,
        queueHeight)
    LayoutApi.SetBounds(window.buildMaterialList, rightX,
        lowerTop + queueHeight + gap, right, math.max(1,
            lowerHeight - queueHeight - gap))
end

function Layout.Apply(window, LayoutApi, content, recipeColumns, compactRecipeColumns)
    local gap = 8
    local width = math.max(1, tonumber(content.width) or 1)
    local debugAvailable = PNC.Client and PNC.Client.CanUseDebug
        and PNC.Client.CanUseDebug() == true
    window.buildDebugAvailable = debugAvailable
    local toolbarHeight = applyToolbar(
        window, LayoutApi, content, width, gap, debugAvailable
    )
    local top = content.y + toolbarHeight + gap
    local height = math.max(1, (tonumber(content.height) or 1)
        - toolbarHeight - gap)
    local compact = width < 1000 or height < 600
    window.buildRecipeList.catalogColumns = compact
        and compactRecipeColumns or recipeColumns
    local rowHeight = compact and height < 520 and 28 or 32
    window.buildRecipePreviewCompact = compact
    for _, list in ipairs({ window.buildCategoryList,
        window.buildRecipeList, window.buildQueueList,
        window.buildMaterialList }) do
        list.itemheight = rowHeight
    end

    if compact then
        applyCompactLayout(
            window, LayoutApi, content, top, width, height, gap
        )
        return
    end

    applyWideLayout(
        window, LayoutApi, content, top, width, height, gap
    )

end


return Layout
