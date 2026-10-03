local Entries = PNC.NameplateEntries
local Bodies = PNC.NameplateBodies
local Presentation = PNC.NameplatePresentation
local Const = PNC.Const
local ClientState = PNC.Network.ClientState
local Speech = PNC.NameplateSpeech
local Scopes = PNC.NameplateScopes
local Diagnostics = PNC.PerformanceScalingDiagnostics
local cacheMetrics = Entries._CacheMetrics

local UPDATE_RATE = 6

local function populateLiveEntry(
    entry,
    snapshot,
    zombie,
    currentTime,
    settings,
    speech,
    scopes
)
    if Diagnostics then
        Diagnostics.Increment("UI.NameplateEntryBuilds")
    end
    entry.snapshot = snapshot
    entry.zombie = zombie
    entry.debugOnly = false
    entry.healthRatio = Presentation.HealthRatio(snapshot)
    entry.nameColor = Presentation.NameColor(snapshot)
    entry.healthVisible = scopes[Scopes.IDENTITY]
        and Presentation.ShouldShowHealth(snapshot, currentTime) or false
    entry.staminaVisible = scopes[Scopes.IDENTITY]
        and Presentation.ShouldShowStamina(snapshot, currentTime) or false
    entry.staminaRatio = Presentation.StaminaRatio(snapshot)
    entry.staminaColor = Presentation.StaminaColor(entry.staminaRatio)
    entry.barColor = snapshot.healthState == "incapacitated"
        and Presentation.IncapacitatedColor(currentTime)
        or Presentation.HealthColor(entry.healthRatio)
    cacheMetrics(entry, snapshot, zombie, settings, speech, scopes)
end

local function populateDebugEntry(entry, snapshot, settings, speech, scopes)
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
    cacheMetrics(entry, snapshot, nil, settings, speech, scopes)
end

function Entries.Refresh(manager, settings)
    if Diagnostics then
        Diagnostics.Increment("UI.NameplateUpdateCalls")
    end
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
        local speech = Speech and Speech.Get(uuid) or nil
        local alive = snapshot and snapshot.alive ~= false
            and snapshot.presenceState == Const.PRESENCE_LIVE
        local scopes = Scopes.Build(
            player,
            snapshot,
            zombie,
            settings,
            speech
        )
        if zombie and alive and Scopes.IsLiveVisible(player, zombie)
            and Scopes.HasRenderableScope(scopes)
        then
            Bodies.Tag(zombie, uuid, snapshot)
            local entry = manager.entries[uuid] or { uuid = uuid }
            populateLiveEntry(
                entry,
                snapshot,
                zombie,
                currentTime,
                settings,
                speech,
                scopes
            )
            manager.entries[uuid] = entry
            visible[uuid] = true
        elseif snapshot and Scopes.HasRenderableScope(scopes) then
            local entry = manager.entries[uuid] or { uuid = uuid }
            populateDebugEntry(entry, snapshot, settings, speech, scopes)
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
