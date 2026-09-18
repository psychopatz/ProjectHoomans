-- Placement, pending-actor, and help overlays for the anchor grid.

local Internal = PNC.PuppetOperaAnchorGridInternal
local tr = Internal.tr

local function drawDropPreview(grid, cell)
    local drop = grid.dropPreview
    if not drop or not drop.inside then return end
    local dropX, dropY = grid:cellPoint(drop.right, drop.forward)
    local occupied = drop.occupied == true
    local dropColor = occupied
        and { r = 0.96, g = 0.32, b = 0.30 }
        or { r = 0.38, g = 0.96, b = 0.62 }
    grid:drawRect(
        dropX - cell * 0.45,
        dropY - cell * 0.45,
        cell * 0.90,
        cell * 0.90,
        0.28,
        dropColor.r,
        dropColor.g,
        dropColor.b
    )
    grid:drawRectBorder(
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

local function drawOverlays(grid, left, top, cell)
    drawDropPreview(grid, cell)
    local pending = grid.model
        and type(grid.model.GetPendingLiveActorID) == "function"
        and grid.model.GetPendingLiveActorID() or nil
    if pending then
        grid:drawText(
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
    grid:drawText(
        tr("UI_PNC_PuppetOpera_GridHint",
            "Gray = empty slot, green = assigned actor, yellow = selected."),
        10,
        grid:getHeight() - 22,
        0.62,
        0.72,
        0.78,
        1,
        UIFont.Small
    )
end

Internal.drawOverlays = drawOverlays

return ISPNCPuppetOperaAnchorGrid
