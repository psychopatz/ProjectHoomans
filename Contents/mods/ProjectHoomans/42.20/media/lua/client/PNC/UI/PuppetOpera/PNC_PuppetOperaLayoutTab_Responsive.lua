-- Responsive geometry for the Puppet Opera layout editor.

PNC = PNC or {}

local Internal = PNC.PuppetOperaLayoutTabInternal
local Layout = Internal.Layout
local resizeRows = Internal.resizeRows
local Class = ISPNCPuppetOperaLayoutTab

function Class:onResponsiveLayout()
    local scale = self.ownerWindow and self.ownerWindow.uiScale
    local pad = Layout.Pixels(8, scale)
    local gap = Layout.Pixels(8, scale)
    local width = self:getWidth()
    local height = self:getHeight()
    local compact = height < Layout.Pixels(430, scale)
    local actorRowHeight = Layout.Pixels(compact and 36 or 48, scale)
    local liveRowHeight = Layout.Pixels(compact and 36 or 44, scale)
    resizeRows(self.actorList, actorRowHeight)
    resizeRows(self.liveList, liveRowHeight)
    resizeRows(self.details, Layout.Pixels(25, scale))
    if self.actorList then self.actorList.uiScale = scale end
    if self.liveList then self.liveList.uiScale = scale end
    local columnsWidth = math.max(1, width - pad * 2 - gap * 2)
    local stacked = width < Layout.Pixels(720, scale)
        or columnsWidth < Layout.Pixels(430, scale)
    if stacked then
        local heading = Layout.Pixels(20, scale)
        local rowBlock = math.max(Layout.Pixels(70, scale),
            math.floor(height * 0.22))
        local listWidth = math.max(1, width - pad * 2)
        local sceneHeight = math.max(Layout.Pixels(36, scale),
            math.floor(rowBlock * 0.48))
        local liveTop = pad + heading + sceneHeight + gap + heading
        local liveHeight = math.max(Layout.Pixels(36, scale),
            math.floor(rowBlock * 0.48))
        local gridTop = liveTop + liveHeight + gap
        local detailsHeight = math.max(Layout.Pixels(1, scale),
            height - gridTop - Layout.Pixels(96, scale))
        local gridHeight = math.max(Layout.Pixels(100, scale),
            math.floor(detailsHeight * 0.62))
        local detailsTop = gridTop + gridHeight + gap
        local removeHeight = Layout.Pixels(26, scale)
        Layout.SetBounds(self.actorList, pad, pad + heading,
            listWidth, sceneHeight)
        Layout.SetBounds(self.liveList, pad, liveTop,
            listWidth, liveHeight)
        Layout.SetBounds(self.grid, pad, gridTop, listWidth, gridHeight)
        Layout.SetBounds(self.details, pad, detailsTop,
            listWidth, math.max(1, height - detailsTop - removeHeight
                - pad - gap))
        Layout.SetBounds(self.addButton, pad, height - pad - removeHeight,
            math.max(1, math.floor((listWidth - gap) / 2)), removeHeight)
        Layout.SetBounds(self.removeButton,
            pad + math.floor((listWidth - gap) / 2) + gap,
            height - pad - removeHeight,
            math.max(1, math.ceil((listWidth - gap) / 2)), removeHeight)
        self.stackedLayout = true
        return
    end
    self.stackedLayout = false
    local leftWidth = math.floor(columnsWidth * 0.24)
    local rightWidth = math.floor(columnsWidth * 0.28)
    local centerWidth = columnsWidth - leftWidth - rightWidth
    if centerWidth < Layout.Pixels(220, scale) then
        leftWidth = math.floor(columnsWidth * 0.20)
        rightWidth = math.floor(columnsWidth * 0.25)
        centerWidth = columnsWidth - leftWidth - rightWidth
    end
    leftWidth = math.max(Layout.Pixels(112, scale), leftWidth)
    rightWidth = math.max(Layout.Pixels(132, scale), rightWidth)
    if leftWidth + rightWidth >= columnsWidth then
        leftWidth = math.max(1, math.floor(columnsWidth * 0.25))
        rightWidth = math.max(1, math.floor(columnsWidth * 0.28))
    end
    centerWidth = math.max(1, columnsWidth - leftWidth - rightWidth)
    centerWidth = math.max(1, centerWidth)

    local leftX = pad
    local leftTop = Layout.Pixels(22, scale)
    local leftBottom = height - pad
    local liveHeadingHeight = Layout.Pixels(20, scale)
    local availableLeft = math.max(1,
        leftBottom - leftTop - gap - liveHeadingHeight)
    local sceneHeight = math.floor(availableLeft * (compact and 0.42 or 0.46))
    local minSceneHeight = math.min(availableLeft,
        math.max(Layout.Pixels(36, scale), actorRowHeight))
    local minLiveHeight = math.min(availableLeft,
        math.max(Layout.Pixels(32, scale), liveRowHeight))
    if availableLeft >= minSceneHeight + minLiveHeight then
        sceneHeight = math.max(minSceneHeight,
            math.min(availableLeft - minLiveHeight, sceneHeight))
    else
        sceneHeight = math.max(1, availableLeft - minLiveHeight)
    end
    local liveTop = leftTop + sceneHeight + gap + Layout.Pixels(20, scale)
    local liveHeight = math.max(1, leftBottom - liveTop)
    Layout.SetBounds(self.actorList, leftX, leftTop, leftWidth, sceneHeight)
    Layout.SetBounds(self.liveList, leftX, liveTop, leftWidth, liveHeight)

    local gridX = leftX + leftWidth + gap
    Layout.SetBounds(self.grid, gridX, pad,
        centerWidth, height - pad * 2)

    local detailsX = gridX + centerWidth + gap
    local removeHeight = Layout.Pixels(26, scale)
    local removeY = math.max(pad, height - pad - removeHeight)
    local detailsHeight = math.max(Layout.Pixels(1, scale),
        removeY - pad - gap)
    Layout.SetBounds(self.details, detailsX, pad,
        math.max(1, width - detailsX - pad), detailsHeight)
    Layout.SetBounds(self.addButton, detailsX,
        removeY - Layout.Pixels(30, scale),
        math.max(1, width - detailsX - pad), Layout.Pixels(26, scale))
    Layout.SetBounds(self.removeButton, detailsX,
        removeY,
        math.max(1, width - detailsX - pad), Layout.Pixels(26, scale))
end

return Class
