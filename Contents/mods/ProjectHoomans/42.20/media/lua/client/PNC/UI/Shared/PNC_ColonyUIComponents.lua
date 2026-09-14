require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

local Shared = require "PNC/UI/Shared/PNC_ColonyUIShared"
local Components = {}
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local rosterTextures = {}
local ROSTER_ICON_SIZE = 22
local ROSTER_ICON_Y = 4

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
