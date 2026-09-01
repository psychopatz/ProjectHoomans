require "PNC/UI/Nameplates/PNC_NameplateSpeech"
require "PNC/UI/Nameplates/PNC_NameplateRelationshipFeedbackRenderer"
require "PNC/UI/Nameplates/PNC_NameplateScopes"

PNC = PNC or {}
PNC.NameplateRenderer = PNC.NameplateRenderer or {}

local Renderer = PNC.NameplateRenderer
local Diagnostics = PNC.PerformanceScalingDiagnostics
local Presentation = PNC.NameplatePresentation
local NameplateDebug = PNC.NameplateDebug
local Speech = PNC.NameplateSpeech
local RelationshipFeedbackRenderer =
    PNC.NameplateRelationshipFeedbackRenderer
local Scopes = PNC.NameplateScopes
local Layout = Presentation.Layout
local Fonts = Presentation.Fonts

local DEBUG_COLOR = { r = 0.8, g = 0.9, b = 1.0, a = 1.0 }
local FACTION_COLORS = {
    danger = { r = 1.0, g = 0.20, b = 0.16, a = 1.0 },
    warning = { r = 1.0, g = 0.72, b = 0.18, a = 1.0 },
    success = { r = 0.22, g = 1.0, b = 0.42, a = 1.0 },
    neutral = { r = 0.12, g = 0.88, b = 1.0, a = 1.0 },
}
local SCENE_COLOR = { r = 0.68, g = 0.48, b = 1.0, a = 1.0 }
local SCENE_TRACK_COLOR = { r = 0.52, g = 0.82, b = 1.0, a = 1.0 }
local INFECTION_COLOR = { r = 1.0, g = 0.12, b = 0.08, a = 1.0 }
local PATH_COLOR = { r = 0.15, g = 0.82, b = 1.0, a = 0.82 }
local PATH_BLOCKED_COLOR = { r = 1.0, g = 0.3, b = 0.2, a = 0.9 }
local PATH_FINAL_COLOR = { r = 0.45, g = 0.72, b = 1.0, a = 0.42 }
local PATH_MARKER_HALF_SIZE = 15
local PATH_FINAL_MARKER_HALF_SIZE = 8
local SEATING_COLOR = { r = 0.16, g = 0.92, b = 1.0, a = 0.78 }
local SEATING_SELECTED_COLOR = { r = 1.0, g = 0.82, b = 0.16, a = 0.95 }
local SEATING_SPOT_COLOR = { r = 0.28, g = 1.0, b = 0.44, a = 0.82 }
local SEATING_BLOCKED_COLOR = { r = 1.0, g = 0.22, b = 0.18, a = 0.9 }
local SEATING_TILE_COLOR = { r = 0.2, g = 0.84, b = 1.0, a = 0.32 }
local CAMP_RESOURCE_COLORS = {
    bed = { r = 0.78, g = 0.42, b = 1.0, a = 0.78 },
    water = { r = 0.22, g = 0.62, b = 1.0, a = 0.78 },
    seating = { r = 0.28, g = 1.0, b = 0.44, a = 0.78 },
    other = { r = 1.0, g = 0.72, b = 0.2, a = 0.78 },
}
local CAMP_RESOURCE_SELECTED_COLOR = { r = 1.0, g = 0.84, b = 0.18, a = 0.98 }
local CAMP_RESOURCE_BLOCKED_COLOR = { r = 1.0, g = 0.2, b = 0.16, a = 0.92 }
local CAMP_RESOURCE_TILE_COLOR = { r = 0.86, g = 0.9, b = 1.0, a = 0.42 }
local CAMP_RADIUS_COLOR = { r = 1.0, g = 0.64, b = 0.16, a = 0.88 }
local CAMP_RESOURCE_RADIUS_COLOR = { r = 0.72, g = 0.78, b = 0.96, a = 0.45 }
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

local function scopeVisible(entry, scope, fallback)
    if type(entry.scopes) ~= "table" or entry.scopes[scope] == nil then
        return fallback == true
    end
    return entry.scopes[scope] == true
end

local function drawStatusBar(manager, left, top, width, height, ratio, color, alpha, backgroundAlpha)
    manager:drawRect(
        left - Layout.padding,
        top - Layout.padding,
        width + (Layout.padding * 2),
        height + (Layout.padding * 2),
        backgroundAlpha * alpha,
        0,
        0,
        0
    )
    manager:drawRect(left, top, width * ratio, height, color.a * alpha, color.r, color.g, color.b)
    manager:drawRectBorder(
        left - Layout.padding,
        top - Layout.padding,
        width + (Layout.padding * 2),
        height + (Layout.padding * 2),
        alpha,
        math.min(1, color.r + 0.08),
        math.min(1, color.g + 0.08),
        math.min(1, color.b + 0.08)
    )
end

local function drawHealth(manager, entry, metrics, barLeft, barTop, alpha)
    if not entry.healthVisible then return end
    drawStatusBar(
        manager,
        barLeft,
        barTop,
        metrics.barWidth,
        metrics.barHeight,
        entry.healthRatio,
        entry.barColor,
        alpha,
        0.55
    )
end

local function drawStamina(manager, entry, metrics, barLeft, barTop, alpha)
    if not entry.staminaVisible then return nil end
    local top = entry.healthVisible
        and (barTop + metrics.barHeight + (6 / metrics.zoom)) or barTop
    drawStatusBar(
        manager,
        barLeft,
        top,
        metrics.barWidth,
        metrics.barHeight,
        entry.staminaRatio,
        entry.staminaColor,
        alpha,
        0.48
    )
    return top
end

