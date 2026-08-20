require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local Components = {}
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function drawRosterRow(list, y, entry, alternate)
    local person = entry.item or {}
    UI.DrawListSelection(
        list, y, list.itemheight, list.selected == entry.index, alternate
    )
    local level = person.worstLevel or "NORMAL"
    local badgeWidth = UI.DrawBadge(list, level, list:getWidth() - 7,
        y + 7, Shared.LEVEL_COLORS[level])
    local available = math.max(40, list:getWidth() - badgeWidth - 24)
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
    UI.DrawListSelection(list, y, list.itemheight, false, alternate)
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
    return createPane(window, 52, drawRosterRow)
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

function Components.AddRow(list, row)
    list:addItem(tostring(row.key or row.label or ""), row)
end

return Components
