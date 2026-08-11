require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISPanel"
local StorageTabs = require "PNC/UI/Communities/PNC_ColonyManagementStorageTabs"
local ResearchTab = require "PNC/UI/Communities/PNC_ColonyManagementResearchTab"

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
local NEED_LABEL_KEYS = {
    hunger = "UI_PNC_Need_Hunger",
    hydration = "UI_PNC_Need_Hydration",
    fatigue = "UI_PNC_Need_Fatigue",
}
local CONDITION_LABEL_KEYS = {
    stress = "UI_PNC_Stat_Stress",
    boredom = "UI_PNC_Stat_Boredom",
    panic = "UI_PNC_Stat_Panic",
}
local NEED_METER_THRESHOLDS = {
    hunger = {
        { maximum = 0.15, color = "success" },
        { maximum = 0.25, color = "accent" },
        { maximum = 0.45, color = "warning" },
        { maximum = 1.00, color = "danger" },
    },
    hydration = {
        { maximum = 0.12, color = "success" },
        { maximum = 0.25, color = "accent" },
        { maximum = 0.70, color = "warning" },
        { maximum = 1.00, color = "danger" },
    },
    fatigue = {
        { maximum = 0.60, color = "success" },
        { maximum = 0.70, color = "accent" },
        { maximum = 0.80, color = "warning" },
        { maximum = 1.00, color = "danger" },
    },
}

local function text(value, fallback)
    value = value ~= nil and tostring(value) or ""
    return value ~= "" and value or tostring(fallback or "")
end

local function listValue(list)
    local entry = list and list.getItem and list:getItem() or nil
    return entry and entry.item or nil
end

local function needLevel(needType, value)
    if PNC.NeedsDefinitions and PNC.NeedsDefinitions.GetLevel then
        return PNC.NeedsDefinitions.GetLevel(
            needType, tonumber(value) or 0
        )
    end
    return "STABLE"
end

local function needMeterColor(value, _, spec)
    return LEVEL_COLORS[needLevel(spec.needType, value)] or "accent"
end

local function conditionMeterColor(value, _, spec)
    local level = PNC.ConditionStats and PNC.ConditionStats.GetLevel
        and PNC.ConditionStats.GetLevel(spec.conditionType, value) or "STABLE"
    return LEVEL_COLORS[level] or "accent"
end

local function moraleMeterColor(value)
    value = tonumber(value) or 0
    if value < -50 then return "danger" end
    if value < 0 then return "warning" end
    if value < 50 then return "accent" end
    return "success"
end

