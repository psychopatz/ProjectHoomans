-- Pointer selection, live placement, and anchor dragging for the grid.

local Class = ISPNCPuppetOperaAnchorGrid

local function hasMethod(target, name)
    local targetType = type(target)
    return (targetType == "table" or targetType == "userdata")
        and type(target[name]) == "function"
end

function Class:onMouseDown(x, y)
    if not hasMethod(self.model, "GetActorAtOffset") then return false end
    if not self:containsGraphPoint(x, y) then return false end
    local right, forward = self:cellAt(x, y)
    local actor = self.model.GetActorAtOffset(right, forward)
    if not actor then
        local pending = hasMethod(self.model, "GetPendingLiveActorID")
            and self.model.GetPendingLiveActorID() or nil
        if pending then
            local accepted, reason
            if hasMethod(self.model, "AddLiveActorToScene") then
                accepted, reason = self.model.AddLiveActorToScene(
                    pending,
                    right,
                    forward,
                    0
                )
            else
                reason = "live_actor_model_unavailable"
            end
            if self.ownerWindow then
                if hasMethod(self.ownerWindow, "setEditorStatus") then
                    self.ownerWindow:setEditorStatus(
                        accepted and "live_actor_added_to_scene" or reason,
                        not accepted
                    )
                end
                if hasMethod(self.ownerWindow, "refreshViews") then
                    self.ownerWindow:refreshViews()
                end
                if accepted
                    and hasMethod(self.ownerWindow, "requestPlacementPreview")
                then
                    self.ownerWindow:requestPlacementPreview()
                end
            end
            return accepted == true
        end
        return false
    end
    local actorType = type(actor)
    if actorType ~= "table" and actorType ~= "userdata" then return false end
    if actor.id == nil then return false end
    if not hasMethod(self.model, "SelectActor") then return false end
    self.model.SelectActor(actor.id)
    if self.ownerWindow and hasMethod(self.ownerWindow, "refreshViews") then
        self.ownerWindow:refreshViews()
    end
    self.dragActorID = actor.id
    self.dragX = x
    self.dragY = y
    self.dragChanged = false
    self:setCapture(true)
    return true
end

function Class:updateDrag(x, y)
    if not self.dragActorID then return false end
    if not self:containsGraphPoint(x, y) then return true end
    if not hasMethod(self.model, "GetGridActors")
        or not hasMethod(self.model, "SetActorAnchorOffset")
    then
        return true
    end
    local right, forward = self:cellAt(x, y)
    local rows = self.model.GetGridActors() or {}
    if type(rows) ~= "table" then return true end
    local z = 0
    for _, row in ipairs(rows) do
        if row.id == self.dragActorID then
            z = tonumber(row.z) or 0
            break
        end
    end
    local accepted = self.model.SetActorAnchorOffset(
        self.dragActorID,
        right,
        forward,
        z
    )
    if accepted then self.dragChanged = true end
    return true
end

function Class:onMouseMove(dx, dy)
    if not self.dragActorID then return false end
    self.dragX = (self.dragX or self:getMouseX()) + (tonumber(dx) or 0)
    self.dragY = (self.dragY or self:getMouseY()) + (tonumber(dy) or 0)
    return self:updateDrag(self.dragX, self.dragY)
end

function Class:onMouseMoveOutside(dx, dy)
    return self:onMouseMove(dx, dy)
end

function Class:onMouseUp()
    local changed = self.dragChanged == true
    self.dragActorID = nil
    self.dragX = nil
    self.dragY = nil
    self.dragChanged = nil
    self:setCapture(false)
    if changed and self.ownerWindow then
        if hasMethod(self.ownerWindow, "refreshViews") then
            self.ownerWindow:refreshViews()
        end
        if hasMethod(self.ownerWindow, "requestPlacementPreview") then
            self.ownerWindow:requestPlacementPreview()
        end
    end
    return true
end

function Class:onMouseUpOutside(x, y)
    return self:onMouseUp(x, y)
end

return Class
