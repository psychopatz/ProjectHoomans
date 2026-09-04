require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.WorldEffectDebugUI = PNC.WorldEffectDebugUI or {}

local WorldEffectUI = PNC.WorldEffectDebugUI
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local ClientState = PNC.Network.ClientState

local function selected(list)
    local entry = list and list:getItem()
    return entry and entry.item or nil
end

local function text(value)
    return tostring(value == nil and "" or value)
end

local function endpointText(row)
    local output = {}
    for _, endpoint in ipairs(row.endpoints or {}) do
        output[#output + 1] = text(endpoint.role) .. " "
            .. string.format("%d,%d,%d", tonumber(endpoint.x) or 0,
                tonumber(endpoint.y) or 0, tonumber(endpoint.z) or 0)
            .. " " .. (endpoint.loaded and "loaded" or "unloaded")
    end
    return table.concat(output, " | ")
end

local function drawEffect(list, y, entry, alternate)
    local row = entry.item
    UI.DrawListSelection(list, y, list.itemheight,
        list.selected == entry.index, alternate)
    list:drawText(Layout.Ellipsize(text(row.kind) .. " / "
        .. text(row.state), UIFont.Small, list:getWidth() - 14),
        7, y + 4, Theme.colors.text.r, Theme.colors.text.g,
        Theme.colors.text.b, Theme.colors.text.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(text(row.operation) .. " | "
        .. text(row.ownerID) .. " | " .. text(row.waitReason
            or row.lastReason or "ready"), UIFont.Small, list:getWidth() - 14),
        7, y + 22, Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    return y + list.itemheight
end

ISPNCWorldEffectDebugWindow = PsychopatzWindow:derive(
    "ISPNCWorldEffectDebugWindow")

function ISPNCWorldEffectDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCWorldEffectDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.effects = UI.CreateList(self, {
        itemHeight = 42, doDrawItem = drawEffect,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 25, labelX = 8, labelY = 5, valueY = 5,
        valueX = 150, valueRightPadding = 8,
    })
    self.controls = {}
    for _, definition in ipairs({
        { "refresh", "REFRESH", "quiet" },
        { "pending", "PENDING", "success" },
        { "all", "ALL", "quiet" },
        { "conflict", "CONFLICT", "danger" },
        { "corpse", "CORPSE", "quiet" },
        { "tree", "TREE", "quiet" },
    }) do
        self.controls[#self.controls + 1] = UI.CreateButton(self, {
            id = definition[1], title = definition[2], target = self,
            onclick = ISPNCWorldEffectDebugWindow.onAction,
            variant = definition[3],
        })
    end
    self.filterState = "PENDING"
    self.filterKind = nil
    self:requestResponsiveLayout(true)
    self:requestSnapshot()
end

function ISPNCWorldEffectDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 28, bottom = 12 })
    local flow = Layout.Flow(self.controls,
        { x = rect.x, y = rect.y, width = rect.width },
        { scale = self.uiScale, minWidth = 78 })
    local top, gap = flow.bottom + 24, 8
    local listWidth = math.max(260, math.floor(rect.width * 0.42))
    local height = rect.height - (top - rect.y)
    self.layout = {
        effects = { x = rect.x, y = top, width = listWidth, height = height },
        details = { x = rect.x + listWidth + gap, y = top,
            width = rect.width - listWidth - gap, height = height },
    }
    Layout.SetBounds(self.effects, self.layout.effects.x,
        self.layout.effects.y, self.layout.effects.width,
        self.layout.effects.height)
    Layout.SetBounds(self.details, self.layout.details.x,
        self.layout.details.y, self.layout.details.width,
        self.layout.details.height)
end

function ISPNCWorldEffectDebugWindow:requestSnapshot()
    PNC.Client.RequestWorldEffectDebug(self.filterState, self.filterKind, 100)
    self.lastRequestAt = PNC.Core.Now()
end

local function restore(list, id)
    for index, entry in ipairs(list.items or {}) do
        if entry.item and entry.item.effectId == id then
            list.selected = index
            return
        end
    end
    if #list.items > 0 then list.selected = 1 end
