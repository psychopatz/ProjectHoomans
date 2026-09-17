-- Relative tile-anchor editor used by the Puppet Opera scene builder.

require "ISUI/ISPanel"

PNC = PNC or {}

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
    local cell = math.floor(math.min((width - 34) / 17, (height - 48) / 17))
    cell = math.max(16, math.min(42, cell))
    return cell, math.floor(width / 2), math.floor(height / 2) + 10
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
    local cell, centerX, centerY = self:geometry()
    local left = centerX - 8 * cell
    local top = centerY - 8 * cell
    local size = 16 * cell

    self:drawRect(left, top, size, size, 0.85, 0.07, 0.09, 0.11)
    for offset = -8, 8 do
        local x = centerX + offset * cell
        local y = centerY - offset * cell
        local alpha = offset == 0 and 0.65 or 0.22
        self:drawRect(x, top, 1, size, alpha, 0.42, 0.52, 0.58)
        self:drawRect(left, y, size, 1, alpha, 0.42, 0.52, 0.58)
    end
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

    for _, row in ipairs(self.model and self.model.GetGridActors
        and self.model.GetGridActors() or {}) do
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
            tostring(row.id),
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
    self:drawText(
        tr("UI_PNC_PuppetOpera_GridHint",
            "Drag an actor marker to a tile. Coordinates are relative to the player."),
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
    local right, forward = self:cellAt(x, y)
    local actor = self.model.GetActorAtOffset(right, forward)
    if not actor then return false end
    self.model.SelectActor(actor.id)
    self.dragActorID = actor.id
    self.dragX = x
    self.dragY = y
    self:setCapture(true)
    return true
end

function ISPNCPuppetOperaAnchorGrid:updateDrag(x, y)
    if not self.dragActorID then return false end
    local right, forward = self:cellAt(x, y)
    local rows = self.model.GetGridActors()
    local z = 0
    for _, row in ipairs(rows) do
        if row.id == self.dragActorID then
            z = tonumber(row.z) or 0
            break
        end
    end
    self.model.SetActorAnchorOffset(
        self.dragActorID,
        right,
        forward,
        z
    )
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
    self.dragActorID = nil
    self.dragX = nil
    self.dragY = nil
    self:setCapture(false)
    return true
end

function ISPNCPuppetOperaAnchorGrid:onMouseUpOutside(x, y)
    return self:onMouseUp(x, y)
end

return ISPNCPuppetOperaAnchorGrid