local function worstNeed(person)
    local worstIndex = 1
    local worstType = NEED_TYPES[1]
    for _, needType in ipairs(NEED_TYPES) do
        local level = needLevel(needType,
            person.needs and person.needs[needType])
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
    if item.meter then
        UI.Meter.Draw(list, {
            x = 10, y = y + 25,
            width = math.max(40, list:getWidth() - 20), height = 18,
            value = item.value, minimum = item.minimum or 0,
            maximum = item.maximum or 1,
            colorName = item.colorName,
            colorResolver = item.colorResolver or needMeterColor,
            needType = item.needType,
            conditionType = item.conditionType,
            thresholds = item.thresholds,
            decimals = item.decimals == nil and 2 or item.decimals,
            showMaximum = true,
        })
    else
        list:drawText(
            Layout.Ellipsize(item.detail, UIFont.Small, list:getWidth() - 20),
            10, y + 27,
            Theme.colors.textMuted.r, Theme.colors.textMuted.g,
            Theme.colors.textMuted.b, Theme.colors.textMuted.a,
            UIFont.Small
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
        { id = "storage", title = "STORAGE" },
        { id = "research", title = "RESEARCH" },
    }) do
        self.tabs[#self.tabs + 1] = UI.CreateButton(self, {
            id = definition.id,
            title = definition.title,
            target = self,
            onclick = ISPNCColonyManagementWindow.onTab,
            variant = definition.id == self.tab and "selected" or "quiet",
        })
    end
    self.provisionButton = UI.CreateButton(self, {
        id = "provision",
        title = tr("UI_PNC_Provision_Open"),
        target = self,
        onclick = ISPNCColonyManagementWindow.onProvisionSettings,
        variant = "quiet",
    })
    self.peoplePane = ISPNCColonyPane:new(0, 0, 1, 1, self.uiScale)
    self.peoplePane:initialise()
    self.peoplePane:instantiate()
    self:addChild(self.peoplePane)
    self.people = UI.CreateList(self.peoplePane, {
        itemHeight = 52,
        doDrawItem = drawPerson,
    })
    self.peoplePane.content = self.people
    self.detailsPane = ISPNCColonyPane:new(0, 0, 1, 1, self.uiScale)
    self.detailsPane:initialise()
    self.detailsPane:instantiate()
    self:addChild(self.detailsPane)
    self.details = UI.CreateList(self.detailsPane, {
        itemHeight = 48,
        doDrawItem = drawDetail,
    })
    self.detailsPane.content = self.details
    StorageTabs.Create(self, UI, tr)
    ResearchTab.Create(self, UI, tr)
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
    local navigation = {}
    for _, button in ipairs(self.tabs) do navigation[#navigation + 1] = button end
    navigation[#navigation + 1] = self.provisionButton
    local flow = Layout.Flow(
        navigation,
        { x = rect.x, y = rect.y, width = rect.width },
        { scale = self.uiScale, minWidth = 92, gap = 6 }
    )
    local summaryHeight = Layout.Pixels(64, self.uiScale)
    local summaryY = flow.bottom + Layout.Pixels(10, self.uiScale)
    local sectionY = summaryY + summaryHeight + Layout.Pixels(10, self.uiScale)
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
        content = content,
    }
    self:layoutPane(
        self.peoplePane,
        split.first.x, split.first.y,
        split.first.width, split.first.height
    )
    self:layoutPane(
        self.detailsPane,
        split.second.x, split.second.y,
        split.second.width, split.second.height
    )
    StorageTabs.Layout(self, Layout, content)
    ResearchTab.Layout(self, Layout, content)
    self:applyTabLayout()
end

function ISPNCColonyManagementWindow:layoutPane(
    pane, x, y, width, height
)
    Layout.SetBounds(pane, x, y, width, height)
    pane.uiScale = self.uiScale
    pane:layoutContent()
end

function ISPNCColonyManagementWindow:onProvisionSettings()
    if PNC.ProvisionSettingsUI then PNC.ProvisionSettingsUI.Open() end
end

function ISPNCColonyManagementWindow:applyTabLayout()
    local peopleCount = #(self.snapshot and self.snapshot.people or {})
    self.peoplePane:setHeader("COMPANIONS", peopleCount)
    local detailTitle = self.tab == "people" and "COMPANION DETAILS"
        or self.tab == "needs" and "NEEDS OVERVIEW"
        or self.tab == "research" and "COLONY RESEARCH"
        or self.tab == "storage" and "DEBUG DETAILS"
        or "COLONY STATUS"
    self.detailsPane:setHeader(detailTitle)
    StorageTabs.ApplyLayout(self, Layout)
    ResearchTab.ApplyVisibility(self)
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
    self:applyTabLayout()
    self:rebuildDetails()
end

function ISPNCColonyManagementWindow:onStorageControl(button)
    return StorageTabs.OnControl(self, button, tr)
end

function ISPNCColonyManagementWindow:onResearchUpgrade(button)
    return ResearchTab.OnUpgrade(self, button)
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

function ISPNCColonyManagementWindow:addNeedMeter(needType, amount)
    local level = needLevel(needType, amount)
    self.details:addItem(tostring(needType), {
        label = tr(NEED_LABEL_KEYS[needType], string.upper(needType)),
        meter = true,
        value = tonumber(amount) or 0,
        minimum = 0,
        maximum = 1,
        needType = needType,
        colorName = LEVEL_COLORS[level] or "accent",
        thresholds = NEED_METER_THRESHOLDS[needType],
    })
end

function ISPNCColonyManagementWindow:addConditionMeter(statType, amount)
    local definition = PNC.ConditionStats
        and PNC.ConditionStats.DEFINITIONS[statType] or nil
    if not definition then return end
    self.details:addItem(statType, {
        label = tr(CONDITION_LABEL_KEYS[statType], string.upper(statType)),
        meter = true, value = tonumber(amount) or definition.default,
        minimum = definition.minimum, maximum = definition.maximum,
        conditionType = statType, colorResolver = conditionMeterColor,
        decimals = statType == "stress" and 2 or 0,
    })
end

function ISPNCColonyManagementWindow:addMoraleMeter(amount)
    self.details:addItem("morale", {
        label = tr("UI_PNC_Stat_Morale", "MORALE"), meter = true,
        value = tonumber(amount) or 0, minimum = -100, maximum = 100,
        colorResolver = moraleMeterColor, decimals = 0,
    })
end

function ISPNCColonyManagementWindow:rebuildDetails()
    local snapshot = self.snapshot or {}
    local colony = snapshot.colony or {}
    self.details:clear()
    if self.storageList then self.storageList:clear() end
    if StorageTabs.Rebuild(self, snapshot, tr)
        or ResearchTab.Rebuild(self, snapshot, tr)
    then return end
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
                        .. string.format("%.2f / 1", tonumber(warning.value) or 0),
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
            self:addNeedMeter(needType, amount)
        end
    elseif self.tab == "needs" then
        local person = listValue(self.people)
        if not person then
            self:addDetail(tr("UI_PNC_Needs_NoCompanions",
                "NO COMPANIONS"), "")
            return
        end
        local value = person.value or {}
        self:addDetail(text(value.name, value.id),
            string.upper(text(value.role, "Companion")), "accent")
        for _, needType in ipairs(NEED_TYPES) do
            self:addNeedMeter(needType,
                tonumber(value.needs and value.needs[needType]) or 0)
        end
        for _, statType in ipairs(PNC.ConditionStats
            and PNC.ConditionStats.TYPES or {})
        do
            self:addConditionMeter(statType,
                value.conditionStats and value.conditionStats[statType])
        end
        self:addMoraleMeter(value.morale)
    end
end

function ISPNCColonyManagementWindow:toggleInventoryGroup(role, groupKey)
    if role ~= "storage" or not groupKey then return end
    self.storageCollapsedGroups = self.storageCollapsedGroups or {}
    self.storageCollapsedGroups[groupKey] =
        self.storageCollapsedGroups[groupKey] ~= true
    self:rebuildDetails()
end

function ISPNCColonyManagementWindow:onPersonSelected()
    local person = listValue(self.people)
    self.selectedPersonID = person and person.id or self.selectedPersonID
    if self.tab == "people" or self.tab == "needs" then
        self:rebuildDetails()
    end
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
    self:applyTabLayout()
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
    if self.tab == "storage" then
        UI.DrawSectionTitle(self, "GENERAL STOCKPILE",
            self.storageList:getX(), self.storageList:getY() - 21,
            self.storageList:getWidth())
    end
    StorageTabs.RenderSummary(self, Theme)
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
