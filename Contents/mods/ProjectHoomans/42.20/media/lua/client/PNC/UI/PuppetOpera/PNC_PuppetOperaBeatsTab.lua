-- Ordered beat editor for a Puppet Opera blueprint.

require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local addDetail = UI.AddKeyValue

local function tr(key, fallback)
    local translation = PNC.Translation
    local value = translation and translation.GetKey
        and translation.GetKey(key, fallback) or fallback
    if not value or value == "" or value == key then return fallback end
    return value
end

local function drawBeatItem(list, y, row, alternate)
    local beat = row.item
    local selected = list.selected == row.index
    if selected then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.35, 0.20, 0.48, 0.82)
    elseif alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20)
    end
    list:drawText(
        tostring(row.index) .. ".  " .. tostring(beat.id),
        8, y + 5,
        0.92, 0.94, 1.00, 1, UIFont.Small
    )
    list:drawText(
        Layout.Ellipsize(
            tostring(row.summary or "No tracks assigned"),
            UIFont.Small,
            math.max(32, list:getWidth() - 16)
        ),
        8, y + 24,
        0.62, 0.82, 0.95, 1, UIFont.Small
    )
    list:drawTextRight(
        tostring(beat.durationMs or "-") .. " ms",
        list:getWidth() - 8,
        y + 5,
        0.72, 0.78, 0.84, 1, UIFont.Small
    )
    return y + list.itemheight
end

ISPNCPuppetOperaBeatsTab = ISPanel:derive("ISPNCPuppetOperaBeatsTab")

