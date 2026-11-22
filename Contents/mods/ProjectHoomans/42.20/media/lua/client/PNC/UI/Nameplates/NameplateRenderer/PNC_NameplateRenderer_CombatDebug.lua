local Renderer = PNC.NameplateRenderer
local Internal = Renderer.Internal
local Presentation = PNC.NameplatePresentation
local Fonts = Presentation.Fonts
local rounded = Internal.Rounded
local screenPoint = Internal.ScreenPoint
local drawWorldLine = Internal.DrawWorldLine
local drawWorldThickLine = Internal.DrawWorldThickLine or drawWorldLine
local drawWorldMarker = Internal.DrawWorldMarker
local drawWorldCircle = Internal.DrawWorldCircle

local DEBUG_COLOR = { r = 0.8, g = 0.9, b = 1.0, a = 1.0 }
local COMBAT_CONE_COLOR = { r = 0.25, g = 0.9, b = 1.0, a = 0.94 }
local COMBAT_CONE_ALERT_COLOR = { r = 1.0, g = 0.78, b = 0.14, a = 0.95 }
local COMBAT_CONE_ENGAGED_COLOR = { r = 1.0, g = 0.28, b = 0.18, a = 0.95 }
local COMBAT_TARGET_COLOR = { r = 1.0, g = 0.22, b = 0.16, a = 0.92 }
local COMBAT_SAFE_COLOR = { r = 0.2, g = 1.0, b = 0.42, a = 0.86 }
local COMBAT_AIM_COLOR = { r = 1.0, g = 0.82, b = 0.18, a = 0.86 }
local COMBAT_UNSAFE_COLOR = { r = 1.0, g = 0.18, b = 0.42, a = 0.94 }
local COMBAT_PRESSURE_COLOR = { r = 1.0, g = 0.56, b = 0.1, a = 0.38 }
local COMBAT_HORDE_COLOR = { r = 1.0, g = 0.12, b = 0.08, a = 0.3 }
local COMBAT_MELEE_COLOR = { r = 1.0, g = 0.42, b = 0.16, a = 0.58 }
local COMBAT_RANGE_COLOR = { r = 0.3, g = 0.58, b = 1.0, a = 0.36 }
local COMBAT_MOVE_COLOR = { r = 0.5, g = 1.0, b = 0.3, a = 0.88 }
local COMBAT_DEFENSE_COLOR = { r = 0.16, g = 1.0, b = 0.30, a = 0.78 }
local COMBAT_BLOCKER_COLOR = { r = 1.0, g = 0.15, b = 0.8, a = 0.95 }
local ZOMBIE_ATTACKER_COLOR = { r = 1.0, g = 0.28, b = 0.12, a = 0.96 }
local PERIPHERAL_CONE_COLOR = { r = 0.25, g = 0.9, b = 1.0, a = 0.78 }
local CLUE_MARKER_COLOR = { r = 1.0, g = 0.72, b = 0.16, a = 0.92 }
local WARNING_LINK_COLOR = { r = 1.0, g = 0.78, b = 0.14, a = 0.95 }
local SELECTED_CHEVRON_COLOR = { r = 1.0, g = 1.0, b = 1.0, a = 0.98 }
local COMBAT_MARKER_HALF_SIZE = 9
local COMBAT_DEBUG_CONE_SEGMENTS = 14
local COMBAT_DEBUG_CIRCLE_SEGMENTS = 24

local function normalizeDirection(x, y)
    local length = math.sqrt((x * x) + (y * y))
    if length <= 0.001 then return 0, 1 end
    return x / length, y / length
end

