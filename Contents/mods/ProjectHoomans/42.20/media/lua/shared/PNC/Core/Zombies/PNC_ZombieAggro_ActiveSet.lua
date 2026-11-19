-- Bounded active-zombie work set. Only zombies near a managed live body, or
-- zombies with an explicit PNC aggro/bite lease, need PNC-side updates.

PNC = PNC or {}
PNC.ZombieAggro = PNC.ZombieAggro or {}

local ZombieAggro = PNC.ZombieAggro
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Spatial = PNC.SpatialIndex
local Internal = ZombieAggro.Internal
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function isForeignOwnedBody(body)
    local ownership = PNC.Compatibility
        and PNC.Compatibility.ActorOwnership or nil
    return ownership
        and ownership.IsForeignOwned
        and ownership.IsForeignOwned(body) == true
        or false
end

ZombieAggro.ActiveSet = ZombieAggro.ActiveSet or {
    byID = {},
    order = {},
    cursor = 1,
    holes = 0,
    lastRefreshAt = 0,
    pathRequestsThisPump = 0,
}

local function isLeased(entry, now)
    local zombie = entry and entry.zombie or nil
    local modData = zombie and zombie.getModData and zombie:getModData() or nil
    local bite = entry and ZombieAggro.State and ZombieAggro.State.bites
        and ZombieAggro.State.bites[entry.id] or nil
    return bite ~= nil
        or (modData and now < (tonumber(modData.PNC_AggroNPCUntil) or 0))
end

