-- Lifecycle, widget construction, and actions for the Puppet Opera layout tab.

PNC = PNC or {}

local Internal = PNC.PuppetOperaLayoutTabInternal
local UI = Internal.UI
local tr = Internal.tr
local Class = ISPNCPuppetOperaLayoutTab

function Class:initialise()
    ISPanel.initialise(self)
    self:noBackground()
end

function Class:createChildren()
    ISPanel.createChildren(self)
    self.actorList = UI.CreateList(self, {
        itemHeight = 50,
        doDrawItem = Internal.drawActorRow,
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
        doDrawItem = Internal.drawLiveRow,
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

function Class:setContext(window)
    self.ownerWindow = window
    self.model = window and window.model or nil
    self.grid:setModel(self.model)
    self.grid.ownerWindow = window
    self:refresh()
end

function Class:onAction(button)
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

return Class
