-- Pointer normalization and drop-preview projection for layout drag/drop.

PNC = PNC or {}

local Internal = PNC.PuppetOperaLayoutTabInternal

local function setLivePointerFromEvent(self, list, x, y)
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
    -- the graph.
    if type(getMouseX) == "function" and type(getMouseY) == "function" then
        addCandidate(getMouseX(), getMouseY())
    end
    if type(x) == "number" and type(y) == "number" then
        if type(list.getAbsoluteX) == "function"
            and type(list.getAbsoluteY) == "function"
        then
            addCandidate(list:getAbsoluteX() + x, list:getAbsoluteY() + y)
        end
        addCandidate(x, y)
    end
    for _, candidate in ipairs(candidates) do
        if self.grid and type(self.grid.containsGraphPoint) == "function"
            and type(self.grid.getAbsoluteX) == "function"
            and type(self.grid.getAbsoluteY) == "function"
        then
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

local function updateLiveDropPreview(self)
    if not self.livePointerX or not self.livePointerY then return false end
    if not self.grid or type(self.grid.containsGraphPoint) ~= "function"
        or type(self.grid.getAbsoluteX) ~= "function"
        or type(self.grid.getAbsoluteY) ~= "function"
        or type(self.grid.cellAt) ~= "function"
    then
        return false
    end
    local x = self.livePointerX - self.grid:getAbsoluteX()
    local y = self.livePointerY - self.grid:getAbsoluteY()
    local inside = self.grid:containsGraphPoint(x, y)
    local right, forward = self.grid:cellAt(x, y)
    local occupied = false
    if self.model and type(self.model.GetActorAtOffset) == "function" then
        occupied = inside
            and self.model.GetActorAtOffset(right, forward) ~= nil
            or false
    end
    self.grid.dropPreview = {
        right = right,
        forward = forward,
        inside = inside,
        occupied = occupied,
    }
    return inside
end

Internal.setLivePointerFromEvent = setLivePointerFromEvent
Internal.updateLiveDropPreview = updateLiveDropPreview

return ISPNCPuppetOperaLayoutTab
