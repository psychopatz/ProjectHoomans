local Renderer = PNC.NameplateRenderer
local Internal = Renderer.Internal
local Presentation = PNC.NameplatePresentation
local Fonts = Presentation.Fonts
local rounded = Internal.Rounded
local screenPoint = Internal.ScreenPoint
local drawWorldLine = Internal.DrawWorldLine
local drawWorldMarker = Internal.DrawWorldMarker
local drawWorldCircle = Internal.DrawWorldCircle

local DEBUG_COLOR = { r = 0.8, g = 0.9, b = 1.0, a = 1.0 }
local COMBAT_CONE_COLOR = { r = 0.25, g = 0.9, b = 1.0, a = 0.52 }
local COMBAT_TARGET_COLOR = { r = 1.0, g = 0.22, b = 0.16, a = 0.9 }
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
local COMBAT_MARKER_HALF_SIZE = 9
local COMBAT_DEBUG_CONE_SEGMENTS = 8
local COMBAT_DEBUG_CIRCLE_SEGMENTS = 16

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

local function drawCombatCone(manager, zombie, debugState)
    local target = debugState.target
    local originX = zombie:getX()
    local originY = zombie:getY()
    local z = zombie:getZ()
    local directionX
    local directionY
    local baseAngle
    local halfAngle = math.rad(
        tonumber(debugState.coneHalfAngleDegrees) or 55
    )
    local radius = tonumber(debugState.coneRadius) or 8.5
    local segments = COMBAT_DEBUG_CONE_SEGMENTS
    local previousX
    local previousY
    local x
    local y
    local angle
    local i
    directionX, directionY = resolveCombatFacing(zombie, target)
    baseAngle = directionAngle(directionY, directionX)
    for i = 0, segments do
        angle = baseAngle - halfAngle
            + ((halfAngle * 2) * (i / segments))
        x = originX + math.cos(angle) * radius
        y = originY + math.sin(angle) * radius
        if previousX ~= nil then
            drawWorldLine(
                manager,
                previousX,
                previousY,
                z,
                x,
                y,
                z,
                COMBAT_CONE_COLOR
            )
        end
        if i == 0 or i == segments
            or i == math.floor(segments / 2)
        then
            drawWorldLine(
                manager,
                originX,
                originY,
                z,
                x,
                y,
                z,
                {
                    r = COMBAT_CONE_COLOR.r,
                    g = COMBAT_CONE_COLOR.g,
                    b = COMBAT_CONE_COLOR.b,
                    a = i == math.floor(segments / 2)
                        and 0.42 or 0.25,
                }
            )
        end
        previousX = x
        previousY = y
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

local function drawCombatDebug(manager, entry)
    local zombie = entry.zombie
    local debugState = entry.snapshot
        and entry.snapshot.combatDebugState or nil
    local target
    local blocker
    local movement
    local worldX
    local worldY
    local worldZ
    local targetDistance
    local lines
    local textColor
    local screenX
    local screenY
    local lineHeight
    local labelX
    local labelY
    local i
    local active
    if not zombie
        or zombie:isDead()
        or type(debugState) ~= "table"
    then
        return
    end
    worldX = zombie:getX()
    worldY = zombie:getY()
    worldZ = zombie:getZ()
    target = debugState.target

    active = type(target) == "table"
        or type(debugState.action) == "table"
        or type(debugState.tacticalMove) == "table"
        or type(debugState.zombieAttacker) == "table"
        or entry.snapshot.attackMode == true
        or entry.snapshot.inCombat == true
    if not active then return end
    drawCombatCone(manager, zombie, debugState)
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
    if debugState.mode == "melee"
        or debugState.mode == "mixed"
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
    if debugState.mode == "ranged"
        or debugState.mode == "mixed"
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

    if type(target) == "table"
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

    blocker = debugState.fireLaneBlocker
    if type(blocker) == "table"
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

    movement = debugState.tacticalMove
    if type(movement) == "table"
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

    lines = Renderer.BuildCombatDebugLines(
        debugState,
        targetDistance
    )
    if type(debugState.action) == "table" then
        lines[#lines + 1] =
            Renderer.BuildBodyAnimationDebugLine(
                zombie,
                debugState.action
            )
        local trackLine =
            Renderer.BuildAnimationTrackDebugLine(zombie)
        if trackLine then
            lines[#lines + 1] = trackLine
        end
        local traceLine =
            Renderer.BuildAnimationTraceDebugLine(zombie)
        if traceLine then
            lines[#lines + 1] = traceLine
        end
    end
    if #lines <= 0 then return end
    if debugState.fireLaneSafe == false then
        textColor = COMBAT_UNSAFE_COLOR
    elseif debugState.decision
        and string.find(
            tostring(debugState.decision),
            "retreat",
            1,
            true
        )
    then
        textColor = COMBAT_AIM_COLOR
    else
        textColor = COMBAT_CONE_COLOR
    end
    screenX, screenY = screenPoint(
        manager,
        worldX,
        worldY,
        worldZ
    )
    lineHeight = getTextManager():getFontHeight(Fonts.debug) + 2
    labelY = screenY + 18
    for i = 1, #lines do
        labelX = screenX + 18
        if string.sub(lines[i], 1, 8) == "DEFENSE " then
            textColor = COMBAT_DEFENSE_COLOR
        elseif string.sub(lines[i], 1, 5) == "ANIM "
            or string.sub(lines[i], 1, 6) == "TRACK "
        then
            textColor = DEBUG_COLOR
        elseif debugState.fireLaneSafe == false then
            textColor = COMBAT_UNSAFE_COLOR
        elseif debugState.decision
            and string.find(
                tostring(debugState.decision),
                "retreat",
                1,
                true
            )
        then
            textColor = COMBAT_AIM_COLOR
        else
            textColor = COMBAT_CONE_COLOR
        end
        Presentation.DrawOutlinedText(
            manager,
            lines[i],
            labelX,
            labelY + ((i - 1) * lineHeight),
            textColor,
            1,
            Fonts.debug
        )
    end
end

Renderer.RenderCombatDebug = drawCombatDebug

return Renderer
