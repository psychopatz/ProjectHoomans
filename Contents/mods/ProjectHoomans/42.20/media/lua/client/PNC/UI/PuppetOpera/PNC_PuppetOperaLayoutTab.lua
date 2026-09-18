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
    local liveID = actor.liveShortID
        and (" [" .. tostring(actor.liveShortID) .. "]") or ""
    local identity = actor.liveName
        and ("  -> " .. tostring(actor.liveName) .. liveID)
        or "  -> unbound"
    list:drawText(Layout.Ellipsize(
        tostring(actor.label) .. identity,
        UIFont.Small,
        width
    ), 8, y + 5,
        0.92, 0.94, 1.00, 1, UIFont.Small)
    list:drawText(
        Layout.Ellipsize(
            "slot=" .. tostring(actor.id)
                .. "  " .. tostring(actor.kind or "unbound")
                .. "  anchor=" .. tostring(actor.anchor),
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
    local assignment = actor.assignedActorID
        and ("BOUND slot=" .. tostring(actor.assignedActorID))
        or tr("UI_PNC_PuppetOpera_FreeActor", "FREE - drag to graph")
    local readiness = actor.ready == true
        and tr("UI_PNC_PuppetOpera_Ready", "READY")
        or actor.ready == false
        and tr("UI_PNC_PuppetOpera_Blocked", "BLOCKED")
        or tr("UI_PNC_PuppetOpera_Checking", "CHECKING")
    if selected then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.35, 0.20, 0.48, 0.82)
    elseif alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20)
    end
    local shortID = actor.shortID and (" [" .. tostring(actor.shortID)
        .. "]") or ""
    local identity = tostring(actor.name) .. shortID
    list:drawText(Layout.Ellipsize(identity, UIFont.Small,
        math.max(32, width - 72)), 8, y + 3,
        0.92, 0.94, 1.00, 1, UIFont.Small)
    list:drawText(
        Layout.Ellipsize(assignment .. "  id=" .. tostring(actor.id), UIFont.Small,
            math.max(32, width - 72)),
        8,
        y + 19,
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
        y + 3,
        0.62,
        0.76,
        0.84,
        1,
        UIFont.Small
    )
    list:drawTextRight(
        readiness,
        list:getWidth() - 8,
        y + 19,
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
    if not list then
        return false
    end
    local candidates = {}
    local function addCandidate(candidateX, candidateY)
        if type(candidateX) == "number" and type(candidateY) == "number" then
            candidates[#candidates + 1] = {
                x = candidateX,
                y = candidateY,
            }
        end
    end
    -- Mouse-up-outside coordinates are list-local in some ISUI paths and
    -- stale capture coordinates in others. Prefer the global screen point,
    -- but accept the event-local projection when it is the one that lands on
    -- the graph. This keeps a captured list from turning a valid drop into
    -- `outside_grid` after the pointer crosses a sibling panel.
    if type(getMouseX) == "function" and type(getMouseY) == "function" then
        addCandidate(getMouseX(), getMouseY())
    end
    if type(x) == "number" and type(y) == "number" then
        addCandidate(list:getAbsoluteX() + x, list:getAbsoluteY() + y)
        addCandidate(x, y)
    end
    for _, candidate in ipairs(candidates) do
        if self.grid and self.grid.containsGraphPoint then
            local graphX = candidate.x - self.grid:getAbsoluteX()
            local graphY = candidate.y - self.grid:getAbsoluteY()
            if self.grid:containsGraphPoint(graphX, graphY) then
                self.livePointerX = candidate.x
                self.livePointerY = candidate.y
                return true
            end
        end
    end
    local fallback = candidates[1]
    if not fallback then return false end
    self.livePointerX = fallback.x
    self.livePointerY = fallback.y
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
    local actorID = self.liveDragActorID
    local dragged = self.liveDragging == true
    local accepted = false
    local reason
    if dragged then
        self:setLivePointerFromEvent(list, x, y)
        local gridX = self.livePointerX - self.grid:getAbsoluteX()
        local gridY = self.livePointerY - self.grid:getAbsoluteY()
        if self.grid:containsGraphPoint(gridX, gridY) then
            local right, forward = self.grid:cellAt(gridX, gridY)
            local occupant = self.model.GetActorAtOffset(right, forward)
            if occupant then
                accepted, reason = self.model.AddLiveActorToScene(
                    actorID, right, forward, 0, occupant.id
                )
            else
                accepted, reason = self.model.AddLiveActorToScene(
                    actorID, right, forward, 0,
                    self.model.GetSelectedActorID()
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
            self:setLivePointerFromEvent(list, x, y)
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
    self.addButton = UI.CreateButton(self, {
        id = "add_actor",
        title = tr("UI_PNC_PuppetOpera_AddActor", "Add actor slot"),
        target = self,
        onclick = UI.ButtonCallback(function(button)
            return self:onAction(button)
        end),
        variant = "quiet",
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
    local selectedIndex = nil
    for index, row in ipairs(self.model.GetActorRows(
        self.model.GetSnapshot()
    )) do
        self.actorList:addItem(row.id, row)
        if tostring(row.id) == tostring(selectedID) then
            selectedIndex = index
        end
    end
    self.actorList.selected = selectedIndex or 0

    if not self.liveDragPending then
        self.liveList:clear()
        local selectedLiveIndex = nil
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
        self.liveList.selected = selectedLiveIndex or 0
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
        addDetail(self.details, "Scene slot", selected.id)
        addDetail(self.details, "Kind", selected.kind or "unbound")
        addDetail(self.details, "Allowed kinds",
            table.concat(selected.allowedKinds or {}, ", "))
        addDetail(self.details, "Anchor", selected.anchor)
        addDetail(self.details, "Binding", selected.bindingID or tr(
            "UI_PNC_PuppetOpera_Unassigned", "unassigned"),
            not selected.bindingID)
        if selected.liveID then
            addDetail(self.details, "Live actor", selected.liveName or "-")
            addDetail(self.details, "Live ID", selected.liveID)
        end
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
        if selected.kind == "nearby_live_npc" and selected.bindingID
            and self.model.GetLiveActorReadiness
        then
            local readiness = self.model.GetLiveActorReadiness(
                selected.bindingID
            )
            if readiness then
                addDetail(self.details, "Live readiness",
                    readiness.ready and "ready" or "blocked",
                    readiness.ready ~= true)
                addDetail(self.details, "Action state",
                    readiness.actionState or "-")
                addDetail(self.details, "Action context",
                    readiness.actionContextState or "-")
                addDetail(self.details, "Current owner",
                    readiness.owner or "-")
                addDetail(self.details, "Override",
                    readiness.suspendable
                        and ("suspendable:"
                            .. tostring(readiness.overrideOwnerKind or "idle"))
                        or "none")
                addDetail(self.details, "Readiness reason",
                    readiness.reasonDetail or readiness.reason or "ready",
                    readiness.ready ~= true)
            end
        end
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
    if not self.model then return false end
    local accepted
    local reason
    if id == "add_actor" then
        accepted, reason = self.model.AddActorContainer()
    elseif id == "remove_actor" then
        accepted, reason = self.model.RemoveActor(
            self.model.GetSelectedActorID()
        )
    else
        return false
    end
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
    local compact = height < Layout.Pixels(430, scale)
    local actorRowHeight = Layout.Pixels(compact and 36 or 48, scale)
    local liveRowHeight = Layout.Pixels(compact and 36 or 44, scale)
    resizeRows(self.actorList, actorRowHeight)
    resizeRows(self.liveList, liveRowHeight)
    resizeRows(self.details, Layout.Pixels(25, scale))
    if self.actorList then self.actorList.uiScale = scale end
    if self.liveList then self.liveList.uiScale = scale end
    local columnsWidth = math.max(1, width - pad * 2 - gap * 2)
    local stacked = width < Layout.Pixels(720, scale)
        or columnsWidth < Layout.Pixels(430, scale)
    if stacked then
        local heading = Layout.Pixels(20, scale)
        local rowBlock = math.max(Layout.Pixels(70, scale),
            math.floor(height * 0.22))
        local listWidth = math.max(1, width - pad * 2)
        local sceneHeight = math.max(Layout.Pixels(36, scale),
            math.floor(rowBlock * 0.48))
        local liveTop = pad + heading + sceneHeight + gap + heading
        local liveHeight = math.max(Layout.Pixels(36, scale),
            math.floor(rowBlock * 0.48))
        local gridTop = liveTop + liveHeight + gap
        local detailsHeight = math.max(Layout.Pixels(1, scale),
            height - gridTop - Layout.Pixels(96, scale))
        local gridHeight = math.max(Layout.Pixels(100, scale),
            math.floor(detailsHeight * 0.62))
        local detailsTop = gridTop + gridHeight + gap
        local removeHeight = Layout.Pixels(26, scale)
        Layout.SetBounds(self.actorList, pad, pad + heading,
            listWidth, sceneHeight)
        Layout.SetBounds(self.liveList, pad, liveTop,
            listWidth, liveHeight)
        Layout.SetBounds(self.grid, pad, gridTop, listWidth, gridHeight)
        Layout.SetBounds(self.details, pad, detailsTop,
            listWidth, math.max(1, height - detailsTop - removeHeight
                - pad - gap))
        Layout.SetBounds(self.addButton, pad, height - pad - removeHeight,
            math.max(1, math.floor((listWidth - gap) / 2)), removeHeight)
        Layout.SetBounds(self.removeButton,
            pad + math.floor((listWidth - gap) / 2) + gap,
            height - pad - removeHeight,
            math.max(1, math.ceil((listWidth - gap) / 2)), removeHeight)
        self.stackedLayout = true
        return
    end
    self.stackedLayout = false
    local leftWidth = math.floor(columnsWidth * 0.24)
    local rightWidth = math.floor(columnsWidth * 0.28)
    local centerWidth = columnsWidth - leftWidth - rightWidth
    if centerWidth < Layout.Pixels(220, scale) then
        leftWidth = math.floor(columnsWidth * 0.20)
        rightWidth = math.floor(columnsWidth * 0.25)
        centerWidth = columnsWidth - leftWidth - rightWidth
    end
    leftWidth = math.max(Layout.Pixels(112, scale), leftWidth)
    rightWidth = math.max(Layout.Pixels(132, scale), rightWidth)
    if leftWidth + rightWidth >= columnsWidth then
        leftWidth = math.max(1, math.floor(columnsWidth * 0.25))
        rightWidth = math.max(1, math.floor(columnsWidth * 0.28))
    end
    centerWidth = math.max(1, columnsWidth - leftWidth - rightWidth)
    centerWidth = math.max(1, centerWidth)

    local leftX = pad
    local leftTop = Layout.Pixels(22, scale)
    local leftBottom = height - pad
    local liveHeadingHeight = Layout.Pixels(20, scale)
    local availableLeft = math.max(1,
        leftBottom - leftTop - gap - liveHeadingHeight)
    local sceneHeight = math.floor(availableLeft * (compact and 0.42 or 0.46))
    local minSceneHeight = math.min(availableLeft,
        math.max(Layout.Pixels(36, scale), actorRowHeight))
    local minLiveHeight = math.min(availableLeft,
        math.max(Layout.Pixels(32, scale), liveRowHeight))
    if availableLeft >= minSceneHeight + minLiveHeight then
        sceneHeight = math.max(minSceneHeight,
            math.min(availableLeft - minLiveHeight, sceneHeight))
    else
        sceneHeight = math.max(1, availableLeft - minLiveHeight)
    end
    local liveTop = leftTop + sceneHeight + gap + Layout.Pixels(20, scale)
    local liveHeight = math.max(1, leftBottom - liveTop)
    Layout.SetBounds(self.actorList, leftX, leftTop, leftWidth, sceneHeight)
    Layout.SetBounds(self.liveList, leftX, liveTop, leftWidth, liveHeight)

    local gridX = leftX + leftWidth + gap
    Layout.SetBounds(self.grid, gridX, pad,
        centerWidth, height - pad * 2)

    local detailsX = gridX + centerWidth + gap
    local removeHeight = Layout.Pixels(26, scale)
    local removeY = math.max(pad, height - pad - removeHeight)
    local detailsHeight = math.max(Layout.Pixels(1, scale),
        removeY - pad - gap)
    Layout.SetBounds(self.details, detailsX, pad,
        math.max(1, width - detailsX - pad), detailsHeight)
    Layout.SetBounds(self.addButton, detailsX,
        removeY - Layout.Pixels(30, scale),
        math.max(1, width - detailsX - pad), Layout.Pixels(26, scale))
    Layout.SetBounds(self.removeButton, detailsX,
        removeY,
        math.max(1, width - detailsX - pad), Layout.Pixels(26, scale))
end

return ISPNCPuppetOperaLayoutTab
