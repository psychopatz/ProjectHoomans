require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.ColonyManagementUI = PNC.ColonyManagementUI or {}

local ColonyUI = PNC.ColonyManagementUI
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local State = PNC.Network.ClientState

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local NEED_TYPES = { "hunger", "hydration", "fatigue" }
local LEVELS = { "GOOD", "STABLE", "LOW", "CRITICAL", "EMERGENCY" }
local LEVEL_COLORS = {
    GOOD = "success",
    STABLE = "accent",
    LOW = "warning",
    CRITICAL = "danger",
    EMERGENCY = "danger",
}

local function text(value, fallback)
    value = value ~= nil and tostring(value) or ""
    return value ~= "" and value or tostring(fallback or "")
end

local function listValue(list)
    local entry = list and list.getItem and list:getItem() or nil
    return entry and entry.item or nil
end

local function needLevel(value)
    if PNC.NeedsDefinitions and PNC.NeedsDefinitions.GetLevel then
        return PNC.NeedsDefinitions.GetLevel(tonumber(value) or 0)
    end
    return "STABLE"
end

local function worstNeed(person)
    local worstIndex = 1
    local worstType = NEED_TYPES[1]
    for _, needType in ipairs(NEED_TYPES) do
        local level = needLevel(person.needs and person.needs[needType])
        for index, candidate in ipairs(LEVELS) do
            if candidate == level and index > worstIndex then
                worstIndex = index
                worstType = needType
            end
        end
    end
    return LEVELS[worstIndex], worstType
end

local function drawPerson(list, y, entry, alternate)
    local person = entry.item or {}
    UI.DrawListSelection(
        list, y, list.itemheight, list.selected == entry.index, alternate
    )
    local level = person.worstLevel or "STABLE"
    local badgeWidth = UI.DrawBadge(
        list,
        level,
        list:getWidth() - 7,
        y + 7,
        LEVEL_COLORS[level]
    )
    local available = math.max(40, list:getWidth() - badgeWidth - 24)
    list:drawText(
        Layout.Ellipsize(person.label, UIFont.Small, available),
        10, y + 7,
        Theme.colors.text.r, Theme.colors.text.g,
        Theme.colors.text.b, Theme.colors.text.a,
        UIFont.Small
    )
    list:drawText(
        Layout.Ellipsize(person.detail, UIFont.Small, list:getWidth() - 20),
        10, y + 28,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a,
        UIFont.Small
    )
    return y + list.itemheight
end

local function drawDetail(list, y, entry, alternate)
    local item = entry.item or {}
    UI.DrawListSelection(list, y, list.itemheight, false, alternate)
    local labelColor = item.colorName and Theme.colors[item.colorName]
        or Theme.colors.text
    list:drawText(
        Layout.Ellipsize(item.label, UIFont.Small, list:getWidth() - 20),
        10, y + 7,
        labelColor.r, labelColor.g, labelColor.b, labelColor.a,
        UIFont.Small
    )
    list:drawText(
        Layout.Ellipsize(item.detail, UIFont.Small, list:getWidth() - 20),
        10, y + 27,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a,
        UIFont.Small
    )
    return y + list.itemheight
end

ISPNCColonyManagementWindow = PsychopatzWindow:derive(
    "ISPNCColonyManagementWindow"
)

function ISPNCColonyManagementWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCColonyManagementWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.tab = "overview"
    self.tabs = {}
    for _, definition in ipairs({
        { id = "overview", title = "OVERVIEW" },
        { id = "people", title = "PEOPLE" },
        { id = "needs", title = "NEEDS" },
    }) do
        self.tabs[#self.tabs + 1] = UI.CreateButton(self, {
            id = definition.id,
            title = definition.title,
            target = self,
            onclick = ISPNCColonyManagementWindow.onTab,
            variant = definition.id == self.tab and "selected" or "quiet",
        })
    end
    self.people = UI.CreateList(self, {
        itemHeight = 52,
        doDrawItem = drawPerson,
    })
    self.details = UI.CreateList(self, {
        itemHeight = 48,
        doDrawItem = drawDetail,
    })
    self.people.onMouseDown = function(list, x, y)
        local handled = ISScrollingListBox.onMouseDown(list, x, y)
        self:onPersonSelected()
        return handled
    end
    self:requestResponsiveLayout(true)
    self:refresh()
    self:requestSnapshot()
end

function ISPNCColonyManagementWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 34, bottom = 12 })
    local flow = Layout.Flow(
        self.tabs,
        { x = rect.x, y = rect.y, width = rect.width },
        { scale = self.uiScale, minWidth = 92, gap = 6 }
    )
    local summaryHeight = Layout.Pixels(64, self.uiScale)
    local summaryY = flow.bottom + Layout.Pixels(10, self.uiScale)
    local sectionY = summaryY + summaryHeight + Layout.Pixels(28, self.uiScale)
    local content = {
        x = rect.x,
        y = sectionY,
        width = rect.width,
        height = math.max(80, rect.y + rect.height - sectionY),
    }
    local split = Layout.Split(content, {
        scale = self.uiScale,
        firstRatio = 0.36,
        topRatio = 0.42,
        breakpoint = 780,
        gap = 12,
    })
    self.layout = {
        summary = {
            x = rect.x,
            y = summaryY,
            width = rect.width,
            height = summaryHeight,
        },
        people = split.first,
        details = split.second,
        compact = split.compact,
    }
    Layout.SetBounds(
        self.people,
        split.first.x, split.first.y,
        split.first.width, split.first.height
    )
    Layout.SetBounds(
        self.details,
        split.second.x, split.second.y,
        split.second.width, split.second.height
    )
end

function ISPNCColonyManagementWindow:updateTabStyles()
    for _, button in ipairs(self.tabs or {}) do
        UI.SetButtonVariant(
            button,
            button.internal == self.tab and "selected" or "quiet"
        )
    end
end

function ISPNCColonyManagementWindow:onTab(button)
    self.tab = button and button.internal or "overview"
    self:updateTabStyles()
    self:rebuildDetails()
end

function ISPNCColonyManagementWindow:requestSnapshot()
    if PNC.Client and PNC.Client.RequestColonyManagement then
        PNC.Client.RequestColonyManagement()
    end
    self.lastRequestAt = PNC.Core.Now()
end

function ISPNCColonyManagementWindow:addDetail(label, detail, colorName)
    self.details:addItem(tostring(label or ""), {
        label = tostring(label or ""),
        detail = tostring(detail or ""),
        colorName = colorName,
    })
end

