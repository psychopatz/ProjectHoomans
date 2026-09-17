-- Relative tile-anchor editor used by the Puppet Opera scene builder.

require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}

local Layout = PsychopatzCore.UI.Layout

local function tr(key, fallback)
    local translation = PNC.Translation
    local value = translation and translation.GetKey
        and translation.GetKey(key, fallback) or fallback
    if not value or value == "" or value == key then return fallback end
    return value
end

ISPNCPuppetOperaAnchorGrid = ISPanel:derive("ISPNCPuppetOperaAnchorGrid")

function ISPNCPuppetOperaAnchorGrid:initialise()
    ISPanel.initialise(self)
    self.background = true
    self.backgroundColor = {
        r = 0.055,
        g = 0.070,
        b = 0.080,
        a = 1,
    }
    self.borderColor = {
        r = 0.22,
        g = 0.30,
        b = 0.34,
        a = 1,
    }
end

function ISPNCPuppetOperaAnchorGrid:setModel(model)
    self.model = model
end

function ISPNCPuppetOperaAnchorGrid:geometry()
    local width = self:getWidth()
    local height = self:getHeight()
    local cell = math.floor(math.min((width - 24) / 17, (height - 44) / 17))
    cell = math.max(8, math.min(42, cell))
    return cell, math.floor(width / 2), math.floor(height / 2) + 10
end

function ISPNCPuppetOperaAnchorGrid:graphBounds()
    local cell, centerX, centerY = self:geometry()
    -- Offsets -8..8 are tile centers, so the visible graph has 17 tiles in
    -- each direction and a half-cell border around the outer centers.  The
    -- old 16-cell bounds made the +8 row fall outside the drop target.
    local left = centerX - 8.5 * cell
    local top = centerY - 8.5 * cell
    local size = 17 * cell
    return left, top, left + size, top + size, cell
end

function ISPNCPuppetOperaAnchorGrid:containsGraphPoint(x, y)
    local left, top, right, bottom = self:graphBounds()
    x = tonumber(x)
    y = tonumber(y)
    return x ~= nil and y ~= nil
        and x >= left and y >= top
        and x < right and y < bottom
end

function ISPNCPuppetOperaAnchorGrid:cellAt(x, y)
    local cell, centerX, centerY = self:geometry()
    local right = math.floor(((x - centerX) / cell) + 0.5)
    local forward = math.floor(((centerY - y) / cell) + 0.5)
    right = math.max(-8, math.min(8, right))
    forward = math.max(-8, math.min(8, forward))
    return right, forward
end

function ISPNCPuppetOperaAnchorGrid:cellPoint(right, forward)
    local cell, centerX, centerY = self:geometry()
    return centerX + right * cell, centerY - forward * cell
end