local function drawDebugText(
    manager,
    entry,
    screenX,
    y,
    alpha,
    showAnimation,
    showScene
)
    local lineHeight = getTextManager():getFontHeight(Fonts.debug) + 2
    local factionColor = FACTION_COLORS[
        entry.factionDebugTone or "neutral"
    ] or FACTION_COLORS.neutral
    for _, key in ipairs({
        "factionDebugLine1",
        "factionDebugLine2",
        "factionDebugLine3",
    }) do
        local value = entry[key]
        if value and value ~= "" then
            Presentation.DrawOutlinedText(
                manager,
                value,
                screenX - ((entry[key .. "Width"] or 0) / 2),
                y,
                factionColor,
                alpha,
                Fonts.debug
            )
            y = y + lineHeight
        end
    end
    for _, definition in ipairs({
        {
            key = "relationshipDebugLine",
            tone = entry.relationshipDebugTone,
        },
        {
            key = "relationshipChangeLine",
            tone = entry.relationshipChangeTone,
        },
    }) do
        local key = definition.key
        local value = entry[key]
        local color = FACTION_COLORS[
            definition.tone or "neutral"
        ] or FACTION_COLORS.neutral
        if value and value ~= "" then
            Presentation.DrawOutlinedText(
                manager,
                value,
                screenX
                    - ((entry[key .. "Width"] or 0) / 2),
                y,
                color,
                alpha,
                Fonts.debug
            )
            y = y + lineHeight
        end
    end
    for _, key in ipairs({
        "communityDebugLine1",
        "communityDebugLine2",
    }) do
        local value = entry[key]
        if value and value ~= "" then
            local color = FACTION_COLORS[
                entry.communityDebugTone or "neutral"
            ] or FACTION_COLORS.neutral
            Presentation.DrawOutlinedText(
                manager,
                value,
                screenX
                    - ((entry[key .. "Width"] or 0) / 2),
                y,
                color,
                alpha,
                Fonts.debug
            )
            y = y + lineHeight
        end
    end
    if entry.debugText and entry.debugText ~= "" then
        Presentation.DrawOutlinedText(
            manager,
            entry.debugText,
            screenX - ((entry.debugTextWidth or 0) / 2),
            y,
            DEBUG_COLOR,
            alpha,
            Fonts.debug
        )
        y = y + lineHeight
    end
    if entry.infectionDebugText and entry.infectionDebugText ~= "" then
        Presentation.DrawOutlinedText(
            manager,
            entry.infectionDebugText,
            screenX - ((entry.infectionDebugTextWidth or 0) / 2),
            y,
            INFECTION_COLOR,
            alpha,
            Fonts.debug
        )
        y = y + lineHeight
    end
    if showAnimation
        and entry.animationDebugText
        and entry.animationDebugText ~= ""
    then
        Presentation.DrawOutlinedText(
            manager,
            entry.animationDebugText,
            screenX - ((entry.animationDebugTextWidth or 0) / 2),
            y,
            COMBAT_CONE_COLOR,
            alpha,
            Fonts.debug
        )
        y = y + lineHeight
    end
    if showScene
        and entry.sceneDebugText
        and entry.sceneDebugText ~= ""
    then
        Presentation.DrawOutlinedText(
            manager,
            entry.sceneDebugText,
            screenX - ((entry.sceneDebugTextWidth or 0) / 2),
            y,
            SCENE_COLOR,
            alpha,
            Fonts.debug
        )
        y = y + lineHeight
    end
    if showScene
        and entry.sceneTrackDebugText
        and entry.sceneTrackDebugText ~= ""
    then
        Presentation.DrawOutlinedText(
            manager,
            entry.sceneTrackDebugText,
            screenX
                - ((entry.sceneTrackDebugTextWidth or 0) / 2),
            y,
            SCENE_TRACK_COLOR,
            alpha,
            Fonts.debug
        )
        y = y + lineHeight
    end
    return y
end

local drawConversation

local function drawDebugOnly(manager, entry, metrics)
    local screenX = isoToScreenX(manager.playerIndex, entry.worldX, entry.worldY, entry.worldZ) - manager.x
    local screenY = isoToScreenY(manager.playerIndex, entry.worldX, entry.worldY, entry.worldZ) - manager.y
    local nameY = screenY - metrics.nameYOffset
    if RelationshipFeedbackRenderer
        and RelationshipFeedbackRenderer.Draw
        and scopeVisible(
            entry,
            Scopes.RELATIONSHIP_FEEDBACK,
            false
        )
    then
        RelationshipFeedbackRenderer.Draw(
            manager,
            entry.snapshot and entry.snapshot.id or entry.uuid,
            screenX,
            nameY,
            {
                currentTime = getTimeInMillis
                    and getTimeInMillis() or nil,
                nameWidth = entry.nameWidth,
                zoom = metrics.zoom,
                alpha = 0.9,
            }
        )
    end
    if scopeVisible(entry, Scopes.CONVERSATION, false) then
        drawConversation(manager, entry, screenX, nameY - Layout.speechGap, 0.9)
    end
    if scopeVisible(entry, Scopes.IDENTITY, true) then
        Presentation.DrawOutlinedText(
            manager,
            entry.name,
            screenX - ((entry.nameWidth or 0) / 2),
            nameY,
            entry.nameColor,
            0.9,
            Fonts.name
        )
    end
    if scopeVisible(entry, Scopes.DEBUG, true) then
        drawDebugText(manager, entry, screenX, nameY + Layout.nameDebugGap, 0.9)
    end
end

local function speechTextObject(entry, speechText)
    if not speechText or speechText == "" then
        entry.speechTextObjectKey = nil
        entry.speechTextObject = nil
        return nil
    end
    local color = Presentation.GetSpeechColor(entry.speech)
    local maxChars = Layout.speechMaxCharsPerLine
    local colorKey = tostring(color.r) .. ":" .. tostring(color.g)
        .. ":" .. tostring(color.b) .. ":" .. tostring(color.a)
    local cacheKey = tostring(speechText) .. "|"
        .. tostring(maxChars) .. "|" .. colorKey
    if entry.speechTextObjectKey == cacheKey and entry.speechTextObject then
        return entry.speechTextObject
    end
    entry.speechTextObjectKey = cacheKey
    entry.speechTextObject = Presentation.CreateSpeechTextObject(
        speechText,
        color,
        maxChars
    )
    return entry.speechTextObject
end

drawConversation = function(manager, entry, screenX, speechBottomY, alpha)
    if not scopeVisible(entry, Scopes.CONVERSATION, entry.speechVisible == true)
        or not entry.speechVisible
    then
        return 0
    end
    local speechText = entry.speechText
    local speechTextWidth = entry.speechTextWidth or 0
    if entry.speech and entry.speech.pending and Speech
        and Speech.GetDisplayText
    then
        speechText = Speech.GetDisplayText(entry.speech)
        speechTextWidth = getTextManager():MeasureStringX(
            Fonts.speech or Fonts.debug, speechText
        )
    end
    if not speechText or speechText == "" then return 0 end
    local actionHeight = getTextManager():getFontHeight(Fonts.debug) + 2
    local speechObject = speechTextObject(entry, speechText)
    local speechHeight = speechObject and speechObject:getHeight() or actionHeight
    local speechY = speechBottomY - speechHeight
    if speechObject then
        local speechColor = Presentation.GetSpeechColor(entry.speech)
        speechObject:Draw(
            screenX,
            speechY,
            true,
            alpha * speechColor.a
        )
    else
        Presentation.DrawOutlinedText(
            manager,
            speechText,
            screenX - (speechTextWidth / 2),
            speechY,
            Presentation.GetSpeechColor(entry.speech),
            alpha,
            Fonts.speech or Fonts.debug
        )
    end
    return speechHeight
