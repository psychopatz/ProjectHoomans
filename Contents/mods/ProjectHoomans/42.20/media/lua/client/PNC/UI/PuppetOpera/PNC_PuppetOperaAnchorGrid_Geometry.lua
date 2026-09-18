-- Pure coordinate mapping for the Puppet Opera anchor grid.

local Class = ISPNCPuppetOperaAnchorGrid

function Class:geometry()
    local width = self:getWidth()
    local height = self:getHeight()
    local cell = math.floor(math.min((width - 24) / 17, (height - 44) / 17))
    cell = math.max(8, math.min(42, cell))
    return cell, math.floor(width / 2), math.floor(height / 2) + 10
end

function Class:graphBounds()
    local cell, centerX, centerY = self:geometry()
    -- Offsets -8..8 are tile centers, so the visible graph has 17 tiles in
    -- each direction and a half-cell border around the outer centers.  The
    -- old 16-cell bounds made the +8 row fall outside the drop target.
    local left = centerX - 8.5 * cell
    local top = centerY - 8.5 * cell
    local size = 17 * cell
    return left, top, left + size, top + size, cell
end

function Class:containsGraphPoint(x, y)
    local left, top, right, bottom = self:graphBounds()
    x = tonumber(x)
    y = tonumber(y)
    return x ~= nil and y ~= nil
        and x >= left and y >= top
        and x < right and y < bottom
end

function Class:cellAt(x, y)
    local cell, centerX, centerY = self:geometry()
    local right = math.floor(((x - centerX) / cell) + 0.5)
    local forward = math.floor(((centerY - y) / cell) + 0.5)
    right = math.max(-8, math.min(8, right))
    forward = math.max(-8, math.min(8, forward))
    return right, forward
end

function Class:cellPoint(right, forward)
    local cell, centerX, centerY = self:geometry()
    return centerX + right * cell, centerY - forward * cell
end

return Class
