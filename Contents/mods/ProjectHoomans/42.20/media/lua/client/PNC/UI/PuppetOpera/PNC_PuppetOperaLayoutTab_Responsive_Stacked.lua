-- Stacked responsive geometry for the Puppet Opera layout editor.

PNC = PNC or {}

local Internal = PNC.PuppetOperaLayoutTabInternal
local Layout = Internal.Layout

local function applyStackedLayout(self, metrics)
    local scale = metrics.scale
    local pad = metrics.pad
    local gap = metrics.gap
    local width = metrics.width
    local height = metrics.height
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
    return true
end

Internal.applyStackedLayout = applyStackedLayout

return applyStackedLayout
