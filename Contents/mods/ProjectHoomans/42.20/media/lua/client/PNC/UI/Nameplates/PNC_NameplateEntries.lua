PNC = PNC or {}
PNC.NameplateEntries = PNC.NameplateEntries or {}

require "PNC/Knowledge/PNC_NPCIdentityPresentation"

local Entries = PNC.NameplateEntries
local Bodies = PNC.NameplateBodies
local Debug = PNC.NameplateDebug
local Presentation = PNC.NameplatePresentation
local Const = PNC.Const
local ClientState = PNC.Network.ClientState
local Identity = PNC.NPCIdentityPresentation
local Diagnostics = PNC.PerformanceScalingDiagnostics

local UPDATE_RATE = 6

local function rounded(value)
    value = tonumber(value) or 0
    if value < 0 then
        return math.ceil(value * 10 - 0.5) / 10
    end
    return math.floor(value * 10 + 0.5) / 10
end

local function signed(value)
    value = rounded(value)
    return (value > 0 and "+" or "") .. tostring(value)
end

local function factionDebugLines(snapshot, settings)
    if not settings
        or settings.showFactionDebug ~= true
        or not PNC.FactionDebugOverlay
        or not PNC.FactionDebugOverlay.GetNPCDiagnostic
    then
        return "", "", "", "", "", nil, nil, nil
    end
    local value =
        PNC.FactionDebugOverlay.GetNPCDiagnostic(snapshot.id)
    if not value then
        return "FACTION waiting for server diagnostic",
            "", "", "", "", "warning", "neutral", nil
    end
    local faction = value.factionName
        or value.factionID or "unaffiliated"
    local first = "FACTION " .. tostring(faction)
        .. " [" .. tostring(value.archetypeID or "-") .. "]"
        .. " " .. tostring(value.role or "-")
        .. "/" .. tostring(value.rank or "-")
    local second = "PLAYER relation="
        .. tostring(value.relationState or "unknown")
        .. " war=" .. tostring(value.atWarWithPlayer == true)
        .. " intent=" .. tostring(value.intent or "observe")
        .. " attack=" .. tostring(value.attackAllowed == true)
        .. " (" .. tostring(value.intentReason or "-") .. ")"
    local target = value.target
    local third = "TACTICAL "
        .. tostring(value.legacyFaction or "neutral")
        .. " P/N/Z="
        .. tostring(value.attackPlayers == true) .. "/"
        .. tostring(value.attackNPCs == true) .. "/"
        .. tostring(value.attackZombies == true)
        .. " order=" .. tostring(value.orderKind or "-")
        .. " job=" .. tostring(value.activeJob or "-")
        .. " target=" .. tostring(
            target and (
                tostring(target.kind or "?")
                    .. ":" .. tostring(target.id or "-")
            ) or "none"
        )
    local tone = value.attackAllowed == true and "danger"
        or value.commandable == true and "success"
        or value.atWarWithPlayer == true and "warning"
        or "neutral"
    local relationship = value.relationship or {}
    local fourth = "REL player A="
        .. signed(relationship.approval)
        .. " R=" .. signed(relationship.respect)
        .. " F=" .. tostring(
            rounded(relationship.familiarity)
        )
        .. " state=" .. tostring(
            relationship.state or "unknown"
        )
        .. " rev=" .. tostring(
            tonumber(relationship.revision) or 0
        )
        .. " morale=" .. signed(value.morale)
    local relationshipTone =
        (tonumber(relationship.approval) or 0) < 0
            and "danger"
        or relationship.state == "friend" and "success"
        or relationship.state == "enemy" and "danger"
        or relationship.state == "rival" and "warning"
        or "neutral"
    local change
    local changeCount
    if PNC.FactionDebugOverlay.GetRelationshipChange then
        change, changeCount =
            PNC.FactionDebugOverlay.GetRelationshipChange(
                snapshot.id
            )
    end
    local fifth = ""
    local changeTone
    if change then
        local changeType = tostring(
            change.memoryType
                or change.kind
                or "relationship_changed"
        )
        fifth = "CHANGE " .. changeType
            .. " [" .. tostring(
                change.kind or "relationship_changed"
            ) .. "]"
            .. " dA=" .. signed(change.approvalDelta)
            .. " dR=" .. signed(change.respectDelta)
            .. " dF=" .. signed(change.familiarityDelta)
            .. " dM=" .. signed(change.moraleDelta)
        if change.stateBefore ~= change.stateAfter then
            fifth = fifth .. " "
                .. tostring(change.stateBefore or "unknown")
                .. ">" .. tostring(
                    change.stateAfter or "unknown"
                )
        end
        if (tonumber(changeCount) or 0) > 1 then
            fifth = fifth .. " x"
                .. tostring(changeCount)
        end
        if change.knowledgeSource then
            fifth = fifth .. " src="
                .. tostring(change.knowledgeSource)
        end
        local net = (tonumber(change.approvalDelta) or 0)
            + (tonumber(change.respectDelta) or 0)
            + (tonumber(change.moraleDelta) or 0)
        changeTone = net < 0 and "danger"
            or net > 0 and "success"
            or "warning"
    end
    return first, second, third, fourth, fifth,
        tone, relationshipTone, changeTone
