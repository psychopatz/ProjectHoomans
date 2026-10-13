require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"
local Settings = require "PsychopatzCore/Settings/PsychopatzSettings"

local Shared = require "PNC/UI/Shared/PNC_ColonyUIShared"
local Components = {}
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local rosterTextures = {}
local ROSTER_ICON_SIZE = 22
local ROSTER_ICON_Y = 4

local function cloneCatalogColumns(columns)
    local copy = {}
    for index, column in ipairs(columns or {}) do
        copy[index] = {
            key = column.key,
            x = tonumber(column.x) or 0,
        }
    end
    return copy
end

local function catalogColumnValueMap(raw)
    local values = {}
    for pair in string.gmatch(tostring(raw or ""), "([^;]+)") do
        local key, value = string.match(pair, "^([^=]+)=([^=]+)$")
        if key and value then
            local position = tonumber(value)
            if position then values[key] = position end
        end
    end
    return values
end

-- Column positions are user preferences, so persist them through the same
-- per-user Settings store used by the other Core UI preferences.  The state
-- is keyed by window type and only stores stable column keys plus normalized
-- positions; screen size and runtime layout remain window-owned.
function Components.CreateCatalogColumnState(options)
    options = options or {}
    local namespace = tostring(options.namespace or "ProjectHoomansCatalogUI")
    local key = tostring(options.key or "columns")
    local store = Settings.Open(namespace, {
        fileName = options.fileName,
        defaults = { [key] = "" },
    })
    if not store.loaded then store:Load() end

    local state = {
        columns = cloneCatalogColumns(options.columns),
        store = store,
        key = key,
    }
    local saved = catalogColumnValueMap(store:Get(key, ""))
    for _, column in ipairs(state.columns) do
        local position = saved[column.key]
        if position then column.x = math.max(0.01, math.min(0.99, position)) end
    end

    function state:save()
        local values = {}
        for _, column in ipairs(self.columns or {}) do
            values[#values + 1] = tostring(column.key) .. "="
                .. string.format("%.6f", tonumber(column.x) or 0)
        end
        self.store:Set(self.key, table.concat(values, ";"), true)
    end

    return state
end

local function rosterTexture(path)
    if not path or not getTexture then return nil end
    if rosterTextures[path] == nil then
        rosterTextures[path] = getTexture(path) or false
    end
    return rosterTextures[path] or nil
end

local function rosterScale(list)
    return tonumber(list and list.uiScale)
        or tonumber(list and list.parent and list.parent.uiScale) or 1
end

local function rosterPixels(value, scale)
    return Layout.Pixels and Layout.Pixels(value, scale) or value
end

local function rosterIconMetrics(list, person)
    local indicators = person.indicators or {}
    local scale = rosterScale(list)
    local size = rosterPixels(ROSTER_ICON_SIZE, scale)
    local gap = rosterPixels(3, scale)
    local count = 0
    for _, indicator in ipairs(indicators) do
        if rosterTexture(indicator.texturePath) then count = count + 1 end
    end
    return size, gap, count
end

local function drawRosterIcons(list, y, person)
    local indicators = person.indicators or {}
    local size, gap, count = rosterIconMetrics(list, person)
    if count == 0 or not list.drawTextureScaledAspect then return 0 end
    local right = list:getWidth() - rosterPixels(8, rosterScale(list))
    local x = right - size
    for index = #indicators, 1, -1 do
        local texture = rosterTexture(indicators[index].texturePath)
        if texture then
            list:drawTextureScaledAspect(texture, x, y + ROSTER_ICON_Y,
                size, size,
                1, 1, 1, 1)
            x = x - size - gap
        end
    end
    return count * size + math.max(0, count - 1) * gap
end

local function rosterIndicatorAt(list)
    if not list or not list.getMouseX or not list.getMouseY
        or not list.rowAt then
        return nil
    end
    if list.isMouseOverScrollBar and list:isMouseOverScrollBar() then
        return nil
    end
    local mouseX = list:getMouseX()
    local mouseY = list:getMouseY()
    local rowIndex = list:rowAt(mouseX, mouseY)
    local entry = list.items and list.items[rowIndex]
    local person = entry and entry.item or nil
    if not person then return nil end

    local rowTop = list.topOfItem and list:topOfItem(rowIndex)
        or (rowIndex - 1) * list.itemheight
    local size, gap, count = rosterIconMetrics(list, person)
    if count == 0 or mouseY < rowTop + ROSTER_ICON_Y
        or mouseY > rowTop + ROSTER_ICON_Y + size
    then
        return nil
    end

    local x = list:getWidth() - rosterPixels(8, rosterScale(list)) - size
    local indicators = person.indicators or {}
    for index = #indicators, 1, -1 do
        local texture = rosterTexture(indicators[index].texturePath)
        if texture then
            if mouseX >= x and mouseX <= x + size then
                return indicators[index]
            end
            x = x - size - gap
        end
    end
    return nil
end

local function hideRosterTooltip(list)
    local tooltip = list and list.tooltipUI or nil
    if tooltip and tooltip.getIsVisible and tooltip:getIsVisible() then
        tooltip:setVisible(false)
        tooltip:removeFromUIManager()
    end
end

local function updateRosterTooltip(list)
    local indicator = rosterIndicatorAt(list)
    local text = indicator and indicator.tooltip or nil
    if not text or not ISToolTip then
        hideRosterTooltip(list)
        return
    end
    if not list.tooltipUI then
        list.tooltipUI = ISToolTip:new()
        list.tooltipUI:setOwner(list)
        list.tooltipUI:setVisible(false)
        list.tooltipUI:setAlwaysOnTop(true)
        list.tooltipUI.maxLineWidth = 1000
    end
    if not list.tooltipUI:getIsVisible() then
        list.tooltipUI:addToUIManager()
        list.tooltipUI:setVisible(true)
    end
    list.tooltipUI.description = text
    list.tooltipUI:setX(list:getMouseX() + 23)
    list.tooltipUI:setY(list:getMouseY() + 23)
end

local function drawRosterRow(list, y, entry, alternate)
    local person = entry.item or {}
    UI.DrawListSelection(
        list, y, list.itemheight, list.selected == entry.index, alternate
    )
    local iconWidth = drawRosterIcons(list, y, person)
    local available = math.max(40, list:getWidth() - iconWidth - 24)
    list:drawText(
        Layout.Ellipsize(person.label, UIFont.Small, available), 10, y + 7,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Small
    )
    list:drawText(
        Layout.Ellipsize(person.detail, UIFont.Small, list:getWidth() - 20),
        10, y + 28, Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small
    )
    return y + list.itemheight
end

local function drawDetailRow(list, y, entry, alternate)
    local item = entry.item or {}
    UI.DrawListSelection(list, y, list.itemheight, item.selected == true,
        alternate)
    local labelColor = item.colorName and Theme.colors[item.colorName]
        or Theme.colors.text
    local actionWidth = item.actionLabel and 96 or 0
    list:drawText(
        Layout.Ellipsize(item.label, UIFont.Small,
            list:getWidth() - 20 - actionWidth),
        10, y + 7, labelColor.r, labelColor.g, labelColor.b, labelColor.a,
        UIFont.Small
    )
    if item.actionLabel then
        local actionColor = item.actionColorName
            and Theme.colors[item.actionColorName] or Theme.colors.warning
        list:drawTextRight(tostring(item.actionLabel), list:getWidth() - 12,
            y + 7, actionColor.r, actionColor.g, actionColor.b,
            actionColor.a, UIFont.Small)
    end
    if item.meter then
        UI.Meter.Draw(list, {
            x = 10, y = y + 25,
            width = math.max(40, list:getWidth() - 20), height = 18,
            value = item.value, minimum = item.minimum or 0,
            maximum = item.maximum or 1,
            colorName = item.colorName,
            colorResolver = item.colorResolver or Shared.NeedMeterColor,
            needType = item.needType,
            conditionType = item.conditionType,
            thresholds = item.thresholds,
            decimals = item.decimals == nil and 2 or item.decimals,
            showMaximum = true,
        })
    else
        list:drawText(
            Layout.Ellipsize(item.detail, UIFont.Small,
                list:getWidth() - 20),
            10, y + 27, Theme.colors.textMuted.r,
            Theme.colors.textMuted.g, Theme.colors.textMuted.b,
            Theme.colors.textMuted.a, UIFont.Small
        )
    end
    return y + list.itemheight
end

ISPNCColonyPane = ISPanel:derive("ISPNCColonyPane")

function ISPNCColonyPane:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCColonyPane:setHeader(title, suffix)
    self.headerTitle = tostring(title or "")
    self.headerSuffix = suffix ~= nil and tostring(suffix) or nil
end

function ISPNCColonyPane:layoutContent()
    if not self.content then return end
    local headerHeight = Layout.Pixels(25, self.uiScale)
    Layout.SetBounds(self.content, 0, headerHeight, self:getWidth(),
        math.max(1, self:getHeight() - headerHeight))
    Components.LayoutScrollbar(self.content)
end

function Components.LayoutScrollbar(list)
    if Layout.SyncNativeScrollbars then
        Layout.SyncNativeScrollbars(list)
        return
    end
    local scrollbar = list and list.vscroll or nil
    if not scrollbar then return end
    local width = scrollbar.getWidth and scrollbar:getWidth()
        or scrollbar.width or 13
    scrollbar:setX(math.max(0, list:getWidth() - width))
    scrollbar:setY(0)
    scrollbar:setHeight(list:getHeight())
end

function ISPNCColonyPane:render()
    ISPanel.render(self)
    UI.DrawSectionTitle(self, self.headerTitle, 0, 0, self:getWidth(),
        self.headerSuffix)
end

function ISPNCColonyPane:new(x, y, width, height, uiScale)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    object.uiScale = uiScale
    return object
end

local function createPane(window, itemHeight, drawItem)
    local pane = ISPNCColonyPane:new(0, 0, 1, 1, window.uiScale)
    pane:initialise()
    pane:instantiate()
    window:addChild(pane)
    local list = UI.CreateList(pane, {
        itemHeight = itemHeight,
        doDrawItem = drawItem,
    })
    pane.content = list
    return pane, list
end

-- Fixed catalog column header.  Catalog rows belong to a scrolling list, but
-- the column labels belong to the pane.  Keeping this as a shared component
-- prevents each catalog from reimplementing sticky-header drawing and keeps
-- the scrollbar's viewport limited to actual rows.
local CatalogHeader = ISPanel:derive("ISPNCCatalogHeader")
local CATALOG_SPLITTER_WIDTH = 12
local DEFAULT_COLUMN_MINIMUMS = { 150, 80, 45, 95, 95 }

local function sumColumnMinimums(minimums, first, last)
    local total = 0
    for index = first, last do
        total = total + (tonumber(minimums[index]) or 1)
    end
    return total
end

local function setDividerBounds(divider, x, height)
    divider:setX(math.floor(x - CATALOG_SPLITTER_WIDTH / 2))
    divider:setY(0)
    divider:setWidth(CATALOG_SPLITTER_WIDTH)
    divider:setHeight(math.max(1, math.floor(height)))
end

function CatalogHeader:initialise()
    ISPanel.initialise(self)
    self.backgroundColor = Theme.Color("surfaceRaised")
    self.borderColor = Theme.Color("border")
    self.drawBorder = true
    self.splitters = {}
    self:setWantMouseEvents(true)
end

function CatalogHeader:setContent(title, cells, columns)
    self.title = tostring(title or "")
    self.cells = cells or {}
    self.columns = columns or self.columns or {}
    self:layoutSplitters()
end

function CatalogHeader:contentWidth()
    local list = self.linkedLists and self.linkedLists[1] or nil
    if list and list.catalogContentWidth then
        return math.max(1, tonumber(list:catalogContentWidth())
            or self:getWidth())
    end
    return math.max(1, self:getWidth())
end

function CatalogHeader:boundaryRange(index, width)
    local minimums = self.columnMinimums or DEFAULT_COLUMN_MINIMUMS
    -- The title occupies the first section before columns[1].x.  Each
    -- catalog column entry marks the start of the next section, so a header
    -- with four cells has five resizable sections and four splitters.
    local count = #self.columns + 1
    local leftMinimum = sumColumnMinimums(minimums, 1, index)
    local rightMinimum = sumColumnMinimums(minimums, index + 1, count)
    if leftMinimum + rightMinimum > width then
        leftMinimum = math.floor(width * index / count)
        rightMinimum = math.max(1, width - leftMinimum)
    end
    return math.max(1, leftMinimum),
        math.max(leftMinimum, width - rightMinimum)
end

function CatalogHeader:updateColumnBoundary(index, value)
    local width = self:contentWidth()
    if width <= 0 then return end
    local minimum, maximum = self:boundaryRange(index, width)
    local boundary = math.max(minimum, math.min(maximum,
        tonumber(value) or minimum))
    self.columns[index].x = boundary / width
    self:layoutSplitters()
    for _, list in ipairs(self.linkedLists or {}) do
        if list.invalidateCatalogControls then
            list:invalidateCatalogControls()
        end
    end
    if type(self.onColumnResize) == "function" then
        self.onColumnResize(self, index, boundary, width)
    end
end

function CatalogHeader:layoutSplitters()
    if not self.columns or #self.columns < 1 then return end
    if self:getWidth() <= 1 then return end
    local width = self:contentWidth()
    for index, divider in ipairs(self.splitters or {}) do
        local column = self.columns[index]
        if column then
            local minimum, maximum = self:boundaryRange(index, width)
            divider:setRange(minimum, maximum)
            local boundary = math.max(minimum, math.min(maximum,
                width * (tonumber(column.x) or 0)))
            column.x = boundary / width
            if not divider.dragging then
                divider:setValue(boundary, true)
            end
            setDividerBounds(divider, boundary, self:getHeight())
            divider:bringToTop()
        end
    end
end

function CatalogHeader:configure(options)
    options = options or {}
    self.linkedLists = options.lists or {}
    self.columnMinimums = options.minWidths or DEFAULT_COLUMN_MINIMUMS
    self.onColumnResize = options.onColumnResize
    self.onColumnResizeEnd = options.onColumnResizeEnd
    self.splitters = {}
    for index = 1, #self.columns do
        local divider = UI.CreateResizableDivider(self, {
            width = CATALOG_SPLITTER_WIDTH,
            height = self:getHeight(),
            drawIndicator = true,
            onChange = function(value)
                self:updateColumnBoundary(index, value)
            end,
            onRelease = function(value)
                if type(self.onColumnResizeEnd) == "function" then
                    self.onColumnResizeEnd(self, index, value)
                end
            end,
        })
        self.splitters[index] = divider
    end
    self:layoutSplitters()
end

function CatalogHeader:render()
    ISPanel.render(self)
    local font = Theme.Font(self.uiScale)
    local muted = Theme.colors.textMuted
    local accent = Theme.colors.accent
    local width = self:contentWidth()
    local firstColumn = self.columns[1]
    local titleRight = firstColumn
        and math.floor(width * (tonumber(firstColumn.x) or 0.4))
        or width
    self:drawText(Layout.Ellipsize(self.title, font,
        math.max(1, titleRight - 43)), 39, 7,
        muted.r, muted.g, muted.b, muted.a, font)
    for index, column in ipairs(self.columns) do
        local value = self.cells[column.key]
        if value ~= nil and value ~= "" then
            local x = math.floor(width * (tonumber(column.x) or 0)) + 4
            local nextColumn = self.columns[index + 1]
            local right = nextColumn
                and math.floor(width * (tonumber(nextColumn.x) or 1))
                or width
            self:drawText(Layout.Ellipsize(tostring(value), font,
                math.max(1, right - x - 4)), x, 7,
                muted.r, muted.g, muted.b, muted.a, font)
        end
    end
    local border = Theme.colors.border or muted
    for index = 1, #self.columns do
        local x = math.floor(width * (tonumber(self.columns[index].x) or 0))
        self:drawRect(x, 0, 1, self:getHeight(), 0.65,
            border.r, border.g, border.b)
    end
    self:drawRect(0, self:getHeight() - 1, width, 1, 0.9,
        accent.r, accent.g, accent.b)
end

function CatalogHeader:new(x, y, width, height, uiScale, columns)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    object.uiScale = uiScale
    object.columns = columns or {}
    object.title = ""
    object.cells = {}
    return object
end

function Components.CreateCatalogHeader(window, columns, options)
    local header = CatalogHeader:new(0, 0, 1, 32,
        window and window.uiScale or 1, columns)
    header:initialise()
    header:instantiate()
    header:configure(options)
    if window then window:addChild(header) end
    return header
end

function Components.CreatePane(window, itemHeight, drawItem)
    return createPane(window, itemHeight, drawItem)
end

function Components.CreateRosterPane(window)
    local pane, list = createPane(window, 52, drawRosterRow)
    list.updateTooltip = updateRosterTooltip
    local nativeMouseMoveOutside = list.onMouseMoveOutside
    list.onMouseMoveOutside = function(self, x, y)
        if type(nativeMouseMoveOutside) == "function" then
            nativeMouseMoveOutside(self, x, y)
        end
        hideRosterTooltip(self)
    end
    return pane, list
end

function Components.CreateDetailPane(window)
    return createPane(window, 48, drawDetailRow)
end

function Components.SetRows(list, rows)
    list:clear()
    if list.setScrollHeight then list:setScrollHeight(0) end
    if list.setYScroll then list:setYScroll(0) end
    list.smoothScrollTargetY = nil
    list.smoothScrollY = nil
    for _, row in ipairs(rows or {}) do
        list:addItem(tostring(row.key or row.label or ""), row)
    end
end

-- Refresh row payloads without clearing a live list. Clearing an
-- ISScrollingListBox during a network refresh briefly removes its children,
-- resets its scroll position, and can steal the mouse capture from a click.
-- Use this for stable-key projections that update in place.
function Components.SetRowsStable(list, rows)
    if not list then return false end
    rows = rows or {}
    local items = list.items or {}
    if #items ~= #rows then
        Components.SetRows(list, rows)
        return false
    end
    for index, row in ipairs(rows) do
        local entry = items[index]
        local old = entry and entry.item or nil
        local oldKey = old and (old.kind or "") .. ":"
            .. tostring(old.key or old.id or old.fullType
                or old.label or old.name or index) or tostring(index)
        local newKey = row and (row.kind or "") .. ":"
            .. tostring(row.key or row.id or row.fullType
                or row.label or row.name or index) or tostring(index)
        if not entry or oldKey ~= newKey then
            Components.SetRows(list, rows)
            return false
        end
    end
    for index, row in ipairs(rows) do
        local entry = items[index]
        entry.item = row
        entry.text = tostring(row.key or row.label or row.name or "")
    end
    list.count = #rows
    if list.selected and list.selected > #rows then
        list.selected = #rows
    end
    return true
end

function Components.AddRow(list, row)
    list:addItem(tostring(row.key or row.label or ""), row)
end

return Components
