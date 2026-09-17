-- Actor-slot and relative-anchor layout editor.

require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaAnchorGrid"

PNC = PNC or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local addDetail = UI.AddKeyValue

local function resizeRows(list, itemHeight)
    if not list then return end
    itemHeight = math.max(1, math.floor(itemHeight))
    list.itemheight = itemHeight
    for _, item in ipairs(list.items or {}) do
        item.height = itemHeight
    end
    if list.setScrollHeight then
        list:setScrollHeight(#(list.items or {}) * itemHeight)
    end
end

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
    local width = math.max(32, list:getWidth() - 16)
    if selected then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.35, 0.20, 0.48, 0.82)
    elseif alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20)
    end
    list:drawText(Layout.Ellipsize(tostring(actor.label), UIFont.Small, width), 8, y + 5,
        0.92, 0.94, 1.00, 1, UIFont.Small)
    list:drawText(
        Layout.Ellipsize(
            tostring(actor.kind) .. "  anchor=" .. tostring(actor.anchor),
            UIFont.Small,
            width
        ),
        8, y + 24,
        0.62, 0.76, 0.84, 1, UIFont.Small
    )
    list:drawTextRight(
        Layout.Ellipsize(tostring(actor.state), UIFont.Small,
            math.max(32, list:getWidth() * 0.42)),
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

local function drawLiveRow(list, y, row, alternate)
    local actor = row.item
    local selected = list.selected == row.index
    local width = math.max(32, list:getWidth() - 16)
    if selected then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.35, 0.20, 0.48, 0.82)
    elseif alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20)
    end
    list:drawText(Layout.Ellipsize(tostring(actor.name), UIFont.Small, width), 8, y + 5,
        0.92, 0.94, 1.00, 1, UIFont.Small)
    local assignment = actor.assignedActorID
        and tr("UI_PNC_PuppetOpera_AssignedTo", "assigned to")
            .. " " .. tostring(actor.assignedActorID)
        or tr("UI_PNC_PuppetOpera_UnassignedDrop",
            "unassigned - drag to the graph")
    local state = actor.reason
        or actor.actionContextState
        or actor.actionState
        or ""
    local detail = assignment
    if state ~= "" then detail = detail .. "  state=" .. tostring(state) end
    list:drawText(
        Layout.Ellipsize(detail, UIFont.Small, width),
        8,
        y + 24,
        actor.ready == false and 1.00
            or actor.assignedActorID and 0.72 or 0.98,
        actor.ready == false and 0.45
            or actor.assignedActorID and 0.80 or 0.66,
        actor.ready == false and 0.40
            or actor.assignedActorID and 0.84 or 0.40,
        1,
        UIFont.Small
    )
    list:drawTextRight(
        string.format("%.1f tiles", math.sqrt(tonumber(actor.distSq) or 0)),
        list:getWidth() - 8,
        y + 5,
        0.62,
        0.76,
        0.84,
        1,
        UIFont.Small
    )
    local readiness = actor.ready == true
        and tr("UI_PNC_PuppetOpera_Ready", "READY")
        or actor.ready == false
        and tr("UI_PNC_PuppetOpera_Blocked", "BLOCKED")
        or tr("UI_PNC_PuppetOpera_Checking", "CHECKING")
    list:drawTextRight(
        readiness,
        list:getWidth() - 8,
        y + 24,
        actor.ready == true and 0.40 or actor.ready == false and 1.00 or 0.80,
        actor.ready == true and 0.95 or actor.ready == false and 0.42 or 0.80,
        actor.ready == true and 0.58 or actor.ready == false and 0.38 or 0.42,
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

function ISPNCPuppetOperaLayoutTab:setLivePointerFromEvent(list, x, y)
    if not list or type(x) ~= "number" or type(y) ~= "number" then
        return false
    end
    self.livePointerX = list:getAbsoluteX() + x
    self.livePointerY = list:getAbsoluteY() + y
    return true
end

function ISPNCPuppetOperaLayoutTab:updateLiveDropPreview()
    if not self.livePointerX or not self.livePointerY then return false end
    local x = self.livePointerX - self.grid:getAbsoluteX()
    local y = self.livePointerY - self.grid:getAbsoluteY()
    local inside = self.grid:containsGraphPoint(x, y)
    local right, forward = self.grid:cellAt(x, y)
    self.grid.dropPreview = {
        right = right,
        forward = forward,
        inside = inside,
        occupied = inside
            and self.model.GetActorAtOffset(right, forward) ~= nil
            or false,
    }
    return inside
end

function ISPNCPuppetOperaLayoutTab:updateLiveDrag(dx, dy)
    if not self.liveDragPending then return false end
    self.liveDragX = (tonumber(self.liveDragX) or 0) + (tonumber(dx) or 0)
    self.liveDragY = (tonumber(self.liveDragY) or 0) + (tonumber(dy) or 0)
    self.livePointerX = (tonumber(self.livePointerX) or 0)
        + (tonumber(dx) or 0)
    self.livePointerY = (tonumber(self.livePointerY) or 0)
        + (tonumber(dy) or 0)
    if not self.liveDragging then
        local distance = math.abs(self.liveDragX) + math.abs(self.liveDragY)
        if distance < 6 then return true end
        self.liveDragging = true
    end
    self:updateLiveDropPreview()
    return true
end

function ISPNCPuppetOperaLayoutTab:finishLiveDrag(list, x, y)
    if not self.liveDragPending then return false end
    self:setLivePointerFromEvent(list, x, y)
    local actorID = self.liveDragActorID
    local dragged = self.liveDragging == true
    local accepted = false
    local reason
    if dragged then
        local gridX = self.livePointerX - self.grid:getAbsoluteX()
        local gridY = self.livePointerY - self.grid:getAbsoluteY()
        if self.grid:containsGraphPoint(gridX, gridY) then
            local right, forward = self.grid:cellAt(gridX, gridY)
            local occupant = self.model.GetActorAtOffset(right, forward)
            if occupant then
                local liveRows = self.model.GetLiveActorRows(
                    self.model.GetActorDiscoveryRadius()
                )
                local draggedRow
                for _, liveRow in ipairs(liveRows) do
                    if tostring(liveRow.id) == tostring(actorID) then
                        draggedRow = liveRow
                        break
                    end
                end
                if draggedRow
                    and draggedRow.assignedActorID
                    and occupant
                    and tostring(occupant.id)
                        == tostring(draggedRow.assignedActorID)
                then
                    accepted, reason = self.model.AddLiveActorToScene(
                        actorID, right, forward, 0
                    )
                else
                    reason = "anchor_tile_occupied"
                end
            else
                accepted, reason = self.model.AddLiveActorToScene(
                    actorID, right, forward, 0
                )
            end
        else
            reason = "live_actor_drop_outside_grid"
        end
    end
    self.liveDragPending = nil
    self.liveDragActorID = nil
    self.liveDragX = nil
    self.liveDragY = nil
    self.liveDragging = nil
    self.livePointerX = nil
    self.livePointerY = nil
    self.grid.dropPreview = nil
    self.liveList:setCapture(false)
    if dragged and self.ownerWindow then
        self.ownerWindow:setEditorStatus(
            accepted and "live_actor_added_to_scene" or reason,
            not accepted
        )
        self.ownerWindow:refreshViews()
        if accepted and self.ownerWindow.requestPlacementPreview then
            self.ownerWindow:requestPlacementPreview()
        end
    end
    return true
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

    self.liveList = UI.CreateList(self, {
        itemHeight = 50,
        doDrawItem = drawLiveRow,
    })
    self.liveList.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        local selected = list:getItem()
        if selected and selected.item and self.model then
            local accepted, reason = self.model.SelectLiveActor(
                selected.item.id
            )
            self.liveDragPending = true
            self.liveDragActorID = selected.item.id
            self.liveDragX = 0
            self.liveDragY = 0
            self.liveDragging = false
            self.livePointerX = list:getAbsoluteX() + (tonumber(x) or 0)
            self.livePointerY = list:getAbsoluteY() + (tonumber(y) or 0)
            list:setCapture(true)
            -- Do not clear/rebuild the captured list during mouse-down.  The
            -- native list can drop capture when its items are cleared; status
            -- and marker selection are rendered from the model on the next
            -- frame, while the full refresh happens after the drop.
            if self.ownerWindow then
                self.ownerWindow:setEditorStatus(
                    accepted and "live_actor_selected_drag_to_grid" or reason,
                    not accepted
                )
            end
        end
        return true
    end
    self.liveList.onMouseMove = function(list, dx, dy)
        if self:updateLiveDrag(dx, dy) then return true end
        return ISScrollingListBox.onMouseMove(list, dx, dy)
    end
    self.liveList.onMouseMoveOutside = function(list, dx, dy)
        if self:updateLiveDrag(dx, dy) then return true end
        return ISScrollingListBox.onMouseMoveOutside(list, dx, dy)
    end
    self.liveList.onMouseUp = function(list, x, y)
        if self:finishLiveDrag(list, x, y) then return true end
        return ISScrollingListBox.onMouseUp(list, x, y)
    end
    self.liveList.onMouseUpOutside = function(list, x, y)
        if self:finishLiveDrag(list, x, y) then return true end
        return ISScrollingListBox.onMouseUpOutside(list, x, y)
    end

    self.grid = ISPNCPuppetOperaAnchorGrid:new(0, 0, 1, 1)
    self.grid:initialise()
    self.grid:instantiate()
    self:addChild(self.grid)

    self.details = UI.CreateKeyValueList(self, {
        itemHeight = 25,
        valueXRatio = 0.34,
        valueXMax = 92,
        ellipsize = true,
        labelX = 8,
        labelY = 6,
        valueY = 6,
        drawSelection = false,
    })
    self.removeButton = UI.CreateButton(self, {
        id = "remove_actor",
        title = tr("UI_PNC_PuppetOpera_RemoveActor", "Remove selected actor"),
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return self:onAction(button)
        end),
        variant = "danger",
    })
