require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISPanel"
require "ISUI/ISScrollingListBox"
require "PNC/UI/Map/PNC_MapCommandRegistry"

PNC = PNC or {}
PNC.OrdersUI = PNC.OrdersUI or {}

local Registry = require "PNC/UI/Orders/PNC_OrdersRegistry"
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme
local OrdersUI = PNC.OrdersUI

local function tr(key, fallback)
    if not key then return fallback end
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function clientState()
    return PNC.Network and PNC.Network.ClientState or {}
end

local function currentSnapshot()
    return clientState().colonyManagement or {}
end

local function orderTitle(definition)
    return tr(definition and definition.titleKey,
        definition and definition.titleFallback or "ORDER")
end

local function selectedPerson(window)
    local id = tostring(window.selectedPersonID or "")
    for _, person in ipairs(window.people or {}) do
        if tostring(person.id or "") == id then return person end
    end
    return nil
end

local function isEnabled(person, definition)
    if not person or not definition then return false end
    local jobs = person and person.allowedJobs or nil
    return not jobs or jobs[definition.job] ~= false
end

local function hasSelectedPeople(window)
    for _, selected in pairs(window.selectedPeopleIDs or {}) do
        if selected == true then return true end
    end
    return false
end

local function hasCurrentOrder(person, definition)
    local order = person and person.order or nil
    if order and tostring(order.kind or "")
        == tostring(definition.orderKind or "")
    then
        return true
    end
    local configured = person and person.specialOrders or nil
    return configured and configured[definition.job] == true or false
end

local function statusFor(person, definition)
    if hasCurrentOrder(person, definition) then
        return tr("UI_PNC_Orders_Active", "ACTIVE"), "success"
    end
    if not isEnabled(person, definition) then
        return tr("UI_PNC_Orders_Disabled", "DISABLED"), "warning"
    end
    return tr("UI_PNC_Orders_Ready", "READY"), "muted"
end

local function readableOrder(person)
    local order = person and person.order or nil
    if order and tostring(order.kind or "") ~= "" then
        local definition = Registry.Get(order.kind)
        return definition and orderTitle(definition) or tostring(order.kind)
    end
    local configured = person and person.specialOrders or {}
    for _, definition in ipairs(Registry.All()) do
        if configured[definition.job] == true then
            return orderTitle(definition)
        end
    end
    return tr("UI_PNC_Orders_NoCurrentOrder", "NO SPECIAL ORDER")
end

