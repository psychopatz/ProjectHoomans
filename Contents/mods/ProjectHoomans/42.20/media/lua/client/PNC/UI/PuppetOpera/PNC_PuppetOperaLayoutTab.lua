-- Actor-slot and relative-anchor layout editor.

require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaAnchorGrid"

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

local function drawActorRow(list, y, row, alternate)
    local actor = row.item
    local selected = list.selected == row.index
    if selected then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.35, 0.20, 0.48, 0.82)
    elseif alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20)
    end
    list:drawText(tostring(actor.label), 8, y + 5,
        0.92, 0.94, 1.00, 1, UIFont.Small)
    list:drawText(
        tostring(actor.kind) .. "  anchor=" .. tostring(actor.anchor),
        8, y + 24,
        0.62, 0.76, 0.84, 1, UIFont.Small
    )
    list:drawTextRight(
        tostring(actor.state) .. (actor.owned and "  owned" or ""),
        list:getWidth() - 8,
        y + 5,
        actor.owned and 0.55 or 0.72,
        actor.owned and 1.00 or 0.80,
        actor.owned and 0.65 or 0.86,
        1,
        UIFont.Small
    )
    return y + list.itemheight
end

ISPNCPuppetOperaLayoutTab = ISPanel:derive("ISPNCPuppetOperaLayoutTab")

function ISPNCPuppetOperaLayoutTab:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function ISPNCPuppetOperaLayoutTab:createChildren()
    ISPanel.createChildren(self)
    self.actorList = UI.CreateList(self, {
        itemHeight = 50,
        doDrawItem = drawActorRow,
    })
    self.actorList.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        local selected = list:getItem()
        if selected and selected.item and self.model then
            self.model.SelectActor(selected.item.id)
            self:refresh()
            if self.ownerWindow then self.ownerWindow:refreshViews() end
        end
    end
    self.grid = ISPNCPuppetOperaAnchorGrid:new(0, 0, 1, 1)
    self.grid:initialise()
    self.grid:instantiate()
    self:addChild(self.grid)
    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 25,
        valueXRatio = 0.34,
        ellipsize = false,
        labelX = 8,
        labelY = 6,
        valueY = 6,
        drawSelection = false,
    })
    self.future3Button = UI.CreateButton(self, {
        id = "future_actor_3",
        title = tr("UI_PNC_PuppetOpera_FutureActor3",
            "Actor slot 3 (future)"),
        target = self,
        onclick = UI.ButtonCallback(function(button)
            if self.ownerWindow then
                self.ownerWindow:setEditorStatus("future_actor_slots_reserved")
            end
            return false
        end),
        variant = "quiet",
    })
    self.future4Button = UI.CreateButton(self, {
        id = "future_actor_4",
        title = tr("UI_PNC_PuppetOpera_FutureActor4",
            "Actor slot 4 (future)"),
        target = self,
        onclick = UI.ButtonCallback(function(button)
            if self.ownerWindow then
                self.ownerWindow:setEditorStatus("future_actor_slots_reserved")
            end
            return false
        end),
        variant = "quiet",
    })
    self.future3Button:setEnable(false)
    self.future4Button:setEnable(false)
end

function ISPNCPuppetOperaLayoutTab:setContext(window)
    self.ownerWindow = window
    self.model = window and window.model or nil
    self.grid:setModel(self.model)
    self:refresh()
end

function ISPNCPuppetOperaLayoutTab:refresh()
    if not self.model or not self.actorList then return end
    local selectedID = self.model.GetSelectedActorID()
    self.actorList:clear()
    local selectedIndex = 1
    for index, row in ipairs(self.model.GetActorRows(
        self.model.GetSnapshot()
    )) do
        self.actorList:addItem(row.id, row)
        if tostring(row.id) == tostring(selectedID) then
            selectedIndex = index
        end
    end
    if #self.actorList.items > 0 then self.actorList.selected = selectedIndex end

    self.details:clear()
    local selected
    for _, row in ipairs(self.model.GetActorRows(
        self.model.GetSnapshot()
    )) do
        if tostring(row.id) == tostring(selectedID) then selected = row break end
    end
    if not selected then
        addDetail(self.details, "Selection", "No actor slot selected", true)
    else
        addDetail(self.details, "Actor", selected.label)
        addDetail(self.details, "Kind", selected.kind)
        addDetail(self.details, "Anchor", selected.anchor)
        for _, gridRow in ipairs(self.model.GetGridActors()) do
            if gridRow.id == selected.id then
                addDetail(self.details, "Relative tile",
                    "right=" .. tostring(gridRow.right)
                    .. " forward=" .. tostring(gridRow.forward)
                    .. " z=" .. tostring(gridRow.z))
                addDetail(self.details, "Faces", gridRow.faceTarget)
                break
            end
        end
        addDetail(self.details, "Selected beat",
            tostring(self.model.GetSelectedBeatIndex()))
        addDetail(self.details, "Assigned track",
            self.model.GetSelectionSummary(selected.id))
    end
    addDetail(self.details, "Drag behavior",
        "Markers snap to relative whole tiles")
    addDetail(self.details, "Runtime safety",
        "No teleport; server derives world targets")
end

function ISPNCPuppetOperaLayoutTab:onResponsiveLayout()
    local scale = self.ownerWindow and self.ownerWindow.uiScale
    local pad = Layout.Pixels(8, scale)
    local top = Layout.Pixels(4, scale)
    local leftWidth = math.max(Layout.Pixels(220, scale),
        math.floor(self:getWidth() * 0.23))
    local rightWidth = math.max(Layout.Pixels(255, scale),
        math.floor(self:getWidth() * 0.27))
    Layout.SetBounds(self.actorList, pad, top, leftWidth,
        self:getHeight() - top - pad)
    Layout.SetBounds(self.grid, leftWidth + pad * 2, top,
        self:getWidth() - leftWidth - rightWidth - pad * 4,
        self:getHeight() - top - pad)
    Layout.SetBounds(self.details,
        self:getWidth() - rightWidth - pad,
        top,
        rightWidth,
        self:getHeight() - top - Layout.Pixels(112, scale))
    Layout.SetBounds(self.future3Button,
        self:getWidth() - rightWidth - pad,
        self:getHeight() - Layout.Pixels(94, scale),
        rightWidth,
        Layout.Pixels(26, scale))
    Layout.SetBounds(self.future4Button,
        self:getWidth() - rightWidth - pad,
        self:getHeight() - Layout.Pixels(60, scale),
        rightWidth,
        Layout.Pixels(26, scale))
end

return ISPNCPuppetOperaLayoutTab
