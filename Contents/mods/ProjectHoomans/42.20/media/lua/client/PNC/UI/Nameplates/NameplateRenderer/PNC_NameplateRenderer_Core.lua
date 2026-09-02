local Renderer = PNC.NameplateRenderer
local Internal = Renderer.Internal
local Diagnostics = PNC.PerformanceScalingDiagnostics
local Presentation = PNC.NameplatePresentation
local Speech = PNC.NameplateSpeech
local RelationshipFeedbackRenderer =
    PNC.NameplateRelationshipFeedbackRenderer
local DisplaySettings = PNC.NameplateDisplaySettings
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

local scopeVisible = Internal.ScopeVisible

local function nameplateFont()
    if DisplaySettings and DisplaySettings.GetNameplateFont then
        return DisplaySettings.GetNameplateFont()
    end
    return Fonts.name
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
    local barGap = metrics.barGap or (6 / metrics.zoom)
    local top = entry.healthVisible
        and (barTop + metrics.barHeight + barGap) or barTop
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
            nameplateFont()
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
            nameplateFont()
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

Internal.DrawDebugOnly = drawDebugOnly
Internal.DrawLive = drawLive

return Renderer
