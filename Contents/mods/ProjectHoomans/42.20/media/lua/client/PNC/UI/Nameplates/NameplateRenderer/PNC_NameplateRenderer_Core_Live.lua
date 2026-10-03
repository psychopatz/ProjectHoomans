local Renderer = PNC.NameplateRenderer
local Internal = Renderer.Internal
local Diagnostics = PNC.PerformanceScalingDiagnostics
local Presentation = PNC.NameplatePresentation
local Speech = PNC.NameplateSpeech
local RelationshipFeedbackRenderer =
    PNC.NameplateRelationshipFeedbackRenderer
local ToolFeedbackRenderer = PNC.NameplateToolFeedbackRenderer
local Scopes = PNC.NameplateScopes
local Layout = Presentation.Layout
local Fonts = Presentation.Fonts
local FirearmAnchor = PNC.NameplateFirearmAnchor
local scopeVisible = Internal.ScopeVisible
local nameplateFont = Internal.NameplateFont
local drawHealth = Internal.DrawHealth
local drawStamina = Internal.DrawStamina
local drawDebugText = Internal.DrawDebugText
local drawConversation = Internal.DrawConversation

local function updateLiveAnchor(manager, entry, zombie, metrics, screenX, screenY, nameY)
    if FirearmAnchor and FirearmAnchor.Update then
        FirearmAnchor.Update(
            zombie,
            entry.uuid or entry.snapshot and entry.snapshot.id,
            manager.playerIndex,
            manager.x,
            manager.y,
            metrics.zoom,
            screenX,
            nameY,
            screenX,
            screenY,
            zombie:getX(),
            zombie:getY(),
            zombie:getZ()
        )
    end
    if FirearmAnchor and FirearmAnchor.Render then
        FirearmAnchor.Render(
            manager,
            zombie,
            entry.uuid or entry.snapshot and entry.snapshot.id,
            screenX,
            nameY,
            screenX,
            screenY,
            zombie:getX(),
            zombie:getY(),
            zombie:getZ()
        )
    end
end

local function drawLiveStatus(manager, entry, metrics, screenX, nameY, alpha, currentTime,
    identityVisible, conversationVisible)
    local actionHeight = getTextManager():getFontHeight(Fonts.debug) + 2
    local toolFeedbackVisible = scopeVisible(
        entry,
        Scopes.TOOL_FEEDBACK,
        false
    ) and entry.toolFeedbackVisible == true
    local toolFeedbackHeight = getTextManager():getFontHeight(Fonts.debug) + 2
    local toolFeedbackY = nameY - toolFeedbackHeight
    local actionY = toolFeedbackVisible
        and (toolFeedbackY - Layout.speechGap - actionHeight)
        or (nameY - actionHeight)
    local actionVisible = identityVisible and entry.actionVisible
    local recoveryVisible = identityVisible
        and entry.recoveryVisible == true
    local statusVisible = recoveryVisible or actionVisible
    local statusText = recoveryVisible and entry.recoveryText
        or entry.actionText or ''
    local statusColor = recoveryVisible and entry.recoveryColor
        or entry.actionColor
    local statusWidth = recoveryVisible and entry.recoveryTextWidth
        or entry.actionTextWidth
    local speechBottomY = statusVisible and (actionY - Layout.speechGap)
        or toolFeedbackVisible and (toolFeedbackY - Layout.speechGap)
        or (nameY - Layout.speechGap)
    if conversationVisible then
        drawConversation(manager, entry, screenX, speechBottomY, 0.95 * alpha)
    end
    if statusVisible and statusText ~= '' then
        Presentation.DrawOutlinedText(
            manager,
            statusText,
            screenX - ((statusWidth or 0) / 2),
            actionY,
            statusColor,
            0.95 * alpha,
            Fonts.debug
        )
    end
    if toolFeedbackVisible and ToolFeedbackRenderer
        and ToolFeedbackRenderer.Draw
    then
        ToolFeedbackRenderer.Draw(
            manager,
            entry.snapshot and entry.snapshot.id or entry.uuid,
            screenX,
            nameY,
            {
                currentTime = currentTime,
                textWidth = entry.toolFeedbackTextWidth,
                y = toolFeedbackY,
                zoom = metrics.zoom,
                alpha = alpha,
            }
        )
    end
    return {
        statusVisible = statusVisible,
        toolFeedbackVisible = toolFeedbackVisible,
        toolFeedbackY = toolFeedbackY,
        actionY = actionY,
        speechBottomY = speechBottomY,
    }