end

local function drawLive(manager, entry, metrics, currentTime, settings)
    local zombie = entry.zombie
    if not zombie or zombie:isDead() then return end
    local alpha = zombie.getAlpha and zombie:getAlpha(manager.playerIndex) or 1
    if alpha <= 0 then return end

    local screenX = isoToScreenX(manager.playerIndex, zombie:getX(), zombie:getY(), zombie:getZ()) - manager.x
    local screenY = isoToScreenY(manager.playerIndex, zombie:getX(), zombie:getY(), zombie:getZ()) - manager.y
    local nameY = screenY - metrics.nameYOffset
    local barLeft = screenX - (metrics.barWidth / 2)
    local barTop = screenY - metrics.barYOffset
    local identityVisible = scopeVisible(entry, Scopes.IDENTITY, true)
    local debugVisible = scopeVisible(entry, Scopes.DEBUG, true)
    local conversationVisible = scopeVisible(
        entry,
        Scopes.CONVERSATION,
        entry.speechVisible == true
    )
    if entry.snapshot.healthState == "incapacitated" then
        entry.barColor = Presentation.IncapacitatedColor(currentTime)
    end

    local actionHeight = getTextManager():getFontHeight(Fonts.debug) + 2
    local actionY = nameY - actionHeight
    local actionVisible = identityVisible and entry.actionVisible
    local speechBottomY = actionVisible and (actionY - Layout.speechGap)
        or (nameY - Layout.speechGap)
    if conversationVisible then
        drawConversation(manager, entry, screenX, speechBottomY, 0.95 * alpha)
    end

    if actionVisible and entry.actionText ~= "" then
        Presentation.DrawOutlinedText(
            manager,
            entry.actionText,
            screenX - ((entry.actionTextWidth or 0) / 2),
            actionY,
            entry.actionColor,
            0.95 * alpha,
            Fonts.debug
        )
    end

    if identityVisible then
        Presentation.DrawOutlinedText(
            manager,
            entry.name,
            screenX - ((entry.nameWidth or 0) / 2),
            nameY,
            entry.nameColor,
            entry.nameColor.a * alpha,
            Fonts.name
        )
    end
    if RelationshipFeedbackRenderer
        and RelationshipFeedbackRenderer.Draw
        and scopeVisible(
            entry,
            Scopes.RELATIONSHIP_FEEDBACK,
            false
        )
    then
        RelationshipFeedbackRenderer.Draw(
            manager,
            entry.snapshot and entry.snapshot.id or entry.uuid,
            screenX,
            nameY,
            {
                currentTime = currentTime,
                nameWidth = entry.nameWidth,
                zoom = metrics.zoom,
                alpha = alpha,
            }
        )
    end
    local staminaTop
    if identityVisible then
        drawHealth(manager, entry, metrics, barLeft, barTop, alpha)
        staminaTop = drawStamina(manager, entry, metrics, barLeft, barTop, alpha)
    end

    local showDebug = settings.showAIDebug == true
    local showCamp = settings.showCampDebug == true
    local showAnimation = settings.showAnimationDebug == true
    local showScene =
        settings.showAnimationSceneDebug == true
    local showFaction = settings.showFactionDebug == true
    local showCommunity =
        settings.showCommunityDebug == true
    if debugVisible and (showDebug or showCamp or showAnimation or showScene
        or showFaction or showCommunity
    ) then
        local debugY
        if entry.staminaVisible then
            debugY = (entry.healthVisible and staminaTop or barTop) + metrics.barHeight + Layout.debugTextGap
        elseif entry.healthVisible then
            debugY = barTop + metrics.barHeight + Layout.debugTextGap
        else
            debugY = nameY + Layout.nameDebugGap
        end
        drawDebugText(
            manager,
            entry,
            screenX,
            debugY,
            0.95 * alpha,
            showAnimation,
            showScene
        )
    end
end

local function rounded(value, digits)
    local number = tonumber(value)
    local scale
    if number == nil then return nil end
    scale = 10 ^ (digits or 2)
    return tostring(math.floor(number * scale + 0.5) / scale)
end

