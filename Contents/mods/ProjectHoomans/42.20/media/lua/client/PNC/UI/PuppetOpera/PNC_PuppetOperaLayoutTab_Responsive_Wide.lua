-- Wide responsive geometry for the Puppet Opera layout editor.

PNC = PNC or {}

local Internal = PNC.PuppetOperaLayoutTabInternal
local Layout = Internal.Layout

local function applyWideLayout(self, metrics)
    local scale = metrics.scale
    local pad = metrics.pad
    local gap = metrics.gap
    local width = metrics.width
    local height = metrics.height
    local columnsWidth = metrics.columnsWidth
    local compact = metrics.compact
    local actorRowHeight = metrics.actorRowHeight
    local liveRowHeight = metrics.liveRowHeight

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
    return true
end

Internal.applyWideLayout = applyWideLayout

return applyWideLayout
