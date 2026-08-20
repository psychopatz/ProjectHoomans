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

function ZombieAggro.Activate(zombie, now, reason, ttl)
    local state = ZombieAggro.ActiveSet
    local id = Internal.ensureZombieID(zombie)
    local entry
    if not id or not zombie then return false end
    id = tostring(id)
    now = tonumber(now) or Core.Now()
    entry = state.byID[id]
    if not entry then
        entry = {
            id = id,
            zombie = zombie,
        }
        state.byID[id] = entry
        state.order[#state.order + 1] = id
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
    now = tonumber(now) or Core.Now()
    if force ~= true and now - (tonumber(state.lastRefreshAt) or 0)
        < (tonumber(Const.ZOMBIE_AGGRO_ACTIVE_REFRESH_MS) or 250)
    then
        return false
    end
    state.lastRefreshAt = now
    if Diagnostics then
        Diagnostics.Increment("ZombieAggro.AggroRefreshes")
    end
    if Registry and Registry.ForEachLive and Spatial and Spatial.QueryZombies then
        Registry.ForEachLive(function(record, body)
            if record and body and record.alive ~= false then
                if Diagnostics then
                    Diagnostics.Increment("ZombieAggro.RefreshNPCs")
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
                    radius
                )
                if Diagnostics then
                    Diagnostics.Increment(
                        "ZombieAggro.CandidateCount",
                        #candidates
                    )
                end
                for i = 1, #candidates do
                    zombie = candidates[i]
                    if zombie
                        and math.abs(zombie:getZ() - body:getZ()) < 1
                        and Core.DistanceSq(
                            body:getX(),
                            body:getY(),
                            zombie:getX(),
                            zombie:getY()
                        ) <= radiusSq
                    then
                        ZombieAggro.Activate(zombie, now, "near_npc")
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
            callback(zombie, now)
            processed = processed + 1
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
        if entry and entry.zombie then
            callback(entry.zombie, entry)
        end
    end
end
