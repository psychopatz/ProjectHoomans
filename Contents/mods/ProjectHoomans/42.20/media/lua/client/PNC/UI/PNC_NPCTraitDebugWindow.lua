require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/PNC_NPCTraitDebugModel"

PNC = PNC or {}
PNC.NPCTraitDebugUI = PNC.NPCTraitDebugUI or {}

local DebugUI = PNC.NPCTraitDebugUI
local Model = PNC.NPCTraitDebugModel
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout

local function tr(key, fallback)
    if type(key) ~= "string" or key == "" then return fallback or "" end
    return PNC.Translation.GetKey(key, fallback or key)
end

local function selected(list)
    local entry = list and list:getItem()
    return entry and entry.item or nil
end

local function drawTrait(list, y, entry, alternate)
    local item = entry.item
    local selectedRow = list.selected == entry.index
    UI.DrawListSelection(list, y, list.itemheight, selectedRow, alternate)
    local color = Theme.colors.text
    local muted = Theme.colors.textMuted
    local label = tr(item.labelKey, item.label or item.id)
    list:drawText(Layout.Ellipsize(label, UIFont.Small,
        list:getWidth() - 14), 8, y + 5,
        color.r, color.g, color.b, color.a, UIFont.Small)
    local detail = item.id .. " | " .. tostring(item.detail or "")
    list:drawText(Layout.Ellipsize(detail, UIFont.Small,
        list:getWidth() - 14), 8, y + 24,
        muted.r, muted.g, muted.b, muted.a, UIFont.Small)
    return y + list.itemheight
end

ISPNCTraitDebugWindow = PsychopatzWindow:derive(
    "ISPNCTraitDebugWindow")

function ISPNCTraitDebugWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCTraitDebugWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.traits = UI.CreateList(self, {
        itemHeight = Layout.Pixels(43, self.uiScale),
        doDrawItem = drawTrait,
    })
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = Layout.Pixels(25, self.uiScale),
        labelX = 8,
        labelY = 5,
        valueY = 5,
        valueX = Layout.Pixels(220, self.uiScale),
        valueRightPadding = 8,
        labelWidthRatio = 0.38,
    })
    self.refresh = UI.CreateButton(self, {
        id = "refresh",
        title = tr("UI_PNC_NPCTraitDebug_Refresh", "REFRESH REGISTRY"),
        target = self,
        onclick = ISPNCTraitDebugWindow.onAction,
        variant = "quiet",
    })
    self:requestResponsiveLayout(true)
    self:refreshRegistry(true)
end

function ISPNCTraitDebugWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 28, bottom = 12 })
    Layout.SetBounds(self.refresh, rect.x, rect.y,
        Layout.Pixels(150, self.uiScale), Layout.Pixels(26, self.uiScale))
    local top = rect.y + Layout.Pixels(50, self.uiScale)
    local gap = Layout.Pixels(8, self.uiScale)
    local listWidth = math.max(Layout.Pixels(260, self.uiScale),
        math.floor(rect.width * 0.40))
    local height = math.max(100, rect.y + rect.height - top)
    self.layout = {
        traits = { x = rect.x, y = top, width = listWidth, height = height },
        details = { x = rect.x + listWidth + gap, y = top,
            width = rect.width - listWidth - gap, height = height },
    }
    Layout.SetBounds(self.traits, self.layout.traits.x, self.layout.traits.y,
        self.layout.traits.width, self.layout.traits.height)
    Layout.SetBounds(self.details, self.layout.details.x,
        self.layout.details.y, self.layout.details.width,
        self.layout.details.height)
end

function ISPNCTraitDebugWindow:getSelected()
    return selected(self.traits)
end

function ISPNCTraitDebugWindow:refreshDetails()
    self.details:clear()
    local item = self:getSelected()
    if not item or not item.definition then
        self.details:addItem("empty", {
            label = tr("UI_PNC_NPCTraitDebug_Title", "Registry"),
            value = tr("UI_PNC_NPCTraitDebug_NoneSelected",
                "No NPC trait selected"),
        })
        return
    end
    for index, row in ipairs(Model.BuildRows(item.definition)) do
        local display = {}
        for key, value in pairs(row) do display[key] = value end
        if row.translationKey then
            display.value = tr(row.translationKey, row.fallback or row.value)
        elseif row.humanize then
            display.value = tr(row.value, row.fallback or row.value)
        end
        self.details:addItem("row_" .. tostring(index), display)
    end
end

function ISPNCTraitDebugWindow:refreshRegistry(force)
    local previous = self:getSelected()
    local previousID = previous and previous.id or nil
    local revision = PNC.NPCTraits and PNC.NPCTraits.Revision or 0
    if not force and revision == self.registryRevision then return end
    self.registryRevision = revision
    self.traits:clear()
    local items = Model.BuildItems()
    for _, item in ipairs(items) do
        self.traits:addItem(item.label, item)
    end
    self.traits.selected = 0
    if previousID then
        for index, entry in ipairs(self.traits.items or {}) do
            if entry.item and entry.item.id == previousID then
                self.traits.selected = index
                break
            end
        end
    end
    if self.traits.selected == 0 and #self.traits.items > 0 then
        self.traits.selected = 1
    end
    self.lastSelection = self.traits.selected
    self:refreshDetails()
end

function ISPNCTraitDebugWindow:onAction(button)
    if button and button.internal == "refresh" then
        self:refreshRegistry(true)
    end
end

function ISPNCTraitDebugWindow:prerender()
    self:refreshRegistry(false)
    local selection = self.traits and self.traits.selected or 0
    if selection ~= self.lastSelection then
        self.lastSelection = selection
        self:refreshDetails()
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCTraitDebugWindow:render()
    PsychopatzWindow.render(self)
    if self.layout then
        UI.DrawSectionTitle(self, tr("UI_PNC_NPCTraitDebug_Registered",
            "REGISTERED NPC TRAITS"),
            self.layout.traits.x, self.layout.traits.y - 20,
            self.layout.traits.width)
        UI.DrawSectionTitle(self, tr("UI_PNC_NPCTraitDebug_Details",
            "TRAIT DETAILS"),
            self.layout.details.x, self.layout.details.y - 20,
            self.layout.details.width)
    end
end

function ISPNCTraitDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    DebugUI.instance = nil
end

function ISPNCTraitDebugWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function DebugUI.Open()
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        return nil
    end
    local window = DebugUI.instance
    if not window then
        window = UI.NewWindow(ISPNCTraitDebugWindow, {
            title = tr("UI_PNC_NPCTraitDebug_Title",
                "NPC TRAIT REGISTRY"),
            resizable = true,
            responsiveSpec = {
                width = 980,
                height = 650,
                minWidth = 700,
                minHeight = 440,
                maxWidth = 1500,
                maxHeight = 1000,
            },
        })
        window:initialise()
        window:instantiate()
        DebugUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:refreshRegistry(true)
    return window
end

function DebugUI.Toggle()
    if DebugUI.instance and DebugUI.instance:getIsVisible() then
        DebugUI.instance:close()
        return false
    end
    return DebugUI.Open() ~= nil
end

return DebugUI
