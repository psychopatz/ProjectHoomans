local Renderer = PNC.NameplateRenderer
local Internal = Renderer.Internal
local Presentation = PNC.NameplatePresentation
local Fonts = Presentation.Fonts
local rounded = Internal.Rounded
local screenPoint = Internal.ScreenPoint
local drawWorldLine = Internal.DrawWorldLine
local drawWorldMarker = Internal.DrawWorldMarker
local drawWorldCircle = Internal.DrawWorldCircle

local SOUND_EMITTED_COLOR = { r = 1.0, g = 0.76, b = 0.16, a = 0.95 }
local SOUND_OBSERVED_COLOR = { r = 0.20, g = 1.0, b = 0.42, a = 0.95 }
local SOUND_MISMATCH_COLOR = { r = 1.0, g = 0.24, b = 0.18, a = 0.95 }
local SOUND_SUPPRESSED_COLOR = { r = 0.82, g = 0.44, b = 1.0, a = 0.95 }
local NATIVE_AI_COLOR = { r = 0.35, g = 0.82, b = 1.0, a = 0.94 }
local SOUND_CIRCLE_SEGMENTS = 12
local SOUND_MARKER_HALF_SIZE = 10

local function distanceSq(x1, y1, x2, y2)
    if not x1 or not y1 or not x2 or not y2 then return math.huge end
    return ((x1 - x2) * (x1 - x2))
        + ((y1 - y2) * (y1 - y2))
end

local function findClientObservation(zombie, now)
    local sync = PNC.ClientPresenceSync
    local internal = sync and sync.Internal or nil
    if not internal or not internal.GetClientZombieSoundObservation then
        return nil
    end
    return internal.GetClientZombieSoundObservation(zombie, now)
end

local function nativeTargetLabel(zombie)
    local target
    local record
    local targetID
    if not zombie or not zombie.getTarget then return "none" end
    target = zombie:getTarget()
    if not target then return "none" end
    if PNC.Core and PNC.Core.IsManagedNPCBody
        and PNC.Core.IsManagedNPCBody(target)
    then
        record = PNC.Registry and PNC.Registry.FindRecordByZombie
            and PNC.Registry.FindRecordByZombie(target) or nil
        return "npc:" .. tostring(
            record and (record.displayName or record.name or record.id)
                or "unknown"
        )
    end
    if instanceof and instanceof(target, "IsoPlayer") then
        targetID = target.getUsername and target:getUsername()
            or target.getOnlineID and target:getOnlineID()
            or "player"
        return "player:" .. tostring(targetID)
    end
    return "object"
end

local function nativeState(zombie)
    local state = zombie and zombie.getActionStateName
        and tostring(zombie:getActionStateName() or "-") or "-"
    local useless = zombie and zombie.isUseless
        and zombie:isUseless() == true or false
    local moving = zombie and zombie.isMoving
        and zombie:isMoving() == true or false
    local path = zombie and zombie.getPath2
        and zombie:getPath2() ~= nil or false
    local known = zombie and zombie.isTargetLocationKnown
        and zombie:isTargetLocationKnown() == true or false
    local responding = zombie and zombie.isRespondingToPlayerSound
        and zombie:isRespondingToPlayerSound() == true or false
    return state, useless, moving, path, known, responding
end

local function formatPosition(x, y, z)
    if not x or not y then return "-" end
    return tostring(math.floor(x)) .. "," .. tostring(math.floor(y))
        .. "," .. tostring(math.floor(z or 0))
end

local function drawMarkerOnce(manager, drawn, key, x, y, z, color, size)
    if not x or not y or z == nil or drawn[key] then return end
    drawn[key] = true
    drawWorldMarker(manager, x, y, z, color, size)
end