end

function ISPNCPuppetOperaLayoutTab:setContext(window)
    self.ownerWindow = window
    self.model = window and window.model or nil
    self.grid:setModel(self.model)
    self.grid.ownerWindow = window
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

    if not self.liveDragPending then
        self.liveList:clear()
        local selectedLiveIndex = 1
        for index, row in ipairs(self.model.GetLiveActorRows(
            self.model.GetActorDiscoveryRadius()
        )) do
            self.liveList:addItem(row.id, row)
            if tostring(row.id) == tostring(
                self.model.GetPendingLiveActorID()
                    or self.model.GetSelectedNPCID()
                    or ""
            ) then
                selectedLiveIndex = index
            end
        end
        if #self.liveList.items > 0 then
            self.liveList.selected = selectedLiveIndex
        end
    end

    self.details:clear()
    local selected
    for _, row in ipairs(self.model.GetActorRows(
        self.model.GetSnapshot()
    )) do
        if tostring(row.id) == tostring(selectedID) then selected = row break end
    end
    if not selected then
        addDetail(self.details, "Selection", tr(
            "UI_PNC_PuppetOpera_NoActorSelected", "No actor slot selected"), true)
    else
        addDetail(self.details, "Actor", selected.label)
        addDetail(self.details, "Kind", selected.kind)
        addDetail(self.details, "Anchor", selected.anchor)
        addDetail(self.details, "Binding", selected.bindingID or tr(
            "UI_PNC_PuppetOpera_Unassigned", "unassigned"),
            selected.kind == "nearby_live_npc" and not selected.bindingID)
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
    addDetail(self.details, "Placement", tr(
        "UI_PNC_PuppetOpera_PlacementHint",
        "Drag a live actor onto an empty tile"))
    addDetail(self.details, "Runtime safety", tr(
        "UI_PNC_PuppetOpera_RuntimeSafety",
        "No teleport; server derives world targets"))