end

function ISPNCWorldEffectDebugWindow:refreshSnapshot()
    local snapshot = ClientState.worldEffectDebug or {}
    local previous = selected(self.effects)
    self.effects:clear()
    for _, row in ipairs(snapshot.rows or {}) do
        self.effects:addItem(text(row.effectId), row)
    end
    restore(self.effects, previous and previous.effectId)
    self.details:clear()
    local summary = snapshot.summary or {}
    for _, key in ipairs({ "total", "pending", "applied", "conflict",
        "failed", "cancelled" }) do
        self.details:addItem("summary_" .. key, {
            label = key:upper(), value = text(summary[key] or 0),
        })
    end
    local row = selected(self.effects)
    if row then
        local rows = {
            { "Effect ID", row.effectId },
            { "Provider", row.providerID },
            { "Owner", row.ownerID },
            { "Operation", row.operation },
            { "Kind", row.kind },
            { "State", row.state },
            { "Order status", row.orderStatus },
            { "Worker", row.workerName or row.workerID },
            { "Progress", string.format("%d%% (%s/%s)",
                tonumber(row.percent) or 0, text(row.progress),
                text(row.requiredWork)) },
            { "Priority", row.priority },
            { "Attempts", row.attempts },
            { "Next retry", row.nextRetryAt },
            { "Wait reason", row.waitReason },
            { "Last reason", row.lastReason },
            { "Endpoints", endpointText(row) },
        }
        for index, item in ipairs(rows) do
            self.details:addItem("row_" .. tostring(index), {
                label = item[1], value = text(item[2]),
            })
        end
    end
    self.lastReceiveAt = ClientState.lastWorldEffectDebugReceiveAt
        or PNC.Core.Now()
end

function ISPNCWorldEffectDebugWindow:onAction(button)
    local id = button.internal
    if id == "refresh" then
        self:requestSnapshot()
        return
    end
    if id == "pending" then
        self.filterState, self.filterKind = "PENDING", nil
    elseif id == "all" then
        self.filterState, self.filterKind = "ALL", nil
    elseif id == "conflict" then
        self.filterState, self.filterKind = "CONFLICT", nil
    elseif id == "corpse" then
        self.filterState, self.filterKind = "ALL", "CORPSE_TRANSFER"
    elseif id == "tree" then
        self.filterState, self.filterKind = "ALL", "TREE_REMOVE"
    end
    self:requestSnapshot()
end

function ISPNCWorldEffectDebugWindow:prerender()
    local received = ClientState.lastWorldEffectDebugReceiveAt or 0
    if received > (self.lastReceiveAt or 0) then self:refreshSnapshot() end
    if PNC.Core.Now() - (self.lastRequestAt or 0) > 3000 then
        self:requestSnapshot()
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCWorldEffectDebugWindow:render()
    PsychopatzWindow.render(self)
    if self.layout then
        UI.DrawSectionTitle(self, "WORLD EFFECTS", self.layout.effects.x,
            self.layout.effects.y - 20, self.layout.effects.width)
        UI.DrawSectionTitle(self, "EFFECT DETAILS", self.layout.details.x,
            self.layout.details.y - 20, self.layout.details.width)
    end
end

function ISPNCWorldEffectDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    WorldEffectUI.instance = nil
end

function ISPNCWorldEffectDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function WorldEffectUI.Open()
    if not PNC.Client.CanUseDebug() then return nil end
    local window = WorldEffectUI.instance
    if not window then
        window = UI.NewWindow(ISPNCWorldEffectDebugWindow, {
            title = "PNC WORLD EFFECTS", resizable = true,
            responsiveSpec = { width = 980, height = 640,
                minWidth = 720, minHeight = 420,
                maxWidth = 1600, maxHeight = 1000 },
        })
        window:initialise()
        window:instantiate()
        WorldEffectUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestSnapshot()
    return window
end

function WorldEffectUI.Toggle()
    if WorldEffectUI.instance and WorldEffectUI.instance:getIsVisible() then
        WorldEffectUI.instance:close()
        return false
    end
    return WorldEffectUI.Open() ~= nil
end