end

Entries.BuildFactionDebugLines = factionDebugLines

local function communityDebugLines(snapshot, settings)
    if not settings
        or settings.showCommunityDebug ~= true
        or not PNC.CommunityDebugOverlay
        or not PNC.CommunityDebugOverlay.GetNPCDiagnostic
    then
        return "", "", "neutral"
    end
    local value =
        PNC.CommunityDebugOverlay.GetNPCDiagnostic(snapshot.id)
    if not value then
        return "COMMUNITY waiting for server diagnostic",
            "", "warning"
    end
    if not value.communityID then
        return "COMMUNITY none | faction="
            .. tostring(value.factionID or "unaffiliated"),
            "LOCATION "
                .. tostring(math.floor(value.x or 0))
                .. "," .. tostring(math.floor(value.y or 0))
                .. "," .. tostring(math.floor(value.z or 0)),
            "neutral"
    end
    local snapshotValue = ClientState.communityDebug
        and ClientState.communityDebug.communities or {}
    local community
    for _, item in ipairs(snapshotValue) do
        if item.id == value.communityID then
            community = item
            break
        end
    end
    local first = "COMMUNITY "
        .. tostring(value.communityName or value.communityID)
        .. " role=" .. tostring(value.communityRole)
        .. " " .. tostring(
            community and community.mode or "-"
        )
        .. "/" .. tostring(
            community and community.status or "-"
        )
    local second = "HOME distance="
        .. tostring(rounded(value.distanceFromHome))
        .. " inside=" .. tostring(value.insideHome == true)
        .. " population="
        .. tostring(
            community and community.currentPopulation or 0
        )
        .. "/" .. tostring(
            community and community.populationCapacity or 0
        )
        .. " security=" .. tostring(
            community and community.security or 0
        )
        .. " morale=" .. signed(
            community and community.morale or 0
        )
        .. " rev=" .. tostring(
            community and community.revision or 0
        )
    return first, second,
        value.insideHome == true and "success" or "warning"
end

Entries.BuildCommunityDebugLines = communityDebugLines

