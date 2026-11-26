-- Authoritative live-actor drop admission and drag cleanup.

PNC = PNC or {}

local Internal = PNC.ChoreographyLayoutTabInternal

local function tryBindToSlot(model, slotID, actorID)
    if not model or type(model.BindLiveActor) ~= "function" then
        return false, "live_actor_model_unavailable"
    end
    local ok, reason = model.BindLiveActor(slotID, actorID)
    if ok then return true, slotID end
    return false, reason
end

local function finishLiveDrag(self, list, x, y)
    if not self.liveDragPending then return false end
    local actorID = self.liveDragActorID
    local dragged = self.liveDragging == true
    local accepted = false
    local reason
    if dragged then
        local hasPointer = self:setLivePointerFromEvent(list, x, y)
        local droppedOnActorList = hasPointer
            and Internal.pointInsideWidget
            and Internal.pointInsideWidget(
                self.actorList,
                self.livePointerX,
                self.livePointerY
            )
        if droppedOnActorList and self.model then
            local slot = Internal.actorSlotAtScreenPoint
                and Internal.actorSlotAtScreenPoint(
                    self,
                    self.livePointerX,
                    self.livePointerY
                )
            if slot and slot.id then
                if slot.liveID and tostring(slot.liveID) ~= tostring(actorID)
                    and type(self.model.UnbindLiveActor) == "function"
                then
                    self.model.UnbindLiveActor(slot.id)
                end
                accepted, reason = tryBindToSlot(self.model, slot.id, actorID)
            else
                -- Dropped onto empty space in Scene actors: bind to first
                -- eligible unbound slot.
                local rows = type(self.model.GetActorRows) == "function"
                    and self.model.GetActorRows(nil) or {}
                for _, row in ipairs(rows) do
                    if not row.liveID then
                        accepted, reason = tryBindToSlot(
                            self.model,
                            row.id,
                            actorID
                        )
                        if accepted then break end
                    end
                end
                if not accepted and not reason then
                    reason = "no_unbound_actor_slot"
                end
            end
        else
            local gridReady = self.grid
                and type(self.grid.containsGraphPoint) == "function"
                and type(self.grid.getAbsoluteX) == "function"
                and type(self.grid.getAbsoluteY) == "function"
                and type(self.grid.cellAt) == "function"
            local modelReady = self.model
                and type(self.model.GetActorAtOffset) == "function"
                and type(self.model.AddLiveActorToScene) == "function"
            if hasPointer and gridReady and modelReady then
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
                            actorID, right, forward, 0
                        )
                    end
                else
                    reason = "live_actor_drop_outside_grid"
                end
            elseif hasPointer and gridReady then
                reason = "live_actor_model_unavailable"
            else
                reason = "live_actor_drop_outside_grid"
            end
        end
    end
    self.liveDragPending = nil
    self.liveDragActorID = nil
    self.liveDragX = nil
    self.liveDragY = nil
    self.liveDragging = nil
    self.livePointerX = nil
    self.livePointerY = nil
    if self.grid then self.grid.dropPreview = nil end
    if self.actorList then self.actorList.dropHoverIndex = nil end
    if self.liveList and self.liveList.setCapture then
        self.liveList:setCapture(false)
    end
    if dragged and self.ownerWindow then
        if type(self.ownerWindow.setEditorStatus) == "function" then
            self.ownerWindow:setEditorStatus(
                accepted and "live_actor_added_to_scene" or reason,
                not accepted
            )
        end
        if type(self.ownerWindow.refreshViews) == "function" then
            self.ownerWindow:refreshViews()
        end
        -- Do NOT auto-start placement preview on drop; participants must stay
        -- idle until the user explicitly clicks Play.
    end
    return true
end

Internal.finishLiveDrag = finishLiveDrag

return ISPNCChoreographyLayoutTab