function Renderer.BuildPathDebugLines(debugState, currentFinalDistance)
    local lines = {}
    local policy
    local provider
    local route
    local movement
    local diagnostic
    local pathIndex
    local pathLength
    local steeringIndex
    local goalDistance
    local finalDistance
    local turnDot
    local turnDegrees
    if type(debugState) ~= "table" then return lines end
    policy = tostring(debugState.navigationPolicy or "unknown")
    provider = tostring(debugState.navigationProvider or "unknown")
    route = tostring(
        debugState.navigationPlanReason
            or debugState.navigationSteeringKind
            or "direct"
    )
    pathIndex = tonumber(debugState.navigationPathIndex)
    steeringIndex = tonumber(
        debugState.navigationSteeringIndex
    )
    pathLength = tonumber(debugState.navigationPathLength) or 0
    if pathIndex and pathLength > 0 then
        route = route .. " wp=" .. tostring(pathIndex)
            .. "/" .. tostring(pathLength)
        if steeringIndex and steeringIndex ~= pathIndex then
            route = route .. " aim=" .. tostring(steeringIndex)
        end
    elseif debugState.navigationSteeringKind then
        route = route .. " " .. tostring(
            debugState.navigationSteeringKind
        )
    end
    if debugState.navigationTraversalKind then
        route = route .. " edge="
            .. tostring(debugState.navigationTraversalKind)
    end
    lines[#lines + 1] = "NAV " .. policy .. "/" .. provider
        .. " | " .. route

    goalDistance = rounded(debugState.moveGoalDistance, 2)
    finalDistance = rounded(
        currentFinalDistance or debugState.moveFinalDistance,
        2
    )
    movement = tostring(debugState.movePhase or "idle")
        .. "/" .. tostring(debugState.moveMode or "-")
        .. " step=" .. tostring(debugState.moveLastStep or "-")
    if goalDistance then movement = movement .. " goal=" .. goalDistance end
    if finalDistance then movement = movement .. " final=" .. finalDistance end
    movement = movement .. " np="
        .. tostring(tonumber(debugState.moveNonProgressSteps) or 0)
    if (tonumber(debugState.moveRetargetCount) or 0) > 0 then
        movement = movement .. " rt="
            .. tostring(tonumber(debugState.moveRetargetCount) or 0)
    end
    turnDot = tonumber(debugState.moveSteeringTurnDot)
    if turnDot then
        turnDot = math.max(-1, math.min(1, turnDot))
        turnDegrees = math.floor(
            math.deg(math.acos(turnDot)) + 0.5
        )
        movement = movement .. " turn="
            .. tostring(turnDegrees)
    end
    lines[#lines + 1] = movement

    if debugState.moveBlockReason
        or debugState.moveBlockedStepReason
        or (tonumber(debugState.navigationPlanFailures) or 0) > 0
        or debugState.navigationInvalidationReason
    then
        diagnostic = "DIAG block="
            .. tostring(
                debugState.moveBlockReason
                    or debugState.moveBlockedStepReason
                    or "-"
            )
            .. " failures="
            .. tostring(
                tonumber(debugState.navigationPlanFailures) or 0
            )
        if debugState.navigationInvalidationReason then
            diagnostic = diagnostic .. " replan="
                .. tostring(debugState.navigationInvalidationReason)
        end
        lines[#lines + 1] = diagnostic
    end
    return lines
end

function Renderer.BuildCombatDebugLines(debugState, currentTargetDistance)
    local lines = {}
    local mode
    local decision
    local pressure
    local horde
    local target
    local targetLine
    local aim
    local lane
    local ammo
    local action
    local movement
    if type(debugState) ~= "table" then return lines end
    mode = tostring(debugState.mode or "unknown")
    decision = tostring(
        debugState.decision
            or debugState.blockReason
            or "observing"
    )
    lines[#lines + 1] = "COMBAT " .. mode
        .. " | " .. decision
        .. (
            debugState.assessmentAgeMs ~= nil
                and " age=" .. tostring(
                    math.floor(
                        tonumber(debugState.assessmentAgeMs) or 0
                    )
                ) .. "ms"
                or ""
        )

    pressure = tostring(
        tonumber(debugState.visiblePressureCount) or 0
    ) .. "/" .. tostring(
        tonumber(debugState.pressureCount) or 0
    )
    horde = tostring(
        tonumber(debugState.visibleHordeCount) or 0
    ) .. "/" .. tostring(
        tonumber(debugState.hordeCount) or 0
    )
    lines[#lines + 1] = "THREAT near="
        .. tostring(tonumber(debugState.surroundedCount) or 0)
        .. " pressure=" .. pressure
        .. " tol=" .. tostring(
            tonumber(debugState.pressureTolerance) or "-"
        )
        .. " horde=" .. horde
        .. " crowd=" .. tostring(
            tonumber(debugState.targetCrowdCount) or 0
        )
        .. " sta=" .. tostring(
            debugState.staminaRatio ~= nil
                and math.floor(
                    (tonumber(debugState.staminaRatio) or 0)
                        * 100 + 0.5
                ) .. "%"
                or "-"
        )
        .. "/" .. tostring(
            debugState.staminaCurrent ~= nil
                and math.floor(
                    tonumber(debugState.staminaCurrent) or 0
                )
                or "-"
        )

    if debugState.visibleZombieCount ~= nil
        or debugState.nearbyZombieCount ~= nil
    then
        lines[#lines + 1] = "VIEW zombies="
            .. tostring(
                tonumber(debugState.visibleZombieCount) or 0
            )
            .. "/" .. tostring(
                tonumber(debugState.nearbyZombieCount) or 0
            )
            .. " intent=" .. tostring(
                debugState.attackType or "auto"
            )
            .. " tactical=" .. tostring(
                debugState.tacticalState or "-"
            )
            .. " retreat=" .. tostring(
                debugState.retreatPhase or "-"
            )
            .. ":" .. tostring(
                debugState.retreatReason or "-"
            )
            .. " biteLane=" .. tostring(
                debugState.biteLaneClear == true
                    and "clear"
                    or debugState.biteLaneReason or "-"
            )
    end
    if type(debugState.viewZombies) == "table" then
        local index
        local viewed
        for index = 1, #debugState.viewZombies do
            viewed = debugState.viewZombies[index]
            lines[#lines + 1] = "Z" .. tostring(index)
                .. " id=" .. tostring(viewed.id or "-")
                .. " d=" .. tostring(
                    rounded(
                        viewed.distSq
                            and math.sqrt(
                                tonumber(viewed.distSq) or 0
                            ),
                        2
                    ) or "-"
                )
                .. " mode=" .. tostring(viewed.intent or "visible")
                .. " state=" .. tostring(
                    viewed.actionState or "-"
                )
                .. " los=" .. tostring(
                    viewed.visibilityKind or "-"
                )
                .. (
                    tostring(viewed.bumpType or "") ~= ""
                        and " bump=" .. tostring(viewed.bumpType)
                        or ""
                )
                .. (
                    viewed.targetKind ~= nil
                        and " target="
                            .. tostring(viewed.targetKind)
                            .. "["
                            .. tostring(
                                viewed.targetName
                                    or viewed.targetId
                                    or "?"
                            )
                            .. "]"
                            .. (
                                viewed.targetSource ~= nil
                                    and " via="
                                        .. tostring(viewed.targetSource)
                                    or ""
                            )
                        or " target=none"
                )
        end
    end

    target = debugState.target
    if type(target) == "table" then
        targetLine = "TARGET " .. tostring(target.kind or "unknown")
            .. (
                target.id ~= nil
                    and "[" .. tostring(target.id) .. "]"
                    or ""
            )
            .. " d=" .. tostring(
                rounded(
                    currentTargetDistance
                        or (
                            target.distSq
                            and math.sqrt(
                                tonumber(target.distSq) or 0
                            )
                        ),
                    2
                ) or "-"
            )
            .. " los=" .. tostring(
                target.visible == false
                    and (target.visibilityKind or "lost")
                    or (target.visibilityKind or "clear")
            )
        if target.threatening == true then
            targetLine = targetLine .. " ACTIVE"
        end
        lines[#lines + 1] = targetLine
    else
        lines[#lines + 1] = "TARGET none"
    end

    if mode == "ranged" or mode == "mixed" then
        aim = tonumber(debugState.aimConfidence)
        if debugState.fireLaneSafe == false then
            lane = "BLOCKED"
            if debugState.fireLaneBlocker then
                lane = lane .. ":"
                    .. tostring(
                        debugState.fireLaneBlocker.kind or "friendly"
                    )
            end
        elseif debugState.fireLaneSafe == true then
            lane = "CLEAR"
        else
            lane = "UNCHECKED"
        end
        ammo = debugState.magazineCount ~= nil
            and (
                tostring(debugState.magazineCount)
                .. "/" .. tostring(
                    debugState.magazineCapacity or "?"
                )
            ) or "-"
        lines[#lines + 1] = "RANGED aim="
            .. tostring(
                aim and math.floor(aim * 100 + 0.5) or "-"
            )
            .. "% ready="
            .. tostring(
                debugState.aimReadyInMs ~= nil
                    and tostring(
                        math.floor(
                            tonumber(debugState.aimReadyInMs) or 0
                        )
                    ) .. "ms"
                    or "-"
            )
            .. " lane=" .. lane
            .. " ammo=" .. ammo
            .. " reserve=" .. tostring(
                debugState.ammoReserveUnlimited == true
                    and "inf"
                    or debugState.ammoReserveCount or "-"
            )
            .. (
                debugState.reloadActive == true
                    and " RELOAD"
                    or ""
            )
    end

    action = debugState.action
    if type(action) == "table" then
        lines[#lines + 1] = "ACTION "
            .. tostring(action.attackType or "-")
            .. "/" .. tostring(action.attackKind or "-")
            .. " anim=" .. tostring(action.anim or "-")
            .. " retry=" .. tostring(
                tonumber(action.animationRetries) or 0
            )
            .. " via=" .. tostring(
                action.animationTriggerMode or "-"
            )
            .. " state=" .. tostring(
                action.animationActionState or "-"
            )
            .. " hit=" .. tostring(
                math.floor(
                    tonumber(action.hitRemainingMs) or 0
                )
            )
            .. "ms finish=" .. tostring(
                math.floor(
                    tonumber(action.finishRemainingMs) or 0
                )
            ) .. "ms"
    end

    movement = debugState.tacticalMove
    if type(movement) == "table" then
        lines[#lines + 1] = "MOVE "
            .. tostring(movement.phase or "-")
            .. "/" .. tostring(movement.mode or "-")
            .. " reason=" .. tostring(movement.reason or "-")
            .. " lock=" .. tostring(
                math.floor(
                    tonumber(movement.lockRemainingMs) or 0
                )
            ) .. "ms"
    end
    lines[#lines + 1] = "DEFENSE r="
        .. tostring(rounded(debugState.defenseRadius, 1) or "-")
        .. " nearby=" .. tostring(
            tonumber(debugState.defenseNearbyCount) or 0
        )
        .. " fit=" .. tostring(
            debugState.defenseFitness ~= nil
                and math.floor(tonumber(debugState.defenseFitness) or 0)
                or "-"
        )
        .. " dodge=" .. tostring(
            debugState.defenseAvoidChance ~= nil
                and math.floor(
                    (tonumber(debugState.defenseAvoidChance) or 0)
                        * 100 + 0.5
                ) .. "%"
                or "-"
        )
        .. " gear=" .. tostring(
            debugState.defenseProtection ~= nil
                and math.floor(
                    (tonumber(debugState.defenseProtection) or 0)
                        + 0.5
                ) .. "%"
                or "-"
        )
        .. " type=" .. tostring(debugState.defenseDamageType or "-")
        .. " last=" .. tostring(debugState.defenseOutcome or "-")
        .. (debugState.defensePushed == true and "+push" or "")
    return lines
end

function Renderer.BuildBodyAnimationDebugLine(zombie, action)
    local modData
    local actionState
    local bumpType
    local requested
    local useless
    local moving
    local sneaking
    local finished
    if not zombie then return nil end
    modData = zombie.getModData and zombie:getModData() or nil
    actionState = zombie.getActionStateName
        and tostring(zombie:getActionStateName() or "")
        or "-"
    bumpType = zombie.getBumpType
        and tostring(zombie:getBumpType() or "")
        or "-"
    requested = modData
        and modData.PNC_ClientAttackRequestedAnim
        or action and action.anim
        or "-"
    useless = zombie.isUseless
        and zombie:isUseless() == true or false
    moving = zombie.isMoving
        and zombie:isMoving() == true or false
    sneaking = zombie.isSneaking
        and zombie:isSneaking() == true or false
    finished = zombie.getVariableBoolean
        and zombie:getVariableBoolean("BumpAnimFinished")
        == true or false
    return "ANIM req=" .. tostring(requested)
        .. " bump=" .. tostring(bumpType ~= "" and bumpType or "-")
        .. " state=" .. tostring(actionState ~= "" and actionState or "-")
        .. " useless=" .. tostring(useless)
        .. " moving=" .. tostring(moving)
        .. " sneak=" .. tostring(sneaking)
        .. " done=" .. tostring(finished)
        .. " lease=" .. tostring(
            modData and modData.PNC_BumpActionLease == true
                or false
        )
end

function Renderer.BuildAnimationTraceDebugLine(zombie)
    if not PNC.AnimationTrace
        or not PNC.AnimationTrace.GetOverlayLine
    then
        return nil
    end
    return PNC.AnimationTrace.GetOverlayLine(zombie)
end

function Renderer.BuildAnimationTrackDebugLine(zombie)
    if not NameplateDebug
        or not NameplateDebug.AnimationTrackText
    then
        return nil
    end
    return NameplateDebug.AnimationTrackText(zombie)
end

local function screenPoint(manager, x, y, z)
    return isoToScreenX(manager.playerIndex, x, y, z) - manager.x,
        isoToScreenY(manager.playerIndex, x, y, z) - manager.y
end

local function drawWorldLine(manager, x1, y1, z1, x2, y2, z2, color)
    local sx1
    local sy1
    local sx2
    local sy2
    sx1, sy1 = screenPoint(manager, x1, y1, z1)
    sx2, sy2 = screenPoint(manager, x2, y2, z2)
    manager:drawLine2(
        sx1,
        sy1,
        sx2,
        sy2,
        color.a,
        color.r,
        color.g,
        color.b
    )
end

local function drawWorldMarker(manager, x, y, z, color, size)
    local sx
    local sy
    size = tonumber(size) or COMBAT_MARKER_HALF_SIZE
    sx, sy = screenPoint(manager, x, y, z)
    manager:drawLine2(
        sx - size,
        sy,
        sx + size,
        sy,
        color.a,
        color.r,
        color.g,
        color.b
    )
    manager:drawLine2(
        sx,
        sy - size,
        sx,
        sy + size,
        color.a,
        color.r,
        color.g,
        color.b
    )
end

local function drawWorldTile(manager, x, y, z, color)
    x = math.floor(tonumber(x) or 0)
    y = math.floor(tonumber(y) or 0)
    z = tonumber(z) or 0
    drawWorldLine(manager, x, y, z, x + 1, y, z, color)
    drawWorldLine(manager, x + 1, y, z, x + 1, y + 1, z, color)
    drawWorldLine(manager, x + 1, y + 1, z, x, y + 1, z, color)
    drawWorldLine(manager, x, y + 1, z, x, y, z, color)
    if type(addAreaHighlightForPlayer) == "function" then
        addAreaHighlightForPlayer(
            manager.playerIndex,
            x, y, x + 1, y + 1, z,
            color.r, color.g, color.b, color.a
        )
    end
end

local function campResourcePoint(resource)
    local x = tonumber(resource and resource.x)
    local y = tonumber(resource and resource.y)
    local z = tonumber(resource and resource.z)
    if x == nil and resource and resource.originX ~= nil then
        x = tonumber(resource.originX) + 0.5
    end
    if y == nil and resource and resource.originY ~= nil then
        y = tonumber(resource.originY) + 0.5
    end
    if z == nil and resource then z = tonumber(resource.originZ) end
    if x == nil or y == nil or z == nil then return nil end
    return x, y, z
end

local function campResourceTile(resource)
    local x = tonumber(resource and resource.originX)
    local y = tonumber(resource and resource.originY)
    local z = tonumber(resource and resource.originZ)
    if x == nil or y == nil then
        local pointX, pointY, pointZ = campResourcePoint(resource)
        if pointX == nil then return nil end
        x, y, z = math.floor(pointX), math.floor(pointY), pointZ
    end
    return math.floor(x), math.floor(y), tonumber(z) or 0
end

local function campResourceColor(resource)
    if resource and resource.available == false then
        return CAMP_RESOURCE_BLOCKED_COLOR
    end
    if resource and resource.selected == true then
        return CAMP_RESOURCE_SELECTED_COLOR
    end
    return CAMP_RESOURCE_COLORS[tostring(resource and resource.category or "other")]
        or CAMP_RESOURCE_COLORS.other
end

local function hoveredWorldPoint(manager, x, y, z)
    if type(getMouseX) ~= "function" or type(getMouseY) ~= "function"
        or not isoToScreenX or not isoToScreenY
    then return nil end
    local mouseX = getMouseX() - (tonumber(manager.x) or 0)
    local mouseY = getMouseY() - (tonumber(manager.y) or 0)
    local screenX = isoToScreenX(manager.playerIndex, x, y, z)
        - (tonumber(manager.x) or 0)
    local screenY = isoToScreenY(manager.playerIndex, x, y, z)
        - (tonumber(manager.y) or 0)
    local xStep = math.abs(isoToScreenX(manager.playerIndex, x + 1, y, z)
        - isoToScreenX(manager.playerIndex, x, y, z))
    local yStep = math.abs(isoToScreenX(manager.playerIndex, x, y + 1, z)
        - isoToScreenX(manager.playerIndex, x, y, z))
    local size = math.max(16, 2 * math.max(xStep, yStep))
    local dx = mouseX - screenX
    local dy = mouseY - screenY
    if math.abs(dx) <= math.max(12, size / 2)
        and math.abs(dy) <= math.max(12, size / 2)
    then
        return dx * dx + dy * dy
    end
    return nil
end

local function updateCampResourceHover(manager, resource, hoverState)
    local x, y, z = campResourcePoint(resource)
    if not x then return end
    local distance = hoveredWorldPoint(manager, x, y, z)
    if distance and (not hoverState.distance or distance < hoverState.distance) then
        hoverState.resource = resource
        hoverState.distance = distance
    end
end

local function campResourceJobsText(resource)
    local jobs = resource and resource.supportedJobs or nil
    if type(jobs) == "table" and #jobs > 0 then
        local labels = {}
        for index = 1, #jobs do labels[#labels + 1] = tostring(jobs[index]) end
        return table.concat(labels, ", ")
    end
    return tostring(resource and (resource.capability
        or resource.role or resource.resourceKind) or "unknown")
end

local function drawCampResourceHover(manager, resource)
    if not resource or type(getMouseX) ~= "function"
        or type(getMouseY) ~= "function" or not manager.drawText
    then return end
    local category = tostring(resource.category or "other")
    local state = resource.blocked == true and "BLOCKED"
        or resource.available == false and "RESERVED" or "AVAILABLE"
    local lines = {
        "CAMP RESOURCE: " .. category,
        "jobs: " .. campResourceJobsText(resource),
        "state: " .. state,
        "key: " .. tostring(resource.resourceKey or "-"),
    }
    local width = 190
    for index = 1, #lines do
        width = math.max(width, #lines[index] * 7 + 18)
    end
    local height = #lines * 18 + 10
    local x = getMouseX() - (tonumber(manager.x) or 0) + 14
    local y = getMouseY() - (tonumber(manager.y) or 0) + 14
    local managerWidth = tonumber(manager.width) or 1920
    local managerHeight = tonumber(manager.height) or 1080
    if x + width > managerWidth then x = managerWidth - width - 4 end
    if y + height > managerHeight then y = managerHeight - height - 4 end
    x, y = math.max(4, x), math.max(4, y)
    manager:drawRect(x, y, width, height, 0.88, 0.02, 0.05, 0.07)
    manager:drawRectBorder(x, y, width, height, 0.96,
        CAMP_RESOURCE_TILE_COLOR.r,
        CAMP_RESOURCE_TILE_COLOR.g,
        CAMP_RESOURCE_TILE_COLOR.b)
    for index = 1, #lines do
        manager:drawText(lines[index], x + 8, y + 5 + ((index - 1) * 18),
            1, 1, 1, 1, UIFont and UIFont.Small)
    end
end

local drawWorldCircle

local function campDebugKey(camp)
    if tostring(camp and camp.campId or "") ~= "" then
        return tostring(camp.campId)
    end
    local anchor = camp and camp.anchor or {}
    return tostring(anchor.x or "?") .. ":" .. tostring(anchor.y or "?")
        .. ":" .. tostring(anchor.z or "?")
end

local function drawCampResourceDebug(manager, entry, hoverState, drawnCamps)
    local camp = entry.snapshot and (
        entry.snapshot.campResourceDebug
            or entry.snapshot.debugState
            and entry.snapshot.debugState.campResourceDebug
    )
    if type(camp) ~= "table" then return end
    local anchor = camp.anchor
    local campKey = campDebugKey(camp)
    drawnCamps = drawnCamps or {}
    if camp.active == true and type(anchor) == "table"
        and anchor.x and anchor.y and anchor.z
        and not drawnCamps[campKey]
    then
        drawnCamps[campKey] = true
        drawWorldCircle(
            manager,
            anchor.x,
            anchor.y,
            anchor.z,
            camp.campRadius or 3,
            CAMP_RADIUS_COLOR,
            false
        )
        if tonumber(camp.resourceRadius)
            and tonumber(camp.resourceRadius) > tonumber(camp.campRadius or 3)
        then
            drawWorldCircle(
                manager,
                anchor.x,
                anchor.y,
                anchor.z,
                camp.resourceRadius,
                CAMP_RESOURCE_RADIUS_COLOR,
                true
            )
        end
    end
    for index = 1, #(camp.facilities or {}) do
        local resource = camp.facilities[index]
        if type(resource) == "table" then
            local color = campResourceColor(resource)
            local tileX, tileY, tileZ = campResourceTile(resource)
            if tileX ~= nil then
                drawWorldTile(manager, tileX, tileY, tileZ, color)
            end
            local x, y, z = campResourcePoint(resource)
            if x ~= nil then
                drawWorldMarker(manager, x, y, z, color,
                    resource.selected == true and 10 or 6)
                updateCampResourceHover(manager, resource, hoverState)
            end
        end
    end
end

drawWorldCircle = function(
    manager,
    centerX,
    centerY,
    z,
    radius,
    color,
    dashed,
    segmentsOverride
)
    local segments = math.max(
        8,
        math.floor(tonumber(segmentsOverride) or 28)
    )
    local previousX
    local previousY
    local x
    local y
    local angle
    local i
    radius = tonumber(radius)
    if not radius or radius <= 0 then return end
    for i = 0, segments do
        angle = (i / segments) * math.pi * 2
        x = centerX + math.cos(angle) * radius
        y = centerY + math.sin(angle) * radius
        if previousX ~= nil
            and (not dashed or i % 2 == 0)
        then
            drawWorldLine(
                manager,
                previousX,
                previousY,
                z,
                x,
                y,
                z,
                color
            )
        end
        previousX = x
        previousY = y
    end
end

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

local function drawPathGoal(manager, entry)
    local zombie = entry.zombie
    local debugState = entry.snapshot and (
        entry.snapshot.pathDebugState
            or entry.snapshot.debugState
    )
    local goal = debugState and debugState.moveGoal
    if not zombie or zombie:isDead() or type(goal) ~= "table" then return end

    local goalX = tonumber(goal.x)
    local goalY = tonumber(goal.y)
    local goalZ = tonumber(goal.z)
    if not goalX or not goalY or not goalZ then return end

    local worldX = zombie:getX()
    local worldY = zombie:getY()
    local worldZ = zombie:getZ()
    local startX = isoToScreenX(manager.playerIndex, worldX, worldY, worldZ) - manager.x
    local startY = isoToScreenY(manager.playerIndex, worldX, worldY, worldZ) - manager.y
    local endX = isoToScreenX(manager.playerIndex, goalX, goalY, goalZ) - manager.x
    local endY = isoToScreenY(manager.playerIndex, goalX, goalY, goalZ) - manager.y
    local color = debugState.moveBlockReason and PATH_BLOCKED_COLOR or PATH_COLOR
    local finalGoal = debugState.moveFinalGoal
    local finalX = finalGoal and tonumber(finalGoal.x) or nil
    local finalY = finalGoal and tonumber(finalGoal.y) or nil
    local finalZ = finalGoal and tonumber(finalGoal.z) or nil
    local finalScreenX
    local finalScreenY
    local lines
    local lineHeight
    local labelX
    local labelY
    local textWidth
    local textColor
    local currentFinalDistance
    local i

    if finalX and finalY and finalZ then
        currentFinalDistance = math.sqrt(
            ((finalX - worldX) * (finalX - worldX))
                + ((finalY - worldY) * (finalY - worldY))
        )
    end

    manager:drawLine2(startX, startY, endX, endY, color.a, color.r, color.g, color.b)
    manager:drawLine2(
        endX - PATH_MARKER_HALF_SIZE,
        endY,
        endX + PATH_MARKER_HALF_SIZE,
        endY,
        color.a,
        color.r,
        color.g,
        color.b
    )
    manager:drawLine2(
        endX,
        endY - PATH_MARKER_HALF_SIZE,
        endX,
        endY + PATH_MARKER_HALF_SIZE,
        color.a,
        color.r,
        color.g,
        color.b
    )
    if finalX and finalY and finalZ
        and (
            math.abs(finalX - goalX) > 0.05
            or math.abs(finalY - goalY) > 0.05
            or math.abs(finalZ - goalZ) > 0.05
        )
    then
        finalScreenX = isoToScreenX(
            manager.playerIndex,
            finalX,
            finalY,
            finalZ
        ) - manager.x
        finalScreenY = isoToScreenY(
            manager.playerIndex,
            finalX,
            finalY,
            finalZ
        ) - manager.y
        manager:drawLine2(
            endX,
            endY,
            finalScreenX,
            finalScreenY,
            PATH_FINAL_COLOR.a,
            PATH_FINAL_COLOR.r,
            PATH_FINAL_COLOR.g,
            PATH_FINAL_COLOR.b
        )
        manager:drawLine2(
            finalScreenX - PATH_FINAL_MARKER_HALF_SIZE,
            finalScreenY,
            finalScreenX + PATH_FINAL_MARKER_HALF_SIZE,
            finalScreenY,
            PATH_FINAL_COLOR.a,
            PATH_FINAL_COLOR.r,
            PATH_FINAL_COLOR.g,
            PATH_FINAL_COLOR.b
        )
        manager:drawLine2(
            finalScreenX,
            finalScreenY - PATH_FINAL_MARKER_HALF_SIZE,
            finalScreenX,
            finalScreenY + PATH_FINAL_MARKER_HALF_SIZE,
            PATH_FINAL_COLOR.a,
            PATH_FINAL_COLOR.r,
            PATH_FINAL_COLOR.g,
            PATH_FINAL_COLOR.b
        )
    end

    lines = Renderer.BuildPathDebugLines(
        debugState,
        currentFinalDistance
    )
    lineHeight = getTextManager():getFontHeight(Fonts.debug) + 2
    labelX = (startX + endX) / 2
    labelY = math.min(startY, endY)
        - (#lines * lineHeight)
        - 4
    textColor = debugState.moveBlockReason
        and PATH_BLOCKED_COLOR or PATH_COLOR
    for i = 1, #lines do
        textWidth = getTextManager():MeasureStringX(
            Fonts.debug,
            lines[i]
        )
        Presentation.DrawOutlinedText(
            manager,
            lines[i],
            labelX - (textWidth / 2),
            labelY + ((i - 1) * lineHeight),
            textColor,
            1,
            Fonts.debug
        )
    end
end

local function drawSeatingDebug(manager, entry)
    local seating = entry.snapshot and (
        entry.snapshot.seatingDebug
            or entry.snapshot.debugState
            and entry.snapshot.debugState.seatingDebug
    )
    if type(seating) ~= "table" then return end
    local facilities = seating.facilities or {}
    for facilityIndex = 1, #facilities do
        local facility = facilities[facilityIndex]
        if type(facility) == "table" then
            local resourceColor = facility.selected == true
                and SEATING_SELECTED_COLOR or facility.available == false
                and SEATING_BLOCKED_COLOR or SEATING_COLOR
            if facility.x and facility.y and facility.z then
                drawWorldMarker(
                    manager,
                    facility.x,
                    facility.y,
                    facility.z,
                    resourceColor,
                    facility.selected == true and 11 or 7
                )
            end
            if facility.originX and facility.originY and facility.originZ then
                -- The resource tile and the SeatingManager anchor are
                -- different things. Draw both for unambiguous diagnostics.
                drawWorldTile(
                    manager,
                    facility.originX,
                    facility.originY,
                    facility.originZ,
                    SEATING_TILE_COLOR
                )
            end
            for spotIndex = 1, #(facility.spots or {}) do
                local spot = facility.spots[spotIndex]
                if type(spot) == "table" and spot.x and spot.y and spot.z then
                    local color = spot.valid == false
                        and SEATING_BLOCKED_COLOR
                        or spot.selected == true
                        and SEATING_SELECTED_COLOR
                        or SEATING_SPOT_COLOR
                    drawWorldTile(manager, spot.x, spot.y, spot.z, color)
                    -- Tile outlines are deliberately aligned to integer tile
                    -- coordinates; this point is the actual sub-tile anchor.
                    drawWorldMarker(manager, spot.x, spot.y, spot.z, color,
                        spot.selected == true and 8 or 4)
                    if facility.x and facility.y and facility.z then
                        drawWorldLine(
                            manager,
                            facility.x,
                            facility.y,
                            facility.z,
                            spot.x,
                            spot.y,
                            spot.z,
                            SEATING_TILE_COLOR
                        )
                    end
                end
            end
        end
    end
    local target = seating.target
    if type(target) == "table" and target.x and target.y and target.z then
        drawWorldMarker(
            manager,
            target.x,
            target.y,
            target.z,
            SEATING_SELECTED_COLOR,
            14
        )
    end
    if type(seating.body) == "table"
        and seating.body.x and seating.body.y and seating.body.z
    then
        drawWorldMarker(
            manager,
            seating.body.x,
            seating.body.y,
            seating.body.z,
            SEATING_BLOCKED_COLOR,
            9
        )
        if type(target) == "table" and target.x and target.y and target.z then
            drawWorldLine(
                manager,
                seating.body.x,
                seating.body.y,
                seating.body.z,
                target.x,
                target.y,
                target.z,
                SEATING_BLOCKED_COLOR
            )
        end
    end
    if type(seating.anchor) == "table"
        and seating.anchor.x and seating.anchor.y and seating.anchor.z
    then
        drawWorldMarker(
            manager,
            seating.anchor.x,
            seating.anchor.y,
            seating.anchor.z,
            SEATING_SELECTED_COLOR,
            10
        )
    end
end

Renderer.RenderSeatingDebug = drawSeatingDebug
Renderer.RenderCampResourceDebug = drawCampResourceDebug
Renderer.DrawCampResourceHover = drawCampResourceHover

function Renderer.Render(manager, settings)
    if Diagnostics then
        Diagnostics.Increment("UI.NameplateRenderCalls")
    end
    if not settings.enabled or not manager.player then
        manager:clearStencilRect()
        return
    end

    local metrics = Presentation.ScaleFor(manager.playerIndex)
    local currentTime = getTimeInMillis()
    local campHover = settings.showCampDebug
        and { distance = nil, resource = nil } or nil
    local drawnCamps = {}
    if Diagnostics then
        local entryCount = 0
        for _, _ in pairs(manager.entries) do entryCount = entryCount + 1 end
        Diagnostics.Increment("UI.NameplateEntriesRendered", entryCount)
    end
    if settings.showPathDebug then
        for _, entry in pairs(manager.entries) do
            if not entry.debugOnly
                and scopeVisible(entry, Scopes.DEBUG, true)
            then
                drawPathGoal(manager, entry)
            end
        end
    end
    if settings.showCombatDebug then
        for _, entry in pairs(manager.entries) do
            if not entry.debugOnly
                and scopeVisible(entry, Scopes.DEBUG, true)
            then
                drawCombatDebug(manager, entry)
            end
        end
    end
    if settings.showAIDebug or settings.showCampDebug then
        for _, entry in pairs(manager.entries) do
            if not entry.debugOnly
                and scopeVisible(entry, Scopes.DEBUG, true)
            then
                drawSeatingDebug(manager, entry)
                if campHover then
                    drawCampResourceDebug(
                        manager, entry, campHover, drawnCamps)
                end
            end
        end
    end
    if campHover and campHover.resource then
        drawCampResourceHover(manager, campHover.resource)
    end
    for _, entry in pairs(manager.entries) do
        if entry.debugOnly then
            drawDebugOnly(manager, entry, metrics)
        else
            drawLive(manager, entry, metrics, currentTime, settings)
        end
    end
    manager:clearStencilRect()
end

return Renderer