function ISPNCColonyManagementWindow:rebuildDetails()
    local snapshot = self.snapshot or {}
    local colony = snapshot.colony or {}
    self.details:clear()
    if self.tab == "overview" then
        self:addDetail("STATUS", "Active community")
        self:addDetail("HOME", colony.mode and string.upper(colony.mode)
            or "CAMP NOT ESTABLISHED")
        self:addDetail("POPULATION", tostring(#(snapshot.people or {}))
            .. " active companions")
        if #(snapshot.attention or {}) == 0 then
            self:addDetail(
                "ALL NEEDS STABLE",
                "No companion currently needs attention.",
                "success"
            )
        else
            for _, warning in ipairs(snapshot.attention or {}) do
                self:addDetail(
                    text(warning.name, "Unknown companion"),
                    string.upper(text(warning.needType, "need")) .. "  "
                        .. string.format("%.0f / 100", tonumber(warning.value) or 0),
                    LEVEL_COLORS[warning.severity] or "warning"
                )
            end
        end
    elseif self.tab == "people" then
        local person = listValue(self.people)
        if not person then
            self:addDetail("NO COMPANIONS", "Recruit someone to populate this colony.")
            return
        end
        local value = person.value or {}
        self:addDetail(text(value.name, "Unknown"),
            string.upper(text(value.role, "Companion")), "accent")
        self:addDetail("ACTIVITY", text(value.activity, "Idle"))
        self:addDetail("ASSIGNMENT", text(value.job, "Unassigned"))
        self:addDetail("HEALTH", string.upper(text(value.health, "Unknown")))
        for _, needType in ipairs(NEED_TYPES) do
            local amount = tonumber(value.needs and value.needs[needType]) or 0
            local level = needLevel(amount)
            self:addDetail(
                string.upper(needType),
                string.format("%.1f / 100  -  %s", amount, level),
                LEVEL_COLORS[level]
            )
        end
    else
        for _, needType in ipairs(NEED_TYPES) do
            local counts = snapshot.levels and snapshot.levels[needType] or {}
            self:addDetail(
                string.upper(needType),
                string.format(
                    "Good %d   Stable %d   Low %d   Critical %d   Emergency %d",
                    counts.GOOD or 0,
                    counts.STABLE or 0,
                    counts.LOW or 0,
                    counts.CRITICAL or 0,
                    counts.EMERGENCY or 0
                )
            )
        end
        for _, warning in ipairs(snapshot.attention or {}) do
            self:addDetail(
                text(warning.name, "Unknown companion"),
                string.upper(text(warning.needType, "need")) .. " needs attention",
                LEVEL_COLORS[warning.severity] or "warning"
            )
        end
    end
end

function ISPNCColonyManagementWindow:onPersonSelected()
    local person = listValue(self.people)
    self.selectedPersonID = person and person.id or self.selectedPersonID
    if self.tab == "people" then self:rebuildDetails() end
end

function ISPNCColonyManagementWindow:refresh()
    local selectedID = self.selectedPersonID
    local selectedIndex
    self.snapshot = State.colonyManagement or {}
    self.people:clear()
    for _, person in ipairs(self.snapshot.people or {}) do
        local level, needType = worstNeed(person)
        local row = {
            id = person.id,
            label = text(person.name, person.id),
            detail = string.upper(text(person.role, "Companion")) .. "  -  "
                .. text(person.activity, "Idle") .. "  -  "
                .. string.upper(needType),
            value = person,
            worstLevel = level,
        }
        self.people:addItem(row.label, row)
        if row.id == selectedID then selectedIndex = #self.people.items end
    end
    if #self.people.items > 0 then
        self.people.selected = selectedIndex or 1
        local person = listValue(self.people)
        self.selectedPersonID = person and person.id or nil
    else
        self.people.selected = 0
        self.selectedPersonID = nil
    end
    self:updateTabStyles()
    self:rebuildDetails()
    self.lastReceiveAt = State.lastColonyManagementReceiveAt
        or PNC.Core.Now()
end

function ISPNCColonyManagementWindow:prerender()
    if (State.lastColonyManagementReceiveAt or 0)
        > (self.lastReceiveAt or 0)
    then
        self:refresh()
    end
    if PNC.Core.Now() - (self.lastRequestAt or 0) > 3000 then
        self:requestSnapshot()
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCColonyManagementWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then return end
    local snapshot = self.snapshot or {}
    local colony = snapshot.colony or {}
    local summary = self.layout.summary
    UI.DrawSurface(self, summary.x, summary.y, summary.width, summary.height, true)
    self:drawText(
        string.upper(text(colony.name, "New Colony")),
        summary.x + 14, summary.y + 10,
        Theme.colors.text.r, Theme.colors.text.g,
        Theme.colors.text.b, Theme.colors.text.a,
        Theme.Font(self.uiScale, "title")
    )
    self:drawText(
        tostring(#(snapshot.people or {})) .. " companions  |  "
            .. tostring(#(snapshot.attention or {})) .. " need attention",
        summary.x + 14, summary.y + summary.height - 23,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a,
        UIFont.Small
    )
    UI.DrawSectionTitle(
        self, "COMPANIONS",
        self.layout.people.x, self.layout.people.y - 21,
        self.layout.people.width,
        tostring(#(snapshot.people or {}))
    )
    local detailTitle = self.tab == "people" and "COMPANION DETAILS"
        or self.tab == "needs" and "NEEDS OVERVIEW"
        or "COLONY STATUS"
    UI.DrawSectionTitle(
        self, detailTitle,
        self.layout.details.x, self.layout.details.y - 21,
        self.layout.details.width
    )
end

function ISPNCColonyManagementWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    ColonyUI.instance = nil
end

function ISPNCColonyManagementWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function ColonyUI.Open()
    local window = ColonyUI.instance
    if not window then
        window = UI.NewWindow(ISPNCColonyManagementWindow, {
            title = string.upper(tr(
                "UI_PNC_ColonyManagement",
                "Colony Management"
            )),
            resizable = true,
            persistenceKey = "PNC.ColonyManagement",
            responsiveSpec = {
                width = 980,
                height = 640,
                minWidth = 700,
                minHeight = 500,
                maxWidth = 1320,
                maxHeight = 860,
            },
        })
        window:initialise()
        window:instantiate()
        ColonyUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestSnapshot()
    return window
end

function ColonyUI.Toggle()
    if ColonyUI.instance and ColonyUI.instance:getIsVisible() then
        ColonyUI.instance:close()
        return false
    end
    return ColonyUI.Open() ~= nil
end

return ColonyUI