end

local function drawLiveIdentity(manager, entry, metrics, screenX, nameY,
    alpha, identityVisible, barLeft, barTop, currentTime)
    if not identityVisible then return nil end
    Presentation.DrawOutlinedText(
        manager,
        entry.name,
        screenX - ((entry.nameWidth or 0) / 2),
        nameY,
        entry.nameColor,
        entry.nameColor.a * alpha,
        nameplateFont()
    )
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
    drawHealth(manager, entry, metrics, barLeft, barTop, alpha)
    return drawStamina(manager, entry, metrics, barLeft, barTop, alpha)
end

local function drawLiveDebugOverlay(manager, entry, metrics, settings, screenX,
    nameY, alpha, debugVisible, staminaTop, barTop, showAnimation, showScene)
    local showDebug = settings.showNameplateDebug == true
        or settings.showAIDebug == true
    local showCamp = settings.showCampDebug == true
    local showFaction = settings.showFactionDebug == true
    local showCommunity = settings.showCommunityDebug == true
    if not debugVisible or not (
        showDebug or showCamp or showAnimation or showScene
            or showFaction or showCommunity
    ) then
        return
    end
    local debugY
    if entry.staminaVisible then
        debugY = (entry.healthVisible and staminaTop or barTop)
            + metrics.barHeight + Layout.debugTextGap
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


local function drawLive(manager, entry, metrics, currentTime, settings)
    local zombie = entry.zombie
    if not zombie or zombie:isDead() then return end
    local alpha = zombie.getAlpha and zombie:getAlpha(manager.playerIndex) or 1
    if alpha <= 0 then return end
    local screenX = isoToScreenX(
        manager.playerIndex, zombie:getX(), zombie:getY(), zombie:getZ()
    ) - manager.x
    local screenY = isoToScreenY(
        manager.playerIndex, zombie:getX(), zombie:getY(), zombie:getZ()
    ) - manager.y
    local nameY = screenY - metrics.nameYOffset
    updateLiveAnchor(manager, entry, zombie, metrics, screenX, screenY, nameY)
    local barLeft = screenX - (metrics.barWidth / 2)
    local barTop = screenY - metrics.barYOffset
    local identityVisible = scopeVisible(entry, Scopes.IDENTITY, true)
    local debugVisible = scopeVisible(entry, Scopes.DEBUG, true)
    local conversationVisible = scopeVisible(
        entry,
        Scopes.CONVERSATION,
        entry.speechVisible == true
    )
    if entry.snapshot.healthState == 'incapacitated' then
        entry.barColor = Presentation.IncapacitatedColor(currentTime)
    end
    local status = drawLiveStatus(
        manager,
        entry,
        metrics,
        screenX,
        nameY,
        alpha,
        currentTime,
        identityVisible,
        conversationVisible
    )
    local showAnimation = settings.showAnimationDebug == true
    local showScene = settings.showAnimationSceneDebug == true
    local staminaTop = drawLiveIdentity(
        manager,
        entry,
        metrics,
        screenX,
        nameY,
        alpha,
        identityVisible,
        barLeft,
        barTop,
        currentTime
    )
    drawLiveDebugOverlay(
        manager,
        entry,
        metrics,
        settings,
        screenX,
        nameY,
        alpha,
        debugVisible,
        staminaTop,
        barTop,
        showAnimation,
        showScene
    )
end

Internal.DrawLive = drawLive