local function directionAngle(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
    if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
    if y > 0 then return math.pi * 0.5 end
    if y < 0 then return math.pi * -0.5 end
    return 0
end

local function resolveCombatFacing(zombie, target)
    local forward
    local x
    local y
    if zombie and zombie.getForwardDirection then
        forward = zombie:getForwardDirection()
        if forward then
            x = tonumber(forward:getX()) or 0
            y = tonumber(forward:getY()) or 0
            if math.abs(x) + math.abs(y) > 0.001 then
                return normalizeDirection(x, y)
            end
        end
    end
    if zombie and target then
        return normalizeDirection(
            (tonumber(target.x) or zombie:getX()) - zombie:getX(),
            (tonumber(target.y) or zombie:getY()) - zombie:getY()
        )
    end
    return 0, 1
end

local function resolveConePalette(debugState)
    if type(debugState.target) == "table"
        or type(debugState.action) == "table"
    then
        return COMBAT_CONE_ENGAGED_COLOR
    end
    local agStage = tostring(debugState.agitationStage or "calm")
    local secAlert = tostring(debugState.secondaryAlertLevel or "calm")
    if type(debugState.warningLink) == "table"
        or debugState.warnedBy ~= nil
        or (secAlert ~= "calm" and secAlert ~= "")
        or (agStage ~= "calm" and agStage ~= "")
    then
        return COMBAT_CONE_ALERT_COLOR
    end
    return COMBAT_CONE_COLOR
end

local function drawConeBand(manager, originX, originY, z, baseAngle, halfAngle, radius, segments, color, thickness, shadow)
    local previousX
    local previousY
    local i
    for i = 0, segments do
        local angle = baseAngle - halfAngle
            + ((halfAngle * 2) * (i / segments))
        local x = originX + math.cos(angle) * radius
        local y = originY + math.sin(angle) * radius
        if previousX ~= nil then
            drawWorldThickLine(
                manager, previousX, previousY, z,
                x, y, z, color, thickness, shadow
            )
        end
        previousX = x
        previousY = y
    end
end

local function drawCombatCone(manager, zombie, debugState, isSelected)
    local target = debugState.target
    local originX = zombie:getX()
    local originY = zombie:getY()
    local z = zombie:getZ()
    local directionX, directionY = resolveCombatFacing(zombie, target)
    local baseAngle = directionAngle(directionY, directionX)
    local halfAngle = math.rad(
        tonumber(debugState.coneHalfAngleDegrees) or 55
    )
    local radius = tonumber(debugState.coneRadius) or 8.5
    local segments = COMBAT_DEBUG_CONE_SEGMENTS
    local palette = resolveConePalette(debugState)
    local outerThickness = isSelected == true and 4 or 3
    local sideThickness = isSelected == true and 3 or 2
    local innerBandColor = {
        r = palette.r, g = palette.g, b = palette.b, a = 0.34,
    }
    local ribColor = {
        r = palette.r, g = palette.g, b = palette.b, a = 0.28,
    }
    local i

    drawConeBand(manager, originX, originY, z, baseAngle, halfAngle,
        radius * 0.38, 8, innerBandColor, 1, 0)
    drawConeBand(manager, originX, originY, z, baseAngle, halfAngle,
        radius * 0.72, 10, innerBandColor, 1, 0)
    drawConeBand(manager, originX, originY, z, baseAngle, halfAngle,
        radius, segments, palette, outerThickness, 0.72)

    local midIdx = math.floor(segments / 2)
    for i = 0, segments do
        local angle = baseAngle - halfAngle
            + ((halfAngle * 2) * (i / segments))
        local x = originX + math.cos(angle) * radius
        local y = originY + math.sin(angle) * radius
        if i == 0 or i == segments then
            drawWorldThickLine(
                manager, originX, originY, z, x, y, z,
                palette, sideThickness, 0.65
            )
        elseif i == midIdx then
            local tipColor = isSelected == true and SELECTED_CHEVRON_COLOR or palette
            drawWorldThickLine(
                manager, originX, originY, z, x, y, z,
                tipColor, 2, 0.55
            )
            local tipSize = math.min(0.65, radius * 0.12)
            local lx = x - math.cos(angle - 0.5) * tipSize
            local ly = y - math.sin(angle - 0.5) * tipSize
            local rx = x - math.cos(angle + 0.5) * tipSize
            local ry = y - math.sin(angle + 0.5) * tipSize
            drawWorldThickLine(manager, x, y, z, lx, ly, z, tipColor, 2, 0.45)
            drawWorldThickLine(manager, x, y, z, rx, ry, z, tipColor, 2, 0.45)
        elseif i % 3 == 0 then
            drawWorldLine(manager, originX, originY, z, x, y, z, ribColor)
        end
    end
end

local function drawFireLane(manager, zombie, debugState, target)
    local originX = zombie:getX()
    local originY = zombie:getY()
    local z = zombie:getZ()
    local targetX = tonumber(target.x)
    local targetY = tonumber(target.y)
    local targetZ = tonumber(target.z) or z
    local dx
    local dy
    local length
    local perpendicularX
    local perpendicularY
    local corridor = 0.62
    local color
    if not targetX or not targetY then return end
    if debugState.fireLaneSafe == false then
        color = COMBAT_UNSAFE_COLOR
    elseif debugState.aimReadyInMs
        and tonumber(debugState.aimReadyInMs) > 0
    then
        color = COMBAT_AIM_COLOR
    else
        color = (
            debugState.mode == "ranged"
                or debugState.mode == "mixed"
        )
            and COMBAT_SAFE_COLOR
            or COMBAT_TARGET_COLOR
    end
    drawWorldLine(
        manager,
        originX,
        originY,
        z,
        targetX,
        targetY,
        targetZ,
        color
    )
    if debugState.mode ~= "ranged"
        and debugState.mode ~= "mixed"
    then
        return
    end
    dx = targetX - originX
    dy = targetY - originY
    length = math.sqrt((dx * dx) + (dy * dy))
    if length <= 0.001 then return end
    perpendicularX = (-dy / length) * corridor
    perpendicularY = (dx / length) * corridor
    drawWorldLine(
        manager,
        originX + perpendicularX,
        originY + perpendicularY,
        z,
        targetX + perpendicularX,
        targetY + perpendicularY,
        targetZ,
        {
            r = color.r,
            g = color.g,
            b = color.b,
            a = color.a * 0.42,
        }
    )
    drawWorldLine(
        manager,
        originX - perpendicularX,
        originY - perpendicularY,
        z,
        targetX - perpendicularX,
        targetY - perpendicularY,
        targetZ,
        {
            r = color.r,
            g = color.g,
            b = color.b,
            a = color.a * 0.42,
        }
    )
end

local function resolveZombieAttacker(attacker)
    local onlineID
    local zombieId
    local zombie
    if type(attacker) ~= "table" then return nil end
    onlineID = tonumber(attacker.onlineID)
    if onlineID and onlineID >= 0
        and PNC.Network
        and PNC.Network.FindZombieByOnlineID
    then
        zombie =
            PNC.Network.FindZombieByOnlineID(onlineID)
        if zombie then return zombie end
    end
    zombieId = attacker.zombieId
    if zombieId
        and PNC.Perception
        and PNC.Perception.FindZombieByID
    then
        return PNC.Perception.FindZombieByID(zombieId)
    end
    return nil
end

local function drawZombieAttackerDebug(
    manager,
    npcBody,
    attacker
)
    local zombie
    local x
    local y
    local z
    local npcX
    local npcY
    local npcZ
    local distance
    local screenX
    local screenY
    local lineHeight
    local firstLine
    local secondLine
    if not npcBody or type(attacker) ~= "table" then
        return
    end
    zombie = resolveZombieAttacker(attacker)
    if zombie and zombie.isDead and zombie:isDead() then
        zombie = nil
    end
    x = zombie and zombie:getX() or tonumber(attacker.x)
    y = zombie and zombie:getY() or tonumber(attacker.y)
    z = zombie and zombie:getZ() or tonumber(attacker.z)
    if not x or not y or z == nil then return end
    npcX = npcBody:getX()
    npcY = npcBody:getY()
    npcZ = npcBody:getZ()
    distance = math.sqrt(
        ((x - npcX) * (x - npcX))
            + ((y - npcY) * (y - npcY))
    )
    drawWorldLine(
        manager,
        x,
        y,
        z,
        npcX,
        npcY,
        npcZ,
        ZOMBIE_ATTACKER_COLOR
    )
    drawWorldMarker(
        manager,
        x,
        y,
        z,
        ZOMBIE_ATTACKER_COLOR,
        COMBAT_MARKER_HALF_SIZE + 4
    )
    screenX, screenY = screenPoint(manager, x, y, z)
    lineHeight =
        getTextManager():getFontHeight(Fonts.debug) + 2
    firstLine = "ZED -> "
        .. tostring(
            attacker.targetName
                or attacker.targetId
                or "Unknown survivor"
        )
        .. " | zed="
        .. tostring(attacker.zombieId or attacker.onlineID or "?")
        .. " phase=" .. tostring(attacker.phase or "-")
        .. " d=" .. tostring(rounded(distance, 2) or "-")
        .. " age=" .. tostring(
            math.floor(tonumber(attacker.ageMs) or 0)
        ) .. "ms"
    secondLine = "state="
        .. tostring(
            zombie and zombie.getActionStateName
                and zombie:getActionStateName()
                or attacker.actionState or "-"
        )
        .. " bump="
        .. tostring(
            zombie and zombie.getBumpType
                and zombie:getBumpType()
                or attacker.bumpType or "-"
        )
        .. " path2="
        .. tostring(
            zombie and zombie.getPath2
                and zombie:getPath2() ~= nil
                or attacker.path2Active == true
        )
    Presentation.DrawOutlinedText(
        manager,
        firstLine,
        screenX + 16,
        screenY - lineHeight,
        ZOMBIE_ATTACKER_COLOR,
        1,
        Fonts.debug
    )
    Presentation.DrawOutlinedText(
        manager,
        secondLine,
        screenX + 16,
        screenY,
        ZOMBIE_ATTACKER_COLOR,
        1,
        Fonts.debug
    )
end

local function drawWarningLink(manager, worldX, worldY, worldZ, debugState)
    local link = type(debugState.warningLink) == "table"
        and debugState.warningLink or nil
    if not link then return end
    local lx = tonumber(link.x)
    local ly = tonumber(link.y)
    local lz = tonumber(link.z) or worldZ
    if not lx or not ly then return end
    drawWorldThickLine(
        manager,
        worldX,
        worldY,
        worldZ,
        lx,
        ly,
        lz,
        WARNING_LINK_COLOR,
        3,
        0.65
    )
    drawWorldMarker(
        manager,
        lx,
        ly,
        lz,
        WARNING_LINK_COLOR,
        COMBAT_MARKER_HALF_SIZE + 2
    )
end

local function drawVisionConeOnly(manager, zombie, debugState, worldX, worldY, worldZ, isSelected)
    local palette = resolveConePalette(debugState)
    drawCombatCone(manager, zombie, debugState, isSelected)
    local peripheralRadius = tonumber(debugState.peripheralRadius) or 2.5
    if peripheralRadius > 0 then
        drawWorldCircle(
            manager,
            worldX,
            worldY,
            worldZ,
            peripheralRadius,
            PERIPHERAL_CONE_COLOR,
            false,
            COMBAT_DEBUG_CIRCLE_SEGMENTS,
            2
        )
    end
    drawWarningLink(manager, worldX, worldY, worldZ, debugState)
    local clues = type(debugState.clues) == "table" and debugState.clues or nil
    if clues then
        for i = 1, #clues do
            local c = clues[i]
            local cx = c and tonumber(c.x)
            local cy = c and tonumber(c.y)
            local cz = (c and tonumber(c.z)) or worldZ
            if cx and cy then
                drawWorldThickLine(manager, worldX, worldY, worldZ, cx, cy, cz, {
                    r = CLUE_MARKER_COLOR.r,
                    g = CLUE_MARKER_COLOR.g,
                    b = CLUE_MARKER_COLOR.b,
                    a = 0.62,
                }, 2, 0.45)
                drawWorldMarker(manager, cx, cy, cz, CLUE_MARKER_COLOR, 7)
            end
        end
    end
end

local function drawCombatRanges(manager, zombie, debugState, worldX, worldY, worldZ, isSelected)
    drawVisionConeOnly(manager, zombie, debugState, worldX, worldY, worldZ, isSelected)
    drawWorldCircle(
        manager,
        worldX,
        worldY,
        worldZ,
        debugState.defenseRadius,
        COMBAT_DEFENSE_COLOR,
        false,
        COMBAT_DEBUG_CIRCLE_SEGMENTS
    )
    drawZombieAttackerDebug(
        manager,
        zombie,
        debugState.zombieAttacker
    )
    drawWorldCircle(
        manager,
        worldX,
        worldY,
        worldZ,
        debugState.pressureRadius,
        COMBAT_PRESSURE_COLOR,
        true,
        COMBAT_DEBUG_CIRCLE_SEGMENTS
    )
    drawWorldCircle(
        manager,
        worldX,
        worldY,
        worldZ,
        debugState.hordeRadius,
        COMBAT_HORDE_COLOR,
        true,
        COMBAT_DEBUG_CIRCLE_SEGMENTS
    )
    if debugState.mode == 'melee'
        or debugState.mode == 'mixed'
    then
        drawWorldCircle(
            manager,
            worldX,
            worldY,
            worldZ,
            debugState.meleeRange,
            COMBAT_MELEE_COLOR,
            false,
            COMBAT_DEBUG_CIRCLE_SEGMENTS
        )
    end
    if debugState.mode == 'ranged'
        or debugState.mode == 'mixed'
    then
        drawWorldCircle(
            manager,
            worldX,
            worldY,
            worldZ,
            debugState.rangedPreferredDistance,
            COMBAT_AIM_COLOR,
            true,
            COMBAT_DEBUG_CIRCLE_SEGMENTS
        )
        drawWorldCircle(
            manager,
            worldX,
            worldY,
            worldZ,
            debugState.rangedRange,
            COMBAT_RANGE_COLOR,
            false,
            COMBAT_DEBUG_CIRCLE_SEGMENTS
        )
    end
end

local function drawCombatTargets(manager, zombie, debugState, worldX, worldY, worldZ)
    local target = debugState.target
    local targetDistance
    local blocker = debugState.fireLaneBlocker
    local movement = debugState.tacticalMove
    if type(target) == 'table'
        and tonumber(target.x)
        and tonumber(target.y)
    then
        targetDistance = math.sqrt(
            ((tonumber(target.x) - worldX) ^ 2)
                + ((tonumber(target.y) - worldY) ^ 2)
        )
        drawFireLane(manager, zombie, debugState, target)
        drawWorldMarker(
            manager,
            tonumber(target.x),
            tonumber(target.y),
            tonumber(target.z) or worldZ,
            COMBAT_TARGET_COLOR,
            COMBAT_MARKER_HALF_SIZE
        )
    end
    if type(blocker) == 'table'
        and tonumber(blocker.x)
        and tonumber(blocker.y)
    then
        drawWorldMarker(
            manager,
            tonumber(blocker.x),
            tonumber(blocker.y),
            tonumber(blocker.z) or worldZ,
            COMBAT_BLOCKER_COLOR,
            COMBAT_MARKER_HALF_SIZE + 3
        )
    end
    if type(movement) == 'table'
        and tonumber(movement.x)
        and tonumber(movement.y)
    then
        drawWorldLine(
            manager,
            worldX,
            worldY,
            worldZ,
            tonumber(movement.x),
            tonumber(movement.y),
            tonumber(movement.z) or worldZ,
            COMBAT_MOVE_COLOR
        )
        drawWorldMarker(
            manager,
            tonumber(movement.x),
            tonumber(movement.y),
            tonumber(movement.z) or worldZ,
            COMBAT_MOVE_COLOR,
            COMBAT_MARKER_HALF_SIZE
        )
    end
    return targetDistance
end

local function appendCombatAnimationLines(lines, zombie, debugState)
    if type(debugState.action) ~= 'table' then return end
    lines[#lines + 1] = Renderer.BuildBodyAnimationDebugLine(
        zombie,
        debugState.action
    )
    local trackLine = Renderer.BuildAnimationTrackDebugLine(zombie)
    if trackLine then lines[#lines + 1] = trackLine end
    local traceLine = Renderer.BuildAnimationTraceDebugLine(zombie)
    if traceLine then lines[#lines + 1] = traceLine end
end

local function combatTextColor(debugState, line)
    if string.sub(line, 1, 8) == 'DEFENSE ' then
        return COMBAT_DEFENSE_COLOR
    end
    if string.sub(line, 1, 5) == 'ANIM '
        or string.sub(line, 1, 6) == 'TRACK '
    then
        return DEBUG_COLOR
    end
    if debugState.fireLaneSafe == false then
        return COMBAT_UNSAFE_COLOR
    end
    if debugState.decision
        and string.find(
            tostring(debugState.decision),
            'retreat',
            1,
            true
        )
    then
        return COMBAT_AIM_COLOR
    end
    return COMBAT_CONE_COLOR
end

local function measureMaxLineWidth(lines, font)
    local tm = getTextManager and getTextManager() or nil
    local maxWidth = 0
    local i
    for i = 1, #lines do
        local text = tostring(lines[i] or "")
        local w
        if tm and type(tm.MeasureStringX) == "function" then
            w = tonumber(tm:MeasureStringX(font, text)) or 0
        else
            w = #text * 7
        end
        if w > maxWidth then maxWidth = w end
    end
    return maxWidth
end

local function resolveAntiOverlapY(x, y, width, height, usedRects)
    if type(usedRects) ~= "table" then return y end
    local shiftedY = y
    local tries = 0
    while tries < 8 do
        local overlap = false
        for i = 1, #usedRects do
            local rect = usedRects[i]
            if x < rect.x + rect.w
                and x + width > rect.x
                and shiftedY < rect.y + rect.h
                and shiftedY + height > rect.y
            then
                shiftedY = rect.y + rect.h + 2
                overlap = true
                break
            end
        end
        if not overlap then break end
        tries = tries + 1
    end
    usedRects[#usedRects + 1] = {
        x = x, y = shiftedY, w = width, h = height,
    }
    return shiftedY
end

local function drawCombatText(manager, zombie, debugState, lines, opts)
    if type(lines) ~= "table" or #lines <= 0 then return end
    opts = type(opts) == "table" and opts or nil
    local screenX, screenY = screenPoint(
        manager,
        zombie:getX(),
        zombie:getY(),
        zombie:getZ()
    )
    local lineHeight = getTextManager():getFontHeight(Fonts.debug) + 2
    local boxX = screenX + 18
    local labelY = screenY + 18 + (tonumber(opts and opts.yOffset) or 0)
    local boxWidth = measureMaxLineWidth(lines, Fonts.debug) + 10
    local boxHeight = (#lines * lineHeight) + 4
    if opts and type(opts.usedLabelRects) == "table" then
        labelY = resolveAntiOverlapY(
            boxX - 4,
            labelY - 2,
            boxWidth,
            boxHeight,
            opts.usedLabelRects
        ) + 2
    end
    if type(manager.drawRect) == "function" then
        manager:drawRect(boxX - 4, labelY - 2, boxWidth, boxHeight, 0.72, 0.04, 0.06, 0.09)
    end
    for index = 1, #lines do
        Presentation.DrawOutlinedText(
            manager,
            lines[index],
            boxX,
            labelY + ((index - 1) * lineHeight),
            combatTextColor(debugState, lines[index]),
            1,
            Fonts.debug
        )
    end
end


Internal.DrawVisionConeOnly = drawVisionConeOnly
Internal.DrawCombatRanges = drawCombatRanges
Internal.DrawCombatTargets = drawCombatTargets
Internal.AppendCombatAnimationLines = appendCombatAnimationLines
Internal.CombatTextColor = combatTextColor
Internal.DrawCombatText = drawCombatText
Internal.ResolveZombieAttacker = resolveZombieAttacker

require "PNC/UI/Nameplates/NameplateRenderer/PNC_NameplateRenderer_CombatDebug_Render"

return Renderer
