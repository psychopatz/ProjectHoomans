-- Facing guides and actor markers for the anchor grid.

local Internal = PNC.PuppetOperaAnchorGridInternal
local Layout = PsychopatzCore.UI.Layout

local function drawFacingGuides(grid, rows, byID)
    -- Draw guides before markers so the actor identity remains legible.
    for _, row in ipairs(rows) do
        local target = byID[tostring(row.faceTarget or "")]
        if target then
            local fromX, fromY = grid:cellPoint(row.right, row.forward)
            local toX, toY = grid:cellPoint(target.right, target.forward)
            local dx = toX - fromX
            local dy = toY - fromY
            local distance = math.sqrt(dx * dx + dy * dy)
            local steps = math.max(1, math.floor(distance / 4))
            for step = 1, steps - 1 do
                local ratio = step / steps
                grid:drawRect(
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
            grid:drawRect(
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
end

local function drawActorMarkers(grid, rows, cell)
    for _, row in ipairs(rows) do
        local x, y = grid:cellPoint(row.right, row.forward)
        local selected = row.selected == true
        local assigned = row.bindingID ~= nil
        local color = selected
            and { r = 0.96, g = 0.78, b = 0.20 }
            or assigned
            and { r = 0.30, g = 0.84, b = 0.52 }
            or { r = 0.52, g = 0.56, b = 0.60 }
        local radius = selected and 11 or 9
        grid:drawRect(
            x - radius,
            y - radius,
            radius * 2,
            radius * 2,
            selected and 0.95 or 0.82,
            color.r,
            color.g,
            color.b
        )
        grid:drawRectBorder(
            x - radius,
            y - radius,
            radius * 2,
            radius * 2,
            0.95,
            0.94,
            0.96,
            1
        )
        grid:drawTextCentre(
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
        grid:drawTextCentre(
            tostring(row.kind == "unbound" and "?"
                or row.right) .. "," .. tostring(row.forward),
            x,
            y - 5,
            0.08,
            0.10,
            0.12,
            1,
            UIFont.Small
        )
    end
end

local function drawActors(grid, rows, byID, cell)
    drawFacingGuides(grid, rows, byID)
    drawActorMarkers(grid, rows, cell)
end

Internal.drawActors = drawActors

return ISPNCPuppetOperaAnchorGrid
