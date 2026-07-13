PNC = PNC or {}
PNC.NameplateEntries = PNC.NameplateEntries or {}

local Entries = PNC.NameplateEntries
local Bodies = PNC.NameplateBodies
local Debug = PNC.NameplateDebug
local Presentation = PNC.NameplatePresentation
local Const = PNC.Const
local ClientState = PNC.Network.ClientState

local UPDATE_RATE = 6

local function cacheMetrics(entry, snapshot, zombie, showDebug)
    local fonts = Presentation.Fonts
    local name = snapshot and snapshot.name or "PNC NPC"
    local hpText = "[" .. tostring(math.floor((tonumber(snapshot.hpCurrent) or 0) + 0.5))
        .. "/" .. tostring(math.floor((tonumber(snapshot.hpMax) or 0) + 0.5)) .. "]"
    local debugText = Debug.BuildText(snapshot, zombie ~= nil)
    if showDebug then
        debugText = debugText .. " | " .. Debug.AnimationText(zombie, snapshot)
    end
    Presentation.CacheTextMetric(entry, "name", name, fonts.name)
    Presentation.CacheTextMetric(entry, "hpText", hpText, fonts.hp)
    Presentation.CacheTextMetric(entry, "debugText", debugText, fonts.debug)
end

local function populateLiveEntry(entry, snapshot, zombie, currentTime, showDebug)
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
    cacheMetrics(entry, snapshot, zombie, showDebug)
end

local function populateDebugEntry(entry, snapshot, showDebug)
    entry.snapshot = snapshot
    entry.zombie = nil
    entry.debugOnly = true
    entry.worldX = tonumber(snapshot.x) or 0
    entry.worldY = tonumber(snapshot.y) or 0
    entry.worldZ = tonumber(snapshot.z) or 0
    entry.nameColor = Presentation.NameColor(snapshot)
    cacheMetrics(entry, snapshot, nil, showDebug)
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
        return
    end

    manager.updateCounter = (manager.updateCounter or 0) + 1
    if manager.updateCounter < UPDATE_RATE then return end
    manager.updateCounter = 0

    local zombieList = getCell():getZombieList()
    if not zombieList then
        manager.entries = {}
        return
    end

    local bodyIndex = Bodies.Index(zombieList)
    local currentTime = getTimeInMillis()
    local visible = {}
    for uuid, snapshot in pairs(ClientState.snapshots or {}) do
        local zombie = Bodies.Resolve(bodyIndex, uuid, snapshot)
        local alive = snapshot and snapshot.alive ~= false
            and snapshot.presenceState == Const.PRESENCE_LIVE
        if zombie and alive then
            Bodies.Tag(zombie, uuid, snapshot)
            if isLiveVisible(player, zombie) then
                local entry = manager.entries[uuid] or { uuid = uuid }
                populateLiveEntry(entry, snapshot, zombie, currentTime, settings.showAIDebug)
                manager.entries[uuid] = entry
                visible[uuid] = true
            end
        elseif settings.showAIDebug and snapshot and isDebugVisible(player, snapshot) then
            local entry = manager.entries[uuid] or { uuid = uuid }
            populateDebugEntry(entry, snapshot, settings.showAIDebug)
            manager.entries[uuid] = entry
            visible[uuid] = true
        end
    end

    for uuid, _ in pairs(manager.entries) do
        if not visible[uuid] then manager.entries[uuid] = nil end
    end
end

return Entries