local function drawOrderRow(list, y, entry, alternate)
    local definition = entry.item or {}
    UI.DrawListSelection(list, y, list.itemheight,
        list.selected == entry.index, alternate)
    local title = orderTitle(definition)
    local mode = definition.mapCommand
        and tr("UI_PNC_Orders_MapOrder", "MAP AREA")
        or tr("UI_PNC_Orders_AutomaticOrder", "AUTOMATIC")
    list:drawText(Layout.Ellipsize(title, UIFont.Small,
        list:getWidth() - 18), 10, y + 8,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Small)
    list:drawText(mode, 10, y + 29,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    return y + list.itemheight
end

local function drawPersonRow(list, y, entry, alternate)
    local value = entry.item or {}
    local person = value.person or {}
    local selected = value.selected == true
    UI.DrawListSelection(list, y, list.itemheight,
        list.selected == entry.index, alternate)
    local marker = selected and "[X] " or "[ ] "
    list:drawText(marker .. tostring(person.name or person.id or "NPC"),
        10, y + 7, selected and Theme.colors.accent.r
            or Theme.colors.text.r,
        selected and Theme.colors.accent.g or Theme.colors.text.g,
        selected and Theme.colors.accent.b or Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(readableOrder(person),
        UIFont.Small, list:getWidth() - 20), 10, y + 28,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    return y + list.itemheight
end

ISPNCOrdersDetails = ISPanel:derive("ISPNCOrdersDetails")

function ISPNCOrdersDetails:render()
    ISPanel.render(self)
    local window = self.owner
    if not window then return end
    local definition = window:selectedDefinition()
    local person = selectedPerson(window)
    local title = definition and orderTitle(definition)
        or tr("UI_PNC_Orders_SelectOrder", "SELECT AN ORDER")
    UI.DrawSectionTitle(self, title, 10, 10,
        math.max(1, self:getWidth() - 20))
    if not definition then
        self:drawText(
            tr("UI_PNC_Orders_SelectOrderHelp",
                "Choose an order type from the left."),
            10, 40, Theme.colors.textMuted.r, Theme.colors.textMuted.g,
            Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
        return
    end
    local description = tr(definition.descriptionKey,
        definition.descriptionFallback or "")
    self:drawText(Layout.Ellipsize(description, UIFont.Small,
        math.max(1, self:getWidth() - 20)), 10, 40,
        Theme.colors.text.r, Theme.colors.text.g, Theme.colors.text.b,
        Theme.colors.text.a, UIFont.Small)
    local selectedCount = #window:selectedPeople()
    local selectedLabel = selectedCount == 1
        and (person and tostring(person.name or person.id) or "")
        or tostring(selectedCount) .. " "
            .. tr("UI_PNC_Orders_ColonistsSelected", "COLONISTS SELECTED")
    self:drawText(tr("UI_PNC_Orders_Selected", "SELECTED") .. ": "
        .. selectedLabel, 10, 72,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    if definition.mapCommand then
        self:drawText(tr("UI_PNC_Orders_MapHelp",
            "Use SET AREA ON MAP, then right-click the work area."),
            10, 102, Theme.colors.accent.r, Theme.colors.accent.g,
            Theme.colors.accent.b, Theme.colors.accent.a, UIFont.Small)
    else
        self:drawText(tr("UI_PNC_Orders_AutomaticHelp",
            "Enable this order for selected colonists; eligible work is claimed automatically."),
            10, 102, Theme.colors.accent.r, Theme.colors.accent.g,
            Theme.colors.accent.b, Theme.colors.accent.a, UIFont.Small)
    end
    local y = 140
    for _, value in ipairs(window:selectedPeople()) do
        local status, colorName = statusFor(value, definition)
        local color = Theme.colors[colorName] or Theme.colors.textMuted
        self:drawText(tostring(value.name or value.id or "NPC") .. "  "
            .. status, 10, y, color.r, color.g, color.b, color.a,
            UIFont.Small)
        y = y + 22
        if y > self:getHeight() - 24 then break end
    end
end

function ISPNCOrdersDetails:new(owner)
    local object = ISPanel:new(0, 0, 1, 1)
    setmetatable(object, self)
    self.__index = self
    object.owner = owner
    object.backgroundColor = Theme.Color("surface")
    object.borderColor = Theme.Color("border")
    return object
end

ISPNCOrdersWindow = PsychopatzWindow:derive("ISPNCOrdersWindow")

function ISPNCOrdersWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCOrdersWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.selectedOrderID = "fishing"
    self.selectedPersonID = nil
    self.selectedPeopleIDs = {}
    self.multiSelect = false
    self.people = {}
    self.lastRevision = -1
    self.lastRequestAt = 0

    self.orderList = UI.CreateList(self, {
        itemHeight = Layout.Pixels(52, self.uiScale),
        doDrawItem = drawOrderRow,
    })
    self.peopleList = UI.CreateList(self, {
        itemHeight = Layout.Pixels(50, self.uiScale),
        doDrawItem = drawPersonRow,
    })
    self.peopleList.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        self:onPersonClicked()
    end
    self.orderList.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        self:onOrderClicked()
    end

    self.details = ISPNCOrdersDetails:new(self)
    self.details:initialise()
    self.details:instantiate()
    self:addChild(self.details)

    self.multiButton = UI.CreateButton(self, {
        id = "multi_select",
        title = tr("UI_PNC_Orders_MultiSelectOff", "MULTI SELECT: OFF"),
        target = self,
        onclick = ISPNCOrdersWindow.onControl,
        variant = "quiet",
    })
    self.refreshButton = UI.CreateButton(self, {
        id = "refresh",
        title = tr("UI_PNC_Orders_Refresh", "REFRESH"),
        target = self,
        onclick = ISPNCOrdersWindow.onControl,
        variant = "quiet",
    })
    self.mapButton = UI.CreateButton(self, {
        id = "configure_map",
        title = tr("UI_PNC_Orders_SetArea", "SET AREA ON MAP"),
        target = self,
        onclick = ISPNCOrdersWindow.onControl,
        variant = "primary",
    })
    self.toggleButton = UI.CreateButton(self, {
        id = "toggle_permission",
        title = tr("UI_PNC_Orders_Enable", "ENABLE"),
        target = self,
        onclick = ISPNCOrdersWindow.onControl,
        variant = "success",
    })
    self.stopButton = UI.CreateButton(self, {
        id = "stop_order",
        title = tr("UI_PNC_Orders_Stop", "STOP ORDER"),
        target = self,
        onclick = ISPNCOrdersWindow.onControl,
        variant = "warning",
    })
    self.closeButton = UI.CreateButton(self, {
        id = "close",
        title = tr("UI_PNC_Orders_Close", "CLOSE"),
        target = self,
        onclick = ISPNCOrdersWindow.onControl,
        variant = "quiet",
    })

    self:populateOrderList()
    self:requestResponsiveLayout(true)
    self:refreshSnapshot()
end

function ISPNCOrdersWindow:populateOrderList()
    self.orderList:clear()
    local selectedIndex = 1
    for index, definition in ipairs(Registry.All()) do
        self.orderList:addItem(definition.id, definition)
        if definition.id == self.selectedOrderID then selectedIndex = index end
    end
    self.orderList.selected = #self.orderList.items > 0 and selectedIndex or 0
end

function ISPNCOrdersWindow:selectedDefinition()
    local row = self.orderList and self.orderList:selectedRow() or nil
    return row and row.item or Registry.Get(self.selectedOrderID)
end

function ISPNCOrdersWindow:selectedPeople()
    local output = {}
    local selected = self.selectedPeopleIDs or {}
    for _, person in ipairs(self.people or {}) do
        if selected[tostring(person.id or "")] == true then
            output[#output + 1] = person
        end
    end
    if #output == 0 then
        local person = selectedPerson(self)
        if person then output[1] = person end
    end
    return output
end

function ISPNCOrdersWindow:onOrderClicked()
    local definition = self:selectedDefinition()
    if not definition then return end
    self.selectedOrderID = definition.id
    self:updateControls()
end

function ISPNCOrdersWindow:onPersonClicked()
    local row = self.peopleList and self.peopleList:selectedRow() or nil
    local value = row and row.item or nil
    local person = value and value.person or nil
    if not person then return end
    local id = tostring(person.id or "")
    self.selectedPersonID = id
    self.selectedPeopleIDs = self.selectedPeopleIDs or {}
    if self.multiSelect then
        self.selectedPeopleIDs[id] = not self.selectedPeopleIDs[id]
    else
        self.selectedPeopleIDs = { [id] = true }
    end
    self:refreshPeopleRows()
    self:updateControls()
end

function ISPNCOrdersWindow:refreshPeopleRows()
    self.peopleList:clear()
    for _, person in ipairs(self.people or {}) do
        local id = tostring(person.id or "")
        self.peopleList:addItem(id, {
            person = person, selected = self.selectedPeopleIDs[id] == true,
        })
    end
    local selectedIndex = 0
    for index, entry in ipairs(self.peopleList.items or {}) do
        if entry.item and entry.item.person
            and tostring(entry.item.person.id or "")
                == tostring(self.selectedPersonID or "")
        then
            selectedIndex = index
            break
        end
    end
    self.peopleList.selected = selectedIndex
end

function ISPNCOrdersWindow:refreshSnapshot()
    local snapshot = currentSnapshot()
    self.snapshot = snapshot
    self.people = snapshot.people or {}
    local present = {}
    for _, person in ipairs(self.people) do
        present[tostring(person.id or "")] = true
    end
    for id, _ in pairs(self.selectedPeopleIDs or {}) do
        if not present[id] then self.selectedPeopleIDs[id] = nil end
    end
    if not present[tostring(self.selectedPersonID or "")] then
        self.selectedPersonID = self.people[1] and self.people[1].id or nil
    end
    if not self.selectedPersonID and self.people[1] then
        self.selectedPersonID = self.people[1].id
    end
    if not hasSelectedPeople(self) and self.selectedPersonID then
        self.selectedPeopleIDs[tostring(self.selectedPersonID)] = true
    end
    self:refreshPeopleRows()
    self:updateControls()
    self.lastRevision = tonumber(clientState().colonyManagementRevision) or 0
end

function ISPNCOrdersWindow:updateControls()
    local definition = self:selectedDefinition()
    local people = self:selectedPeople()
    local hasPeople = #people > 0
    local allEnabled = hasPeople
    local anyActive = false
    for _, person in ipairs(people) do
        if not isEnabled(person, definition) then allEnabled = false end
        if hasCurrentOrder(person, definition) then anyActive = true end
    end
    self.mapButton:setVisible(hasPeople and definition and definition.mapCommand ~= nil)
    self.toggleButton:setVisible(hasPeople and definition ~= nil)
    self.stopButton:setVisible(anyActive and definition ~= nil)
    if definition then
        self.toggleButton:setTitle((allEnabled
            and tr("UI_PNC_Orders_Disable", "DISABLE")
            or tr("UI_PNC_Orders_Enable", "ENABLE"))
            .. " " .. orderTitle(definition))
        self.toggleButton:setEnable(true)
    else
        self.toggleButton:setEnable(false)
    end
    self.multiButton:setTitle(self.multiSelect
        and tr("UI_PNC_Orders_MultiSelectOn", "MULTI SELECT: ON")
        or tr("UI_PNC_Orders_MultiSelectOff", "MULTI SELECT: OFF"))
    self.details.owner = self
end

function ISPNCOrdersWindow:onControl(button)
    local id = tostring(button and button.internal or "")
    if id == "close" then
        self:close()
        return true
    end
    if id == "refresh" then
        self:requestSnapshot()
        return true
    end
    if id == "multi_select" then
        self.multiSelect = not self.multiSelect
        self:updateControls()
        self:refreshPeopleRows()
        return true
    end
    local definition = self:selectedDefinition()
    local people = self:selectedPeople()
    if not definition or #people <= 0 then return false end
    if id == "configure_map" and definition.mapCommand then
        local selection = {}
        for _, person in ipairs(people) do
            local location = person.location or {}
            selection[#selection + 1] = {
                id = person.id, name = person.name,
                x = location.x, y = location.y, z = location.z or 0,
            }
        end
        if PNC.MapCommands and PNC.MapCommands.OpenForSelection(selection)
        then
            self:setVisible(false)
        end
        return true
    end
    if id == "toggle_permission" then
        local allEnabled = true
        for _, person in ipairs(people) do
            if not isEnabled(person, definition) then allEnabled = false end
        end
        local enabled = not allEnabled
        for _, person in ipairs(people) do
            if PNC.Client and PNC.Client.RequestColonyAction then
                PNC.Client.RequestColonyAction("job_permission_set", {
                    npcID = person.id, job = definition.job, enabled = enabled,
                })
            end
        end
        self:requestSnapshot()
        return true
    end
    if id == "stop_order" then
        for _, person in ipairs(people) do
            if hasCurrentOrder(person, definition)
                and PNC.Client and PNC.Client.RequestColonyAction
            then
                PNC.Client.RequestColonyAction("order_cancel", {
                    npcID = person.id, job = definition.job,
                })
            end
        end
        self:requestSnapshot()
        return true
    end
    return false
end

function ISPNCOrdersWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 12, bottom = 12 })
    local scale = self.uiScale or Layout.Scale()
    local function px(value) return Layout.Pixels(value, scale) end
    local gap = px(8)
    local controlHeight = px(28)
    local actionY = rect.y + rect.height - controlHeight
    local utilityY = actionY - controlHeight - gap
    local contentBottom = utilityY - gap
    local contentHeight = math.max(px(120), contentBottom - rect.y)
    local orderWidth = math.min(px(220), math.max(px(180),
        math.floor(rect.width * 0.25)))
    local peopleWidth = math.min(px(280), math.max(px(240),
        math.floor(rect.width * 0.31)))
    local detailX = rect.x + orderWidth + gap + peopleWidth + gap
    local detailWidth = math.max(px(160),
        rect.width - orderWidth - peopleWidth - gap * 2)
    Layout.SetBounds(self.orderList, rect.x, rect.y, orderWidth,
        contentHeight)
    Layout.SetBounds(self.peopleList, rect.x + orderWidth + gap, rect.y,
        peopleWidth, contentHeight)
    Layout.SetBounds(self.details, detailX, rect.y, detailWidth,
        contentHeight)

    local utilityWidth = px(140)
    Layout.SetBounds(self.multiButton, rect.x, utilityY, utilityWidth,
        controlHeight)
    Layout.SetBounds(self.refreshButton, rect.x + utilityWidth + gap,
        utilityY, px(90), controlHeight)

    local x = rect.x
    local actions = {
        { button = self.mapButton, width = px(170) },
        { button = self.toggleButton, width = px(170) },
        { button = self.stopButton, width = px(130) },
        { button = self.closeButton, width = px(80) },
    }
    for _, action in ipairs(actions) do
        Layout.SetBounds(action.button, x, actionY, action.width,
            controlHeight)
        x = x + action.width + gap
    end
    self.layout = { rect = rect, contentBottom = contentBottom }
end

function ISPNCOrdersWindow:requestSnapshot()
    if PNC.Client and PNC.Client.RequestColonyManagement then
        PNC.Client.RequestColonyManagement()
    end
    self.lastRequestAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

function ISPNCOrdersWindow:prerender()
    local state = clientState()
    local revision = tonumber(state.colonyManagementRevision) or 0
    if revision ~= (tonumber(self.lastRevision) or -1) then
        self:refreshSnapshot()
    end
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if now - (tonumber(self.lastRequestAt) or 0) >= 2000 then
        self:requestSnapshot()
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCOrdersWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then return end
    local rect = self.layout.rect
    UI.DrawSectionTitle(self, tr("UI_PNC_Orders_OrderTypes", "ORDER TYPES"),
        rect.x, rect.y - 22, self.orderList:getWidth())
    UI.DrawSectionTitle(self, tr("UI_PNC_Orders_Colonists", "COLONISTS"),
        self.peopleList:getX(), rect.y - 22, self.peopleList:getWidth())
    UI.DrawSectionTitle(self, tr("UI_PNC_Orders_Details", "ORDER DETAILS"),
        self.details:getX(), rect.y - 22, self.details:getWidth())
end

function ISPNCOrdersWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if OrdersUI.instance == self then OrdersUI.instance = nil end
end

function ISPNCOrdersWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function OrdersUI.Open()
    local window = OrdersUI.instance
    if not window then
        window = UI.NewWindow(ISPNCOrdersWindow, {
            title = tr("UI_PNC_Orders_WindowTitle", "ORDERS"),
            resizable = true,
            persistenceKey = "PNC.Orders",
            responsiveSpec = {
                width = 980, height = 620,
                minWidth = 700, minHeight = 480,
                maxWidth = 1320, maxHeight = 860,
            },
        })
        window:initialise()
        window:instantiate()
        OrdersUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:refreshSnapshot()
    window:requestSnapshot()
    return window
end

function OrdersUI.Toggle()
    if OrdersUI.instance and OrdersUI.instance:getIsVisible() then
        OrdersUI.instance:close()
        return false
    end
    return OrdersUI.Open() ~= nil
end

return OrdersUI