local function cacheMetrics(entry, snapshot, zombie, settings)
    local fonts = Presentation.Fonts
    local showDebug = settings and settings.showAIDebug == true
    local name = Identity.GetName(snapshot)
    local debugText = showDebug
        and Debug.BuildText(snapshot, zombie ~= nil, settings) or ""
    if showDebug and settings.debugShowAnimation ~= false then
        local animationText = Debug.AnimationText(zombie, snapshot)
        debugText = debugText ~= "" and (debugText .. " | " .. animationText) or animationText
    end
    local animationDebugText = settings
        and settings.showAnimationDebug == true
        and Debug.AnimationTrackText(zombie)
        or ""
    local sceneDebugText = ""
    local sceneTrackDebugText = ""
    if settings
        and settings.showAnimationSceneDebug == true
        and Debug.AnimationSceneText
    then
        sceneDebugText, sceneTrackDebugText =
            Debug.AnimationSceneText(zombie, snapshot)
    end
    local infectionDebugText = showDebug
        and Debug.InfectionText(snapshot, settings) or ""
    local actionText, actionColor = Presentation.ActionStatus(snapshot)
    local factionLine1
    local factionLine2
    local factionLine3
    local relationshipDebugLine
    local relationshipChangeLine
    local communityDebugLine1
    local communityDebugLine2
    factionLine1,
    factionLine2,
    factionLine3,
    relationshipDebugLine,
    relationshipChangeLine,
    entry.factionDebugTone,
    entry.relationshipDebugTone,
    entry.relationshipChangeTone =
        factionDebugLines(snapshot, settings)
    communityDebugLine1,
    communityDebugLine2,
    entry.communityDebugTone =
        communityDebugLines(snapshot, settings)
    entry.actionColor = actionColor
    entry.actionVisible = actionText ~= ""
    Presentation.CacheTextMetric(entry, "name", name, fonts.name)
    Presentation.CacheTextMetric(entry, "debugText", debugText, fonts.debug)
    Presentation.CacheTextMetric(
        entry,
        "animationDebugText",
        animationDebugText,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "sceneDebugText",
        sceneDebugText,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "sceneTrackDebugText",
        sceneTrackDebugText,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "infectionDebugText",
        infectionDebugText,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "actionText",
        actionText,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "factionDebugLine1",
        factionLine1,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "factionDebugLine2",
        factionLine2,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "factionDebugLine3",
        factionLine3,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "relationshipDebugLine",
        relationshipDebugLine,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "relationshipChangeLine",
        relationshipChangeLine,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "communityDebugLine1",
        communityDebugLine1,
        fonts.debug
    )
    Presentation.CacheTextMetric(
        entry,
        "communityDebugLine2",
        communityDebugLine2,
        fonts.debug
    )
end

local function populateLiveEntry(entry, snapshot, zombie, currentTime, settings)
    if Diagnostics then
        Diagnostics.Increment("UI.NameplateEntryBuilds")
    end
    entry.snapshot = snapshot
    entry.zombie = zombie
    entry.debugOnly = false
    entry.healthRatio = Presentation.HealthRatio(snapshot)
    entry.nameColor = Presentation.NameColor(snapshot)
    entry.healthVisible = Presentation.ShouldShowHealth(snapshot, currentTime)
    entry.staminaVisible = Presentation.ShouldShowStamina(snapshot, currentTime)
    entry.staminaRatio = Presentation.StaminaRatio(snapshot)
    entry.staminaColor = Presentation.StaminaColor(entry.staminaRatio)
    entry.barColor = snapshot.healthState == "incapacitated"
        and Presentation.IncapacitatedColor(currentTime)
        or Presentation.HealthColor(entry.healthRatio)
    cacheMetrics(entry, snapshot, zombie, settings)
end

local function populateDebugEntry(entry, snapshot, settings)
    if Diagnostics then
        Diagnostics.Increment("UI.NameplateEntryBuilds")
    end
    entry.snapshot = snapshot
    entry.zombie = nil
    entry.debugOnly = true
    entry.worldX = tonumber(snapshot.x) or 0
    entry.worldY = tonumber(snapshot.y) or 0
    entry.worldZ = tonumber(snapshot.z) or 0
    entry.nameColor = Presentation.NameColor(snapshot)
    cacheMetrics(entry, snapshot, nil, settings)
end

local function isLiveVisible(player, zombie)
    local layout = Presentation.Layout
    return math.abs(player:getZ() - zombie:getZ()) <= layout.floorTolerance
        and Presentation.Distance(player, zombie) <= layout.maxDrawDistance
end