end

function ISPNCPuppetOperaLayoutTab:onAction(button)
    local id = button and button.internal or ""
    if id ~= "remove_actor" or not self.model then return false end
    local accepted, reason = self.model.RemoveActor(
        self.model.GetSelectedActorID()
    )
    if self.ownerWindow then
        self.ownerWindow:setEditorStatus(reason or "actor_removed", not accepted)
        self.ownerWindow:refreshViews()
    end
    return accepted == true
end

function ISPNCPuppetOperaLayoutTab:render()
    ISPanel.render(self)
    local scale = self.ownerWindow and self.ownerWindow.uiScale
    local pad = Layout.Pixels(8, scale)
    self:drawText(
        tr("UI_PNC_PuppetOpera_SceneActors", "Scene actors"),
        pad,
        2,
        0.82,
        0.88,
        0.94,
        1,
        UIFont.Small
    )
    self:drawText(
        tr("UI_PNC_PuppetOpera_LiveActors", "Nearby live actors"),
        pad,
        self.liveList and self.liveList:getY() - Layout.Pixels(18, scale) or 0,
        0.82,
        0.88,
        0.94,
        1,
        UIFont.Small
    )
end

function ISPNCPuppetOperaLayoutTab:onResponsiveLayout()
    local scale = self.ownerWindow and self.ownerWindow.uiScale
    local pad = Layout.Pixels(8, scale)
    local gap = Layout.Pixels(8, scale)
    local width = self:getWidth()
    local height = self:getHeight()
    resizeRows(self.actorList, Layout.Pixels(50, scale))
    resizeRows(self.liveList, Layout.Pixels(50, scale))
    resizeRows(self.details, Layout.Pixels(25, scale))
    if self.actorList then self.actorList.uiScale = scale end
    if self.liveList then self.liveList.uiScale = scale end
    local columnsWidth = math.max(1, width - pad * 2 - gap * 2)
    local leftWidth = math.floor(columnsWidth * 0.24)
    local rightWidth = math.floor(columnsWidth * 0.28)
    local centerWidth = columnsWidth - leftWidth - rightWidth
    if centerWidth < Layout.Pixels(220, scale) then
        leftWidth = math.floor(columnsWidth * 0.20)
        rightWidth = math.floor(columnsWidth * 0.25)
        centerWidth = columnsWidth - leftWidth - rightWidth
    end
    leftWidth = math.max(Layout.Pixels(132, scale), leftWidth)
    rightWidth = math.max(Layout.Pixels(156, scale), rightWidth)
    if leftWidth + rightWidth >= columnsWidth then
        leftWidth = math.max(1, math.floor(columnsWidth * 0.25))
        rightWidth = math.max(1, math.floor(columnsWidth * 0.28))
    end
    centerWidth = math.max(1, columnsWidth - leftWidth - rightWidth)
    centerWidth = math.max(1, centerWidth)

    local leftX = pad
    local leftTop = Layout.Pixels(22, scale)
    local leftBottom = height - pad
    local sceneHeight = math.max(Layout.Pixels(56, scale),
        math.floor((leftBottom - leftTop - gap - Layout.Pixels(20, scale))
            * 0.46))
    local liveTop = leftTop + sceneHeight + gap + Layout.Pixels(20, scale)
    local liveHeight = math.max(1, leftBottom - liveTop)
    Layout.SetBounds(self.actorList, leftX, leftTop, leftWidth, sceneHeight)
    Layout.SetBounds(self.liveList, leftX, liveTop, leftWidth, liveHeight)

    local gridX = leftX + leftWidth + gap
    Layout.SetBounds(self.grid, gridX, pad,
        centerWidth, height - pad * 2)

    local detailsX = gridX + centerWidth + gap
    local detailsHeight = math.max(Layout.Pixels(1, scale),
        height - pad * 2 - Layout.Pixels(38, scale))
    Layout.SetBounds(self.details, detailsX, pad,
        math.max(1, width - detailsX - pad), detailsHeight)
    Layout.SetBounds(self.removeButton, detailsX,
        height - pad - Layout.Pixels(28, scale),
        math.max(1, width - detailsX - pad), Layout.Pixels(26, scale))
end

return ISPNCPuppetOperaLayoutTab
