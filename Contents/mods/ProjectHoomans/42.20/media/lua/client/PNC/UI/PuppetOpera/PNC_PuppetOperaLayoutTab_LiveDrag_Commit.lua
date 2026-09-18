-- Authoritative live-actor drop admission and drag cleanup.

PNC = PNC or {}

local Internal = PNC.PuppetOperaLayoutTabInternal

local function finishLiveDrag(self, list, x, y)
    if not self.liveDragPending then return false end
    local actorID = self.liveDragActorID
    local dragged = self.liveDragging == true
    local accepted = false
    local reason
    if dragged then
        local hasPointer = self:setLivePointerFromEvent(list, x, y)
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
                    if type(self.model.GetSelectedActorID) == "function" then
                        accepted, reason = self.model.AddLiveActorToScene(
                            actorID, right, forward, 0,
                            self.model.GetSelectedActorID()
                        )
                    else
                        reason = "live_actor_model_unavailable"
                    end
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
    self.liveDragPending = nil
    self.liveDragActorID = nil
    self.liveDragX = nil
    self.liveDragY = nil
    self.liveDragging = nil
    self.livePointerX = nil
    self.livePointerY = nil
    if self.grid then self.grid.dropPreview = nil end
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
        if accepted
            and type(self.ownerWindow.requestPlacementPreview) == "function"
        then
            self.ownerWindow:requestPlacementPreview()
        end
    end
    return true
end

Internal.finishLiveDrag = finishLiveDrag

return ISPNCPuppetOperaLayoutTab