local function isDebugVisible(player, snapshot)
    local layout = Presentation.Layout
    return math.abs(player:getZ() - (tonumber(snapshot.z) or 0)) <= layout.floorTolerance
        and PNC.Core.Distance(
            player:getX(),
            player:getY(),
            tonumber(snapshot.x) or 0,
            tonumber(snapshot.y) or 0
        ) <= layout.maxDrawDistance
end

function Entries.Refresh(manager, settings)
    if Diagnostics then
        Diagnostics.Increment("UI.NameplateUpdateCalls")
    end
    local debugActive = settings.showAIDebug == true
        or settings.showPathDebug == true
        or settings.showCombatDebug == true
        or settings.showAnimationDebug == true
        or settings.showAnimationSceneDebug == true
        or settings.showFactionDebug == true
        or settings.showCommunityDebug == true
    if settings.showFactionDebug == true
        and PNC.FactionDebugOverlay
        and PNC.FactionDebugOverlay.Update
    then
        PNC.FactionDebugOverlay.Update()
    end
    if settings.showCommunityDebug == true
        and PNC.CommunityDebugOverlay
        and PNC.CommunityDebugOverlay.Update
    then
        PNC.CommunityDebugOverlay.Update()
    end
    manager:setX(getPlayerScreenLeft(manager.playerIndex))
    manager:setY(getPlayerScreenTop(manager.playerIndex))
    manager.renderWidth = getPlayerScreenWidth(manager.playerIndex)
    manager.renderHeight = getPlayerScreenHeight(manager.playerIndex)
    manager:setWidth(manager.renderWidth)
    manager:setHeight(manager.renderHeight)

    manager.player = getSpecificPlayer(manager.playerIndex)
    local player = manager.player
    if not player or not settings.enabled or not getCell then
        manager.entries = {}
        if Diagnostics then
            Diagnostics.SetGauge("UI.NameplateVisibleEntries", 0)
        end
        return
    end

    manager.updateCounter = (manager.updateCounter or 0) + 1
    if manager.updateCounter < UPDATE_RATE then return end
    manager.updateCounter = 0
    if Diagnostics then
        Diagnostics.Increment("UI.NameplateRefreshes")
    end

    local zombieList = getCell():getZombieList()
    if not zombieList then
        manager.entries = {}
        if Diagnostics then
            Diagnostics.SetGauge("UI.NameplateVisibleEntries", 0)
        end
        return
    end
    if Diagnostics then
        Diagnostics.Increment("UI.LoadedZombieScans")
        Diagnostics.Increment(
            "UI.LoadedZombiesScanned",
            zombieList:size()
        )
    end

    local bodyIndex = Bodies.Index(zombieList)
    local currentTime = getTimeInMillis()
    local visible = {}
    for uuid, snapshot in pairs(ClientState.snapshots or {}) do
        local zombie = Bodies.Resolve(bodyIndex, uuid, snapshot)
        local alive = snapshot and snapshot.alive ~= false
            and snapshot.presenceState == Const.PRESENCE_LIVE
        if zombie and alive
            and (Identity.IsNameKnown(snapshot) or debugActive)
        then
            Bodies.Tag(zombie, uuid, snapshot)
            if isLiveVisible(player, zombie) then
                local entry = manager.entries[uuid] or { uuid = uuid }
                populateLiveEntry(entry, snapshot, zombie, currentTime, settings)
                manager.entries[uuid] = entry
                visible[uuid] = true
            end
        elseif debugActive and snapshot and isDebugVisible(player, snapshot) then
            local entry = manager.entries[uuid] or { uuid = uuid }
            populateDebugEntry(entry, snapshot, settings)
            manager.entries[uuid] = entry
            visible[uuid] = true
        end
    end

    for uuid, _ in pairs(manager.entries) do
        if not visible[uuid] then manager.entries[uuid] = nil end
    end
    if Diagnostics then
        local visibleCount = 0
        for _, _ in pairs(visible) do visibleCount = visibleCount + 1 end
        Diagnostics.SetGauge("UI.NameplateVisibleEntries", visibleCount)
    end
end

return Entries
