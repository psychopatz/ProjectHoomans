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

local function isZombieObject(object)
    if not object then
        return false
    end
    if instanceof then
        return instanceof(object, "IsoZombie") == true
    end
    return object.getPersistentOutfitID ~= nil
end

local function collectLoadedSquareCandidates(candidates, seen, record)
    local cell
    local centerX
    local centerY
    local centerZ
    local dx
    local dy
    local square
    local objects
    local count
    local index
    local object
    if not record or not record.x or not record.y then
        return
    end
    cell = getCell and getCell() or nil
    if not cell or not cell.getGridSquare then
        return
    end
    centerX = math.floor(tonumber(record.x) or 0)
    centerY = math.floor(tonumber(record.y) or 0)
    centerZ = math.floor(tonumber(record.z) or 0)
    -- The index/census can be one refresh behind a freshly restored body.
    -- Inspect the bounded loaded-square halo immediately before materializing.
    for dx = -4, 4 do
        for dy = -4, 4 do
            square = cell:getGridSquare(
                centerX + dx,
                centerY + dy,
                centerZ
            )
            objects = square and square.getMovingObjects
                and square:getMovingObjects() or nil
            if objects then
                count = objects.size and objects:size() or #objects
                for index = 0, count - 1 do
                    object = objects.get
                        and objects:get(index) or objects[index + 1]
                    if isZombieObject(object) then
                        addCandidate(candidates, seen, object)
                    end
                end
            end
        end
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
    collectLoadedSquareCandidates(candidates, seen, record)
    collectCellFallback(candidates)
    return candidates
end