function ISPNCPuppetOperaAnchorGrid:render()
    ISPanel.render(self)
    local left, top, _, _, cell = self:graphBounds()
    local _, centerX, centerY = self:geometry()
    local size = 17 * cell

    self:drawRect(left, top, size, size, 0.85, 0.07, 0.09, 0.11)
    for boundary = 0, 17 do
        local offset = boundary - 8.5
        local x = centerX + offset * cell
        local y = centerY - offset * cell
        local alpha = 0.22
        self:drawRect(x, top, 1, size, alpha, 0.42, 0.52, 0.58)
        self:drawRect(left, y, size, 1, alpha, 0.42, 0.52, 0.58)
    end
    self:drawRect(centerX, top, 1, size, 0.65, 0.42, 0.52, 0.58)
    self:drawRect(left, centerY, size, 1, 0.65, 0.42, 0.52, 0.58)
    self:drawRectBorder(left, top, size, size, 0.65, 0.30, 0.38, 0.42)
    self:drawTextCentre(
        tr("UI_PNC_PuppetOpera_PlayerOrigin", "Player origin"),
        centerX,
        top - 22,
        0.72,
        0.82,
        0.88,
        1,
        UIFont.Small
    )
    self:drawTextCentre(
        tr("UI_PNC_PuppetOpera_Forward", "forward"),
        centerX,
        top + 4,
        0.60,
        0.76,
        0.84,
        1,
        UIFont.Small
    )
    self:drawText(
        tr("UI_PNC_PuppetOpera_Right", "right"),
        left + size + 6,
        centerY - 8,
        0.60,
        0.76,
        0.84,
        1,
        UIFont.Small
    )

    local rows = self.model and self.model.GetGridActors
        and self.model.GetGridActors() or {}
    local byID = {}
    for _, row in ipairs(rows) do byID[tostring(row.id)] = row end

    -- Draw facing guides before the markers.  A tiny stepped line keeps this
    -- compatible with ISPanel's stable drawRect surface while still making
    -- the in-game facing contract obvious in the authoring view.
    for _, row in ipairs(rows) do
        local target = byID[tostring(row.faceTarget or "")]
        if target then
            local fromX, fromY = self:cellPoint(row.right, row.forward)
            local toX, toY = self:cellPoint(target.right, target.forward)
            local dx = toX - fromX
            local dy = toY - fromY
            local distance = math.sqrt(dx * dx + dy * dy)
            local steps = math.max(1, math.floor(distance / 4))
            for step = 1, steps - 1 do
                local ratio = step / steps
                self:drawRect(
                    fromX + dx * ratio - 1,
                    fromY + dy * ratio - 1,
                    2,
                    2,
                    0.68,
                    0.84,
                    0.72,
                    0.34
                )
            end
            local directionX = dx / math.max(1, distance)
            local directionY = dy / math.max(1, distance)
            local arrowX = toX - directionX * 12
            local arrowY = toY - directionY * 12
            self:drawRect(
                arrowX - 2,
                arrowY - 2,
                4,
                4,
                0.90,
                0.84,
                0.72,
                0.34
            )
        end
    end

    for _, row in ipairs(rows) do
        local x, y = self:cellPoint(row.right, row.forward)
        local selected = row.selected == true
        local color = row.kind == "nearby_live_npc"
            and { r = 0.92, g = 0.58, b = 0.28 }
            or { r = 0.32, g = 0.82, b = 0.96 }
        local radius = selected and 11 or 9
        self:drawRect(
            x - radius,
            y - radius,
            radius * 2,
            radius * 2,
            selected and 0.95 or 0.82,
            color.r,
            color.g,
            color.b
        )
        self:drawRectBorder(
            x - radius,
            y - radius,
            radius * 2,
            radius * 2,
            0.95,
            0.94,
            0.96,
            1
        )
        self:drawTextCentre(
            Layout.Ellipsize(tostring(row.label or row.id), UIFont.Small,
                math.max(32, cell * 2)),
            x,
            y + radius + 3,
            0.92,
            0.94,
            0.96,
            1,
            UIFont.Small
        )
        self:drawTextCentre(
            tostring(row.right) .. "," .. tostring(row.forward),
            x,
            y - 5,
            0.08,
            0.10,
            0.12,
            1,
            UIFont.Small
        )
    end

    local drop = self.dropPreview
    if drop and drop.inside then
        local dropX, dropY = self:cellPoint(drop.right, drop.forward)
        local occupied = drop.occupied == true
        local dropColor = occupied
            and { r = 0.96, g = 0.32, b = 0.30 }
            or { r = 0.38, g = 0.96, b = 0.62 }
        self:drawRect(
            dropX - cell * 0.45,
            dropY - cell * 0.45,
            cell * 0.90,
            cell * 0.90,
            0.28,
            dropColor.r,
            dropColor.g,
            dropColor.b
        )
        self:drawRectBorder(
            dropX - cell * 0.45,
            dropY - cell * 0.45,
            cell * 0.90,
            cell * 0.90,
            0.90,
            dropColor.r,
            dropColor.g,
            dropColor.b
        )
    end
    local pending = self.model and self.model.GetPendingLiveActorID
        and self.model.GetPendingLiveActorID() or nil
    if pending then
        self:drawText(
            tr("UI_PNC_PuppetOpera_DropActor", "DROP LIVE ACTOR")
                .. ": " .. tostring(pending),
            10,
            math.max(2, top - 20),
            0.98,
            0.72,
            0.30,
            1,
            UIFont.Small
        )
    end
    self:drawText(
        tr("UI_PNC_PuppetOpera_GridHint",
            "Drag live actors or markers onto an empty tile."),
        10,
        self:getHeight() - 22,
        0.62,
        0.72,
        0.78,
        1,
        UIFont.Small
    )
end

function ISPNCPuppetOperaAnchorGrid:onMouseDown(x, y)
    if not self.model then return false end
    if not self:containsGraphPoint(x, y) then return false end
    local right, forward = self:cellAt(x, y)
    local actor = self.model.GetActorAtOffset(right, forward)
    if not actor then
        local pending = self.model.GetPendingLiveActorID
            and self.model.GetPendingLiveActorID() or nil
        if pending then
            local accepted, reason = self.model.AddLiveActorToScene(
                pending,
                right,
                forward,
                0
            )
            if self.ownerWindow then
                self.ownerWindow:setEditorStatus(
                    accepted and "live_actor_added_to_scene" or reason,
                    not accepted
                )
                self.ownerWindow:refreshViews()
                if accepted and self.ownerWindow.requestPlacementPreview then
                    self.ownerWindow:requestPlacementPreview()
                end
            end
            return accepted == true
        end
        return false
    end
    self.model.SelectActor(actor.id)
    self.dragActorID = actor.id
    self.dragX = x
    self.dragY = y
    self.dragChanged = false
    self:setCapture(true)
    return true
end

function ISPNCPuppetOperaAnchorGrid:updateDrag(x, y)
    if not self.dragActorID then return false end
    if not self:containsGraphPoint(x, y) then return true end
    local right, forward = self:cellAt(x, y)
    local rows = self.model.GetGridActors()
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

function ISPNCPuppetOperaAnchorGrid:onMouseMove(dx, dy)
    if not self.dragActorID then return false end
    self.dragX = (self.dragX or self:getMouseX()) + (tonumber(dx) or 0)
    self.dragY = (self.dragY or self:getMouseY()) + (tonumber(dy) or 0)
    return self:updateDrag(self.dragX, self.dragY)
end

function ISPNCPuppetOperaAnchorGrid:onMouseMoveOutside(dx, dy)
    return self:onMouseMove(dx, dy)
end

function ISPNCPuppetOperaAnchorGrid:onMouseUp()
    local changed = self.dragChanged == true
    self.dragActorID = nil
    self.dragX = nil
    self.dragY = nil
    self.dragChanged = nil
    self:setCapture(false)
    if changed and self.ownerWindow then
        self.ownerWindow:refreshViews()
        if self.ownerWindow.requestPlacementPreview then
            self.ownerWindow:requestPlacementPreview()
        end
    end
    return true
end

function ISPNCPuppetOperaAnchorGrid:onMouseUpOutside(x, y)
    return self:onMouseUp(x, y)
end

return ISPNCPuppetOperaAnchorGrid