function ISPNCPuppetOperaBeatsTab:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCPuppetOperaBeatsTab:createChildren()
    ISPanel.createChildren(self)
    self.beatList = UI.CreateList(self, {
        itemHeight = 50,
        doDrawItem = drawBeatItem,
    })
    self.beatList.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        local selected = list:getItem()
        if selected and selected.index and self.model then
            self.model.SelectBeat(selected.index)
            self:refresh()
            if self.ownerWindow then self.ownerWindow:refreshViews() end
        end
    end
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 25,
        valueXRatio = 0.34,
        valueXMax = 112,
        ellipsize = true,
        labelX = 8,
        labelY = 6,
        valueY = 6,
        drawSelection = false,
    })
    self.durationEntry = UI.CreateTextEntry(self, {
        clearButton = false,
        width = 100,
        height = 26,
    })
    self.applyDurationButton = UI.CreateButton(self, {
        id = "apply_duration",
        title = tr("UI_PNC_PuppetOpera_ApplyDuration", "Apply duration"),
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return self:onAction(button)
        end),
        variant = "selected",
    })
    self.buttons = {}
    for _, definition in ipairs({
        { "add", "ADD BEAT", "selected" },
        { "duplicate", "DUPLICATE", "quiet" },
        { "remove", "REMOVE", "danger" },
        { "up", "MOVE UP", "quiet" },
        { "down", "MOVE DOWN", "quiet" },
    }) do
        local button = UI.CreateButton(self, {
            id = definition[1],
            title = definition[2],
            target = self,
            onclick = UI.ButtonCallback(function(clicked)
                return self:onAction(clicked)
            end),
            variant = definition[3],
        })
        self.buttons[#self.buttons + 1] = button
        self[definition[1] .. "Button"] = button
    end
end

function ISPNCPuppetOperaBeatsTab:setContext(window)
    self.ownerWindow = window
    self.model = window and window.model or nil
    self:refresh()
end

function ISPNCPuppetOperaBeatsTab:refresh()
    if not self.model or not self.beatList then return end
    local selectedIndex = self.model.GetSelectedBeatIndex()
    self.beatList:clear()
    for index, row in ipairs(self.model.GetBeatRows()) do
        self.beatList:addItem(row.id, row)
        if index == selectedIndex then self.beatList.selected = index end
    end
    if #self.beatList.items > 0 and (tonumber(self.beatList.selected) or 0) < 1
    then
        self.beatList.selected = 1
    end
    local beat = self.model.GetSelectedBeat()
    if self.durationEntry then
        self.durationEntry:setText(tostring(beat and beat.durationMs or ""))
    end
    self.details:clear()
    if not beat then
        addDetail(self.details, "Selection", "No beat selected", true)
        return
    end
    addDetail(self.details, "Beat", beat.id)
    addDetail(self.details, "Duration", tostring(beat.durationMs) .. " ms")
    addDetail(self.details, "Synchronization",
        beat.synchronization or "arrival_and_start_barrier")
    for _, actor in ipairs(self.model.GetActorRows(nil)) do
        local trackLabel = tostring(actor.label)
            .. " [slot=" .. tostring(actor.id) .. "]"
        if actor.liveName and actor.liveID then
            trackLabel = trackLabel .. " -> " .. tostring(actor.liveName)
                .. " [" .. tostring(actor.liveID) .. "]"
        end
        addDetail(self.details, "Track " .. trackLabel,
            self.model.GetSelectionSummary(actor.id),
            actor.supported ~= true)
    end
    local schemaOK, runtimeReason = self.model.GetValidation()
    addDetail(self.details, "MP policy",
        not schemaOK and "invalid draft"
            or (runtimeReason and "local preview; server will reject"
                or "server-approved"),
        not schemaOK or runtimeReason ~= nil)
end

function ISPNCPuppetOperaBeatsTab:onAction(button)
    if not self.model then return false end
    local id = button and button.internal or ""
    local accepted
    local reason
    if id == "add" or id == "duplicate" then
        accepted, reason = self.model.AddBeat()
    elseif id == "remove" then
        accepted, reason = self.model.RemoveBeat()
    elseif id == "up" then
        accepted, reason = self.model.MoveBeat(-1)
    elseif id == "down" then
        accepted, reason = self.model.MoveBeat(1)
    elseif id == "apply_duration" then
        accepted, reason = self.model.SetBeatDuration(
            self.durationEntry:getText()
        )
    end
    if not accepted then
        if self.ownerWindow then self.ownerWindow:setEditorStatus(reason) end
        return false
    end
    if self.ownerWindow then
        self.ownerWindow:setEditorStatus("beat_updated")
        self.ownerWindow:refreshViews()
    end
    return true
end

function ISPNCPuppetOperaBeatsTab:onResponsiveLayout()
    local scale = self.ownerWindow and self.ownerWindow.uiScale
    local pad = Layout.Pixels(8, scale)
    local top = Layout.Pixels(4, scale)
    local leftWidth = math.max(Layout.Pixels(200, scale),
        math.floor(self:getWidth() * 0.36))
    leftWidth = math.min(leftWidth,
        math.max(Layout.Pixels(1, scale), self:getWidth() - pad * 3
            - Layout.Pixels(190, scale)))
    local bottom = Layout.Pixels(132, scale)
    Layout.SetBounds(self.beatList, pad, top, leftWidth,
        self:getHeight() - top - Layout.Pixels(44, scale))
    Layout.SetBounds(self.durationEntry, pad,
        self:getHeight() - Layout.Pixels(34, scale),
        Layout.Pixels(120, scale), Layout.Pixels(26, scale))
    Layout.SetBounds(self.applyDurationButton,
        pad + Layout.Pixels(128, scale),
        self:getHeight() - Layout.Pixels(34, scale),
        Layout.Pixels(140, scale), Layout.Pixels(26, scale))
    local rightX = leftWidth + pad * 2
    Layout.SetBounds(self.details, rightX, top,
        math.max(1, self:getWidth() - rightX - pad),
        math.max(1, self:getHeight() - top - bottom))
    local buttonAreaWidth = math.max(1, self:getWidth() - rightX - pad)
    local columns = buttonAreaWidth >= Layout.Pixels(500, scale) and 5 or 3
    local buttonWidth = math.max(Layout.Pixels(64, scale),
        math.floor((buttonAreaWidth - pad * (columns - 1)) / columns))
    local buttonTop = self:getHeight() - Layout.Pixels(98, scale)
    for index, button in ipairs(self.buttons) do
        local row = math.floor((index - 1) / columns)
        local column = (index - 1) % columns
        Layout.SetBounds(button,
            rightX + column * (buttonWidth + pad),
            buttonTop + row * Layout.Pixels(31, scale),
            buttonWidth, Layout.Pixels(26, scale))
    end
end

return ISPNCPuppetOperaBeatsTab