local function collectNearbyCorpses(record)
    local cell
    local corpses = {}
    local seen = {}
    local centerX
    local centerY
    local centerZ
    local dx
    local dy
    local square
    if not record or not Internal.forEachCorpse
        or not record.x or not record.y
    then
        return corpses
    end
    cell = getCell and getCell() or nil
    if not cell or not cell.getGridSquare then
        return corpses
    end
    centerX = math.floor(tonumber(record.x) or 0)
    centerY = math.floor(tonumber(record.y) or 0)
    centerZ = math.floor(tonumber(record.z) or 0)
    -- The old shell is normally killed on the exact record square. The one
    -- square halo catches a death animation that crosses a tile without
    -- turning this preflight into a world-wide corpse scan.
    for dx = -1, 1 do
        for dy = -1, 1 do
            square = cell:getGridSquare(
                centerX + dx, centerY + dy, centerZ
            )
            Internal.forEachCorpse(square, function(corpse)
                if corpse and not seen[corpse] then
                    seen[corpse] = true
                    corpses[#corpses + 1] = corpse
                end
            end)
        end
    end
    return corpses
end

local function staleManagedCorpseMatches(record, corpse)
    local modData
    local npcId
    local bodyKind
    if not record or not corpse or not corpse.getModData then
        return false
    end
    modData = corpse:getModData()
    if not modData then
        return false
    end
    npcId = modData.PNC_UUID
    bodyKind = tostring(modData.PNC_BodyKind or "")
    -- A real NPC corpse is authoritative death state. Never consume it from
    -- this live-shell repair lane, even if an old engine path copied PNC_UUID.
    if modData.PNC_DeathMarkerID ~= nil or bodyKind == "corpse" then
        return false
    end
    if npcId == nil or tostring(npcId) ~= tostring(record.id) then
        return false
    end
    return modData.PNC_Owner == "ProjectHoomans"
        or modData.PNC_NPC == true
        or modData.PNC_PersistedShell == true
        or modData.PNC_BodyLease ~= nil
        or bodyKind == "live"
end

local function cleanupStaleManagedCorpses(record)
    local passenger
    local corpses
    local removed = 0
    local i
    if not record or record.alive == false then
        return 0
    end
    -- A passenger is intentionally bodyless. Do not let a stale cleanup pass
    -- touch anything associated with that reservation while the vehicle lane
    -- owns the NPC's presentation.
    passenger = record.runtime and record.runtime.vehiclePassenger or nil
    if passenger and passenger.active == true then
        return 0
    end
    corpses = collectNearbyCorpses(record)
    for i = #corpses, 1, -1 do
        if staleManagedCorpseMatches(record, corpses[i])
            and Internal.removeCorpse
            and Internal.removeCorpse(corpses[i])
        then
            removed = removed + 1
            if Core.LogWarn then
                Core.LogWarn(
                    "PNC stale shell corpse repaired npc="
                        .. tostring(record.id)
                        .. " reason=live_identity_corpse"
                )
            end
        end
    end
    return removed
end

local function removalReason(record, zombie)
    local npcId, strong = Internal.GetLiveShellIdentity(zombie)
    local legacyEntry
    local exactID =
        npcId ~= nil and tostring(npcId) == tostring(record.id)
    local matchedRecord
    local matchReason
    if Internal.IsCanonicalStartupBody(record, zombie) then
        return nil
    end
    if Lifecycle.FindHuskEntry and Lifecycle.IsLegacyAnonymousHusk then
        legacyEntry = Lifecycle.FindHuskEntry(zombie)
        if legacyEntry
            and tostring(legacyEntry.npcId or "") == tostring(record.id)
            and Lifecycle.IsLegacyAnonymousHusk(legacyEntry, zombie)
        then
            return "pre_materialize_legacy_ledger", legacyEntry
        end
    end
    if exactID or strong then
        matchedRecord, matchReason =
            Internal.ResolveRecordForStartupShell(
                Internal.registry(),
                zombie,
                npcId,
                strong,
                false
            )
        if matchedRecord == record
            and not (matchReason
                and string.sub(tostring(matchReason), 1, 10)
                    == "ambiguous_")
        then
            return "pre_materialize_"
                .. tostring(matchReason or "identified_shell")
        end
    end
    return nil
end

local function isUnresolvedUnmarkedBody(record, zombie)
    local npcId
    local strong
    local distance
    if not record or not zombie
        or Internal.IsProtectedBody(zombie)
        or Internal.IsCanonicalStartupBody(record, zombie)
    then
        return false
    end
    npcId, strong = Internal.GetLiveShellIdentity(zombie)
    if npcId ~= nil or strong == true then
        return false
    end
    distance = Internal.StartupDistanceSqToRecord(zombie, record)
    return distance ~= nil and distance <= (1.25 * 1.25)
end

function Lifecycle.CleanupRecordShells(record, now)
    local candidates
    local reason
    local ledgerEntry
    local removed = 0
    local blocked = false
    local staleRemoved
    local blockReason
    local batchBlocked
    local batchReason
    local unresolved
    local i
    now = tonumber(now) or Core.Now()
    if not Core.IsAuthority() or not record or record.alive == false then
        return 0, false, nil
    end
    if Lifecycle.IsStartupRecordBlocked then
        batchBlocked, batchReason =
            Lifecycle.IsStartupRecordBlocked(record, now)
        if batchBlocked then
            blocked = true
            blockReason = batchReason or "startup_batch_blocked"
        end
    end
    candidates = collectCandidates(record, now)
    for i = #candidates, 1, -1 do
        reason, ledgerEntry = removalReason(record, candidates[i])
        unresolved = isUnresolvedUnmarkedBody(record, candidates[i])
        if Lifecycle.IdentityAudit and Lifecycle.IdentityAudit.Capture
            and (reason ~= nil or unresolved)
        then
            Lifecycle.IdentityAudit.Capture(
                candidates[i],
                unresolved and "record_cleanup_unresolved_candidate"
                    or "record_cleanup_identified_candidate",
                record.id,
                true
            )
        end
        if reason then
            if Internal.RemoveStartupShell(
                record, candidates[i], reason, ledgerEntry
            ) then
                removed = removed + 1
            else
                -- A recognized shell must not be left in place while the
                -- materializer creates a replacement.  The next pass may
                -- succeed after the engine finishes attaching the body, but
                -- this pass is fail-closed to prevent duplicate NPC bodies.
                blocked = true
                blockReason = "recognized_shell_removal_failed"
            end
        elseif unresolved then
            -- No UUID, lease, carrier, body hint or ledger proof means this
            -- may simply be a vanilla zombie at the saved NPC position. Keep
            -- the record abstract until the body moves or gains a positive
            -- PNC identity; never delete it as a naked-position shortcut.
            blocked = true
            blockReason = blockReason or "unresolved_unmarked_body"
        end
    end
    staleRemoved = cleanupStaleManagedCorpses(record)
    return removed + staleRemoved, blocked, blockReason
end
