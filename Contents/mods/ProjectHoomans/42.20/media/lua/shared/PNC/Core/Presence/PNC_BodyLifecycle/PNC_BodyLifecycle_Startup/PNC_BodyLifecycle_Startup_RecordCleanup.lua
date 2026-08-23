local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core

local function addCandidate(candidates, seen, zombie)
    if zombie and not seen[zombie] then
        seen[zombie] = true
        candidates[#candidates + 1] = zombie
    end
end

local function collectLifecycleCandidates(candidates, seen, now)
    local values
    local i
    if not PNC.WorldCensus
        or not PNC.WorldCensus.GetLifecycleCandidates
    then
        return
    end
    values = PNC.WorldCensus.GetLifecycleCandidates(now, false)
    for i = 1, #values do
        addCandidate(candidates, seen, values[i])
    end
end

local function collectNearbyCandidates(candidates, seen, record)
    local values
    local i
    if not PNC.SpatialIndex or not PNC.SpatialIndex.QueryZombies then
        return
    end
    values = PNC.SpatialIndex.QueryZombies(record.x, record.y, 3.5)
    for i = 1, #values do
        addCandidate(candidates, seen, values[i])
    end
end

local function collectCensusCandidates(candidates, seen, record, now)
    local values
    local zombie
    local distance
    local i
    if not PNC.WorldCensus
        or not PNC.WorldCensus.GetAll
        or (
            PNC.SpatialIndex
            and tonumber(PNC.SpatialIndex.LastRebuildAt) ~= nil
        )
    then
        return
    end
    values = PNC.WorldCensus.GetAll(now, false)
    for i = 1, #values do
        zombie = values[i]
        distance =
            Internal.StartupDistanceSqToRecord(zombie, record)
        if distance ~= nil and distance <= (3.5 * 3.5) then
            addCandidate(candidates, seen, zombie)
        end
    end
end

local function collectCellFallback(candidates)
    local cell
    local zombies
    local i
    if #candidates > 0
        or (
            PNC.WorldCensus
            and PNC.WorldCensus.GetLifecycleCandidates
        )
    then
        return
    end
    cell = getCell and getCell() or nil
    zombies = cell and cell.getZombieList and cell:getZombieList() or nil
    if not zombies then return end
    for i = 0, zombies:size() - 1 do
        candidates[#candidates + 1] = zombies:get(i)
    end
end

local function collectCandidates(record, now)
    local candidates = {}
    local seen = {}
    collectLifecycleCandidates(candidates, seen, now)
    collectNearbyCandidates(candidates, seen, record)
    collectCensusCandidates(candidates, seen, record, now)
    collectCellFallback(candidates)
    return candidates
end

local function removalReason(record, zombie)
    local npcId =
        Internal.GetLiveShellIdentity(zombie)
    local naked = Internal.IsNakedStartupShell(zombie)
    local exactID =
        npcId ~= nil and tostring(npcId) == tostring(record.id)
    local closeEnough =
        Internal.StartupDistanceSqToRecord(zombie, record)
    closeEnough = closeEnough ~= nil
        and closeEnough
            <= (naked and 1.25 * 1.25 or 3.5 * 3.5)
    if Internal.IsCanonicalStartupBody(record, zombie) then
        return nil
    end
    if exactID then return "pre_materialize_uuid_shell" end
    if Internal.StartupBodyHintMatches(record, zombie) then
        return "pre_materialize_body_hint"
    end
    if naked and closeEnough and npcId == nil then
        return "pre_materialize_naked_shell"
    end
    return nil
end

function Lifecycle.CleanupRecordShells(record, now)
    local candidates
    local reason
    local removed = 0
    local i
    now = tonumber(now) or Core.Now()
    if not Core.IsAuthority() or not record or record.alive == false then
        return 0
    end
    candidates = collectCandidates(record, now)
    for i = #candidates, 1, -1 do
        reason = removalReason(record, candidates[i])
        if reason then
            Internal.RemoveStartupShell(record, candidates[i], reason)
            removed = removed + 1
        end
    end
    return removed
end