local function drawSoundDebug(manager, entry, drawn, now)
    local snapshot = entry.snapshot
    local combat = snapshot and snapshot.combatDebugState or nil
    local stimulus = combat and combat.zombieStimulus or nil
    local attacker = combat and combat.zombieAttacker or nil
    local zombie
    local observation
    local observedMatch = false
    local soundColor = SOUND_MISMATCH_COLOR
    local soundX
    local soundY
    local soundZ
    local nativeX
    local nativeY
    local nativeZ
    local nativeStateName
    local useless
    local moving
    local path
    local locationKnown
    local responding
    local newSoundMarker
    local lines = {}
    local lineHeight
    local labelX
    local labelY
    local i

    if type(combat) ~= "table" then return end
    if Renderer.ResolveZombieAttacker and type(attacker) == "table" then
        zombie = Renderer.ResolveZombieAttacker(attacker)
    end
    if zombie and zombie.isDead and zombie:isDead() then zombie = nil end
    observation = findClientObservation(zombie, now)

    if type(stimulus) == "table" then
        soundX = tonumber(stimulus.x)
        soundY = tonumber(stimulus.y)
        soundZ = tonumber(stimulus.z) or 0
        if stimulus.state == "emitted" then
            soundColor = SOUND_EMITTED_COLOR
            if observation and observation.found == true then
                observedMatch = distanceSq(
                    soundX,
                    soundY,
                    tonumber(observation.x),
                    tonumber(observation.y)
                ) <= 2.25
                if observedMatch then
                    soundColor = SOUND_OBSERVED_COLOR
                end
            end
        elseif stimulus.state == "suppressed" then
            soundColor = SOUND_SUPPRESSED_COLOR
        end
        if soundX and soundY then
            local soundKey = "stimulus:"
                .. tostring(stimulus.sequence or formatPosition(soundX, soundY, soundZ))
            newSoundMarker = not drawn[soundKey]
            drawMarkerOnce(
                manager,
                drawn,
                soundKey,
                soundX,
                soundY,
                soundZ,
                soundColor,
                SOUND_MARKER_HALF_SIZE
            )
            if stimulus.state == "emitted" and newSoundMarker then
                drawWorldCircle(
                    manager,
                    soundX,
                    soundY,
                    soundZ,
                    tonumber(stimulus.radius),
                    soundColor,
                    true,
                    SOUND_CIRCLE_SEGMENTS
                )
            end
        end
        lines[#lines + 1] = "PNC_SOUND "
            .. tostring(stimulus.state or "unknown")
            .. " seq=" .. tostring(stimulus.sequence or "-")
            .. " pos=" .. formatPosition(soundX, soundY, soundZ)
            .. " r=" .. tostring(stimulus.radius or "-")
            .. " v=" .. tostring(stimulus.volume or "-")
            .. " age=" .. tostring(math.floor(tonumber(stimulus.ageMs) or 0))
            .. "ms"
        if stimulus.reason then
            lines[#lines + 1] = "SOUND_REASON "
                .. tostring(stimulus.reason)
        end
    end

    if observation and observation.found == true then
        local observedKey = "observed:"
            .. tostring(attacker and (attacker.zombieId or attacker.onlineID) or "unknown")
        local observedColor = observedMatch
            and SOUND_OBSERVED_COLOR or SOUND_MISMATCH_COLOR
        drawMarkerOnce(
            manager,
            drawn,
            observedKey,
            tonumber(observation.x),
            tonumber(observation.y),
            tonumber(observation.z) or 0,
            observedColor,
            SOUND_MARKER_HALF_SIZE - 2
        )
        if soundX and soundY and observation.x and observation.y
            and not observedMatch
        then
            drawWorldLine(
                manager,
                soundX,
                soundY,
                soundZ,
                tonumber(observation.x),
                tonumber(observation.y),
                tonumber(observation.z) or soundZ,
                SOUND_MISMATCH_COLOR
            )
        end
        lines[#lines + 1] = "WORLD_SOUND observed pos="
            .. formatPosition(observation.x, observation.y, observation.z)
            .. " match=" .. (observedMatch and "PNC" or "OTHER")
            .. " attract=" .. tostring(rounded(observation.attract, 2) or "-")
            .. " r=" .. tostring(observation.radius or "-")
            .. " v=" .. tostring(observation.volume or "-")
            .. " age=" .. tostring(math.floor(
                math.max(0, now - (tonumber(observation.observedAt) or now))
            )) .. "ms"
    elseif type(stimulus) == "table" and stimulus.state == "emitted" then
        lines[#lines + 1] = "WORLD_SOUND NOT_OBSERVED"
    elseif type(stimulus) ~= "table" then
        lines[#lines + 1] = "WORLD_SOUND none (SP native lane)"
    end

    if zombie then
        nativeX = zombie:getX()
        nativeY = zombie:getY()
        nativeZ = zombie:getZ()
        nativeStateName, useless, moving, path, locationKnown, responding =
            nativeState(zombie)
        drawMarkerOnce(
            manager,
            drawn,
            "native:" .. tostring(attacker and (attacker.zombieId or attacker.onlineID) or zombie),
            nativeX,
            nativeY,
            nativeZ,
            NATIVE_AI_COLOR,
            SOUND_MARKER_HALF_SIZE - 3
        )
        lines[#lines + 1] = "NATIVE target=" .. nativeTargetLabel(zombie)
            .. " state=" .. nativeStateName
            .. " useless=" .. tostring(useless)
            .. " moving=" .. tostring(moving)
            .. " path2=" .. tostring(path)
            .. " known=" .. tostring(locationKnown)
            .. " responding=" .. tostring(responding)
    elseif type(attacker) == "table" then
        lines[#lines + 1] = "NATIVE unavailable owner/replica not local"
    end

    if #lines <= 0 then return end
    if zombie then
        labelX, labelY = screenPoint(manager, nativeX, nativeY, nativeZ)
    elseif soundX and soundY then
        labelX, labelY = screenPoint(manager, soundX, soundY, soundZ)
    else
        return
    end
    lineHeight = getTextManager():getFontHeight(Fonts.debug) + 2
    labelX = labelX + 16
    labelY = labelY - (#lines * lineHeight) - 6
    for i = 1, #lines do
        local color = NATIVE_AI_COLOR
        if string.sub(lines[i], 1, 9) == "PNC_SOUND" then
            color = soundColor
        elseif string.sub(lines[i], 1, 12) == "SOUND_REASON"
            or string.find(lines[i], "NOT_OBSERVED", 1, true)
        then
            color = SOUND_MISMATCH_COLOR
        elseif string.sub(lines[i], 1, 11) == "WORLD_SOUND" then
            color = observation and observedMatch
                and SOUND_OBSERVED_COLOR or SOUND_MISMATCH_COLOR
        end
        Presentation.DrawOutlinedText(
            manager,
            lines[i],
            labelX,
            labelY + ((i - 1) * lineHeight),
            color,
            1,
            Fonts.debug
        )
    end
end

Renderer.RenderZombieDebug = drawSoundDebug

return Renderer
