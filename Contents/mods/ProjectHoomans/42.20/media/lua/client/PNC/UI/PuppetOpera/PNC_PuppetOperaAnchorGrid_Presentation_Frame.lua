-- Static frame, axes, and translated labels for the anchor grid.

local Internal = PNC.PuppetOperaAnchorGridInternal
local tr = Internal.tr

local function drawGridFrame(grid, left, top, centerX, centerY, cell, size)
    grid:drawRect(left, top, size, size, 0.85, 0.07, 0.09, 0.11)
    for boundary = 0, 17 do
        local offset = boundary - 8.5
        local x = centerX + offset * cell
        local y = centerY - offset * cell
        local alpha = 0.22
        grid:drawRect(x, top, 1, size, alpha, 0.42, 0.52, 0.58)
        grid:drawRect(left, y, size, 1, alpha, 0.42, 0.52, 0.58)
    end
    grid:drawRect(centerX, top, 1, size, 0.65, 0.42, 0.52, 0.58)
    grid:drawRect(left, centerY, size, 1, 0.65, 0.42, 0.52, 0.58)
    grid:drawRectBorder(left, top, size, size, 0.65, 0.30, 0.38, 0.42)
    grid:drawTextCentre(
        tr("UI_PNC_PuppetOpera_PlayerOrigin", "Player origin"),
        centerX,
        top - 22,
        0.72,
        0.82,
        0.88,
        1,
        UIFont.Small
    )
    grid:drawTextCentre(
        tr("UI_PNC_PuppetOpera_Forward", "forward"),
        centerX,
        top + 4,
        0.60,
        0.76,
        0.84,
        1,
        UIFont.Small
    )
    grid:drawText(
        tr("UI_PNC_PuppetOpera_Right", "right"),
        left + size + 6,
        centerY - 8,
        0.60,
        0.76,
        0.84,
        1,
        UIFont.Small
    )
end

Internal.drawGridFrame = drawGridFrame

return ISPNCPuppetOperaAnchorGrid