local function compact()
    local state = ZombieAggro.ActiveSet
    local compacted = {}
    local i
    local id
    for i = 1, #state.order do
        id = state.order[i]
        if id and state.byID[id] then
            compacted[#compacted + 1] = id
        end
    end
    state.order = compacted
    state.cursor = math.min(math.max(1, state.cursor), math.max(1, #compacted))
    state.holes = 0
    if Diagnostics then
        Diagnostics.Increment("ZombieAggro.Compactions")
    end
end

local function hasLiveBodies()
    local liveByID = Registry and Registry.LiveByID or nil
    if not liveByID then
        return true
    end
    for id, body in pairs(liveByID) do
        if id ~= nil and body ~= nil then
            return true
        end
    end
    return false
end

local function isEntryDue(entry, zombie, now, closeRangeSq)
    if entry.urgent == true
        or entry.nextProcessAt == nil
        or now >= (tonumber(entry.nextProcessAt) or 0)
    then
        return true
    end
    local bites = ZombieAggro.State and ZombieAggro.State.bites or nil
    if bites and bites[entry.id] ~= nil then
        return true
    end
    if (zombie.getTarget and zombie:getTarget() ~= nil)
        or (zombie.getAttackedBy and zombie:getAttackedBy() ~= nil)
    then
        return true
    end
    local reaction = PNC.CombatZombieReaction
    if reaction
        and reaction.IsEngineHitSettling
        and reaction.IsEngineHitSettling(zombie, now) == true
    then
        return true
    end
    local targetBody = entry.targetNpcBody
    if targetBody ~= nil then
        if (targetBody.isDead and targetBody:isDead())
            or (targetBody.getSquare and targetBody:getSquare() == nil)
        then
            return true
        end
        if Core.DistanceSq
            and zombie.getX and zombie.getY
            and targetBody.getX and targetBody.getY
        then
            local dSq = Core.DistanceSq(
                zombie:getX(),
                zombie:getY(),
                targetBody:getX(),
                targetBody:getY()
            )
            if dSq <= closeRangeSq then
                return true
            end
        end
    end
    return false
end

function ZombieAggro.Activate(zombie, now, reason, ttl, skipForeignCheck)
    local state = ZombieAggro.ActiveSet
    local id
    local entry
    local isNew
    if not zombie or (skipForeignCheck ~= true and isForeignOwnedBody(zombie)) then
        return false
    end
    id = Internal.ensureZombieID(zombie)
    if not id then return false end
    id = tostring(id)
    now = tonumber(now) or Core.Now()
    entry = state.byID[id]
    isNew = entry == nil
    if isNew then
        entry = {
            id = id,
            zombie = zombie,
            urgent = true,
        }
        state.byID[id] = entry
        state.order[#state.order + 1] = id
    elseif reason == "provoked" or reason == "attacked" then
        entry.urgent = true
        entry.nextProcessAt = nil
    end
    entry.zombie = zombie
    entry.reason = reason or entry.reason or "near_npc"
    entry.expiresAt = math.max(
        tonumber(entry.expiresAt) or 0,
        now + (tonumber(ttl) or tonumber(Const.ZOMBIE_AGGRO_ACTIVE_TTL_MS) or 1500)
    )
    return true
end

function ZombieAggro.RefreshActiveSet(now, force)
    local state = ZombieAggro.ActiveSet
    local candidates
    local i
    local radius = tonumber(Const.ZOMBIE_AGGRO_RADIUS) or 12
    local radiusSq = radius * radius
    local zombie
    local queryCache
    local cellSize
    local cellX
    local cellY
    local cellZ
    local cellKey
    local queryRadius
    now = tonumber(now) or Core.Now()
    if force ~= true and now - (tonumber(state.lastRefreshAt) or 0)
        < (tonumber(Const.ZOMBIE_AGGRO_ACTIVE_REFRESH_MS) or 250)
    then
        return false
    end
    state.lastRefreshAt = now
    if not hasLiveBodies() then
        if state.holes > 32 and state.holes * 3 > #state.order then
            compact()
        end
        return true
    end
    queryCache = {}
    local seenForeign = {}
    local activatedThisRefresh = {}
    cellSize = math.max(
        2,
        tonumber(Const.CLIENT_ZOMBIE_AGGRO_CELL_SIZE) or 8
    )
    -- One expanded query can serve every NPC in the same spatial cell. The
    -- per-body distance check below keeps the exact radius semantics while
    -- avoiding one Spatial.QueryZombies call for every group member.
    queryRadius = radius + (cellSize * 1.5)
    if Diagnostics then
        Diagnostics.Increment("ZombieAggro.AggroRefreshes")
    end
    if Registry and Registry.ForEachLive and Spatial and Spatial.QueryZombies then
        Registry.ForEachLive(function(record, body)
            if record and body and record.alive ~= false then
                if Diagnostics then
                    Diagnostics.Increment("ZombieAggro.RefreshNPCs")
                end
                cellX = math.floor(body:getX() / cellSize)
                cellY = math.floor(body:getY() / cellSize)
                cellZ = math.floor(body:getZ() or 0)
                cellKey = tostring(cellX) .. ":" .. tostring(cellY)
                    .. ":" .. tostring(cellZ)
                candidates = queryCache[cellKey]
                if not candidates then
                    if Diagnostics then
                        Diagnostics.Increment("ZombieAggro.CandidateQueries")
                        if record.presenceState
                            ~= PNC.Const.PRESENCE_LIVE
                        then
                            Diagnostics.Increment(
                                "LiveAbstract.AbstractAggroQueries"
                            )
                        end
                    end
                    candidates = Spatial.QueryZombies(
                        body:getX(),
                        body:getY(),
                        queryRadius
                    )
                    queryCache[cellKey] = candidates
                end
                if Diagnostics then
                    Diagnostics.Increment(
                        "ZombieAggro.CandidateCount",
                        #candidates
                    )
                end
                for i = 1, #candidates do
                    zombie = candidates[i]
                    if zombie and not activatedThisRefresh[zombie] then
                        local foreign = seenForeign[zombie]
                        if foreign == nil then
                            foreign = isForeignOwnedBody(zombie)
                            seenForeign[zombie] = foreign
                        end
                        if not foreign
                            and math.abs(zombie:getZ() - body:getZ()) < 1
                            and Core.DistanceSq(
                                body:getX(),
                                body:getY(),
                                zombie:getX(),
                                zombie:getY()
                            ) <= radiusSq
                        then
                            activatedThisRefresh[zombie] = true
                            ZombieAggro.Activate(
                                zombie, now, "near_npc", nil, true
                            )
                        end
                    end
                end
            end
        end)
    end
    if state.holes > 32 and state.holes * 3 > #state.order then
        compact()
    end
    return true
end

function ZombieAggro.PumpActiveSet(now, callback)
    local state = ZombieAggro.ActiveSet
    local budget = math.max(1,
        math.floor(tonumber(Const.ZOMBIE_AGGRO_MAX_PER_TICK) or 64))
    local orderCount = #state.order
    local visited = 0
    local processed = 0
    local id
    local entry
    local zombie
    local closeRange = (tonumber(Const.ZOMBIE_BITE_DISTANCE) or 1.2) + 1.5
    local closeRangeSq = closeRange * closeRange
    now = tonumber(now) or Core.Now()
    if type(callback) ~= "function" or orderCount <= 0 then return 0 end
    state.pathRequestsThisPump = 0

    while processed < budget and visited < orderCount do
        if state.cursor > orderCount then state.cursor = 1 end
        id = state.order[state.cursor]
        state.cursor = state.cursor + 1
        visited = visited + 1
        entry = id and state.byID[id] or nil
        zombie = entry and entry.zombie or nil
        if entry and zombie
            and not (zombie.isDead and zombie:isDead())
            and (not zombie.getSquare or zombie:getSquare() ~= nil)
            and (now < (tonumber(entry.expiresAt) or 0)
                or isLeased(entry, now))
        then
            if isEntryDue(entry, zombie, now, closeRangeSq) then
                if isForeignOwnedBody(zombie) then
                    state.byID[id] = nil
                    state.order[state.cursor - 1] = false
                    state.holes = state.holes + 1
                else
                    entry.urgent = false
                    local cooldownMs, targetNpcBody =
                        callback(zombie, now, true)
                    processed = processed + 1
                    if type(cooldownMs) == "number" and cooldownMs > 0 then
                        entry.nextProcessAt = now + cooldownMs
                    else
                        entry.nextProcessAt = nil
                    end
                    entry.targetNpcBody = targetNpcBody
                end
            end
        elseif entry then
            state.byID[id] = nil
            state.order[state.cursor - 1] = false
            state.holes = state.holes + 1
        end
    end
    if Diagnostics then
        Diagnostics.Increment("ZombieAggro.ProcessedCount", processed)
    end
    return processed
end

function ZombieAggro.ConsumePathRequestBudget()
    local state = ZombieAggro.ActiveSet
    local maximum = math.max(
        1,
        math.floor(
            tonumber(Const.ZOMBIE_AGGRO_PATH_REQUESTS_PER_TICK) or 16
        )
    )
    if (tonumber(state.pathRequestsThisPump) or 0) >= maximum then
        return false
    end
    state.pathRequestsThisPump = (tonumber(state.pathRequestsThisPump) or 0) + 1
    return true
end

function ZombieAggro.ForEachActive(callback)
    local state = ZombieAggro.ActiveSet
    local i
    local id
    local entry
    if type(callback) ~= "function" then return end
    for i = 1, #state.order do
        id = state.order[i]
        entry = id and state.byID[id] or nil
        if entry and entry.zombie and not isForeignOwnedBody(entry.zombie) then
            callback(entry.zombie, entry)
        end
    end
end
