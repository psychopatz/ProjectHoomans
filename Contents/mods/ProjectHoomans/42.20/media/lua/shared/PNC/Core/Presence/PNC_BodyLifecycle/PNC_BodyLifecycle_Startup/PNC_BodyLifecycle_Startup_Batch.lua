-- Bounded startup reconciliation for restored IsoZombie bodies.
--
-- This module owns the per-pass body/record relationship.  Identity modules
-- describe what a body can prove; this module decides whether that proof is
-- unique enough to authorize cleanup.  Positional carrier matches are never
-- allowed to win greedily when several NPC records or several shells compete.

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

local function activeRecord(record)
    return record and record.alive ~= false
        and record.presenceState ~= Const.PRESENCE_CORPSE
end

local function expectsRehydration(record)
    return record and record.runtime
        and record.runtime.startupRehydrateExpected == true
end

if not Internal.MatchAnonymousStartupRehydrate
    or not Internal.ResolveStartupRehydrateGroup
then
    require "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup/PNC_BodyLifecycle_Startup_AnonymousRehydrate"
end

local function canonicalBody(reg, record)
    local zombie
    if not reg or not record or not reg.GetLiveZombie then
        return false
    end
    zombie = reg.GetLiveZombie(record.id)
    return zombie ~= nil
        and Internal.IsCanonicalStartupBody(record, zombie) == true
end

local function markBlocked(batch, record, reason)
    local id
    if not record or record.id == nil then
        return
    end
    id = tostring(record.id)
    if batch.blockedRecords[id] == nil then
        batch.blockedRecords[id] = tostring(reason or "ambiguous")
        batch.stats.blockedRecords = batch.stats.blockedRecords + 1
    end
end

local function addRecordMatch(batch, match)
    local id
    local group
    if not match or not match.record or match.record.id == nil then
        return
    end
    id = tostring(match.record.id)
    group = batch.recordMatches[id]
    if not group then
        group = { items = {}, positional = 0, rehydrate = 0 }
        batch.recordMatches[id] = group
    end
    group.items[#group.items + 1] = match
    if match.reason == "signature_position" then
        group.positional = group.positional + 1
    end
    if match.rehydrateEligible == true then
        group.rehydrate = group.rehydrate + 1
    end
end

local function chooseCandidate(candidates)
    local best
    local bestScore
    local topCount = 0
    local i
    if not candidates or #candidates <= 0 then
        return nil, nil
    end
    for i = 1, #candidates do
        if not bestScore or candidates[i].score > bestScore then
            best = candidates[i]
            bestScore = candidates[i].score
            topCount = 1
        elseif candidates[i].score == bestScore then
            topCount = topCount + 1
        end
    end
    if topCount > 1 then
        return nil, "ambiguous_identity"
    end
    if best.reason == "signature_position" and #candidates > 1 then
        return nil, "ambiguous_signature_position"
    end
    return best, nil
end

local function collectRecords(reg)
    local records = {}
    if not reg or not reg.ForEach then
        return records
    end
    reg.ForEach(function(record)
        if activeRecord(record) then
            records[#records + 1] = record
        end
    end)
    return records
end

local function nearbyUnmarkedRecords(records, reg, zombie)
    local output = {}
    local i
    local record
    local distance
    if not zombie then
        return output
    end
    for i = 1, #records do
        record = records[i]
        if not canonicalBody(reg, record) then
            distance = Internal.StartupDistanceSqToRecord(zombie, record)
            if distance ~= nil and distance <= (1.25 * 1.25) then
                output[#output + 1] = record
            end
        end
    end
    return output
end

local function snapshotCell()
    local cell = getCell and getCell() or nil
    local list = cell and cell.getZombieList and cell:getZombieList() or nil
    local bodies = {}
    local size
    local i
    if not list or not list.size or not list.get then
        return nil
    end
    size = list:size()
    for i = 0, size - 1 do
        bodies[#bodies + 1] = list:get(i)
    end
    return bodies
end

local function buildBatch(now)
    local reg = Internal.registry()
    local bodies
    local records
    local batch = {
        available = false,
        at = now,
        bodies = {},
        matches = {},
        canonical = {},
        ambiguousBodies = {},
        orphanStrong = {},
        orphanLedger = {},
        unknownBodies = {},
        anonymousRehydrate = {},
        blockedRecords = {},
        recordMatches = {},
        stats = {
            available = false,
            scanned = 0,
            matched = 0,
            ambiguous = 0,
            protected = 0,
            canonical = 0,
            ordinaryUnknown = 0,
            orphanSignatures = 0,
            blockedRecords = 0,
            pendingRehydrate = 0,
            unresolvedRehydrate = 0,
        },
    }
    local i
    local zombie
    local npcId
    local strong
    local weak
    local naked
    local legacyEntry
    local record
    local candidates
    local candidate
    local ambiguousReason
    local nearby
    local anonymousRecord
    local anonymousSettled

    if not Core.IsAuthority() or not reg or not reg.EnsureLoaded then
        return batch
    end
    reg.EnsureLoaded()
    bodies = snapshotCell()
    if not bodies then
        return batch
    end
    records = collectRecords(reg)
    batch.available = true
    batch.stats.available = true
    batch.bodies = bodies
    batch.stats.scanned = #bodies

    for i = 1, #bodies do
        zombie = bodies[i]
        if zombie then
            if Internal.IsProtectedBody(zombie) then
                batch.stats.protected = batch.stats.protected + 1
            else
                npcId, strong, weak = Internal.GetLiveShellIdentity(zombie)
                naked = Internal.IsNakedStartupShell(zombie)
                legacyEntry = nil
                candidates = nil

                if not strong and Lifecycle.FindHuskEntry
                    and Lifecycle.IsLegacyAnonymousHusk
                then
                    legacyEntry = Lifecycle.FindHuskEntry(zombie)
                    if legacyEntry
                        and Lifecycle.IsLegacyAnonymousHusk(
                            legacyEntry,
                            zombie
                        )
                    then
                        record = reg.Get and reg.Get(legacyEntry.npcId) or nil
                        if activeRecord(record) then
                            candidates = {
                                {
                                    record = record,
                                    reason = expectsRehydration(record)
                                        and "legacy_rehydrate"
                                        or "legacy_ledger",
                                    score = 400000,
                                    identity = true,
                                    ledgerEntry = legacyEntry,
                                },
                            }
                        else
                            batch.orphanLedger[zombie] = legacyEntry
                        end
                    end
                end

                -- A legacy persisted body hint is positive identity evidence
                -- even when the engine restored the shell without PNC
                -- ModData. Include naked shells in this bounded candidate
                -- pass so body_hint/population_id can reconcile them; the
                -- identity provider still rejects naked position-only
                -- matches.
                if not candidates and (npcId or strong or naked)
                    and Internal.GetStartupRecordCandidates
                then
                    candidates = Internal.GetStartupRecordCandidates(
                        reg,
                        zombie,
                        npcId,
                        strong,
                        naked
                    )
                end

                if candidates and #candidates > 0 then
                    candidate, ambiguousReason = chooseCandidate(candidates)
                    if candidate then
                        candidate.body = zombie
                        candidate.rehydrateTracked =
                            expectsRehydration(candidate.record)
                        candidate.rehydrateEligible =
                            candidate.reason == "population_id"
                            or (
                                candidate.rehydrateTracked == true
                                and candidate.identity == true
                                and (
                                    candidate.reason == "uuid"
                                    or candidate.reason == "body_hint"
                                    or candidate.reason == "legacy_rehydrate"
                                )
                            )
                        if Internal.IsCanonicalStartupBody(
                            candidate.record,
                            zombie
                        )
                        then
                            batch.canonical[zombie] = true
                            batch.stats.canonical = batch.stats.canonical + 1
                        else
                            batch.matches[zombie] = candidate
                            addRecordMatch(batch, candidate)
                        end
                    else
                        batch.ambiguousBodies[zombie] = {
                            reason = ambiguousReason
                                or "ambiguous_identity",
                            candidates = candidates,
                        }
                        batch.stats.ambiguous = batch.stats.ambiguous + 1
                        for index = 1, #candidates do
                            markBlocked(
                                batch,
                                candidates[index].record,
                                ambiguousReason
                                    or "ambiguous_identity"
                            )
                        end
                    end
                elseif strong or npcId then
                    -- A positive PNC marker/carrier with no surviving record
                    -- is safe to treat as a managed orphan. It is never the
                    -- same lane as an anonymous ordinary zombie.
                    if not batch.orphanLedger[zombie] then
                        batch.orphanStrong[zombie] = {
                            reason = "orphan_signature",
                        }
                        batch.stats.orphanSignatures =
                            batch.stats.orphanSignatures + 1
                    end
                else
                    -- PZ can restore a saved live shell before its
                    -- ModData/outfit identity is available. The role-agnostic
                    -- current-save lane may adopt exactly one anonymous body
                    -- at the saved live-body position after a real-frame
                    -- settle. Generic unknown-body handling stays fail-closed.
                    nearby = nearbyUnmarkedRecords(records, reg, zombie)
                    anonymousRecord = nil
                    anonymousSettled = false
                    if #nearby == 1 then
                        local eligible
                        eligible, anonymousSettled =
                            Internal.MatchAnonymousStartupRehydrate(
                                nearby[1], zombie, now
                            )
                        if eligible then
                            anonymousRecord = nearby[1]
                        end
                    end
                    if anonymousRecord then
                        if anonymousSettled then
                            candidate = {
                                record = anonymousRecord,
                                reason = "anonymous_rehydrate",
                                score = 1,
                                identity = false,
                                body = zombie,
                                rehydrateTracked = true,
                                rehydrateEligible = true,
                                anonymous = true,
                            }
                            batch.matches[zombie] = candidate
                            addRecordMatch(batch, candidate)
                            if Lifecycle.IdentityAudit
                                and Lifecycle.IdentityAudit.Capture
                            then
                                Lifecycle.IdentityAudit.Capture(
                                    zombie,
                                    "startup_anonymous_rehydrate_candidate",
                                    anonymousRecord.id,
                                    true
                                )
                            end
                        else
                            batch.anonymousRehydrate[zombie] = anonymousRecord
                            batch.unknownBodies[zombie] = nearby
                            batch.stats.unresolvedRehydrate =
                                batch.stats.unresolvedRehydrate + 1
                            markBlocked(
                                batch,
                                anonymousRecord,
                                "anonymous_rehydrate_settle"
                            )
                            if Lifecycle.IdentityAudit
                                and Lifecycle.IdentityAudit.Capture
                            then
                                Lifecycle.IdentityAudit.Capture(
                                    zombie,
                                    "startup_anonymous_rehydrate_settle",
                                    anonymousRecord.id,
                                    true
                                )
                            end
                        end
                    elseif naked and #nearby > 0 then
                        batch.unknownBodies[zombie] = nearby
                        batch.stats.ordinaryUnknown =
                            batch.stats.ordinaryUnknown + 1
                        if Lifecycle.IdentityAudit
                            and Lifecycle.IdentityAudit.Capture
                        then
                            Lifecycle.IdentityAudit.Capture(
                                zombie,
                                "startup_unknown_candidate",
                                nearby[1] and nearby[1].id or nil,
                                true
                            )
                        end
                        for index = 1, #nearby do
                            markBlocked(
                                batch,
                                nearby[index],
                                "unresolved_unmarked_body"
                            )
                        end
                    end
                end
            end
        end
    end

    -- Rehydration is one-to-one. The helper owns anonymous-adoption safety
    -- and winner selection; this batch only records blocking/pending state.
    local id
    local group
    local match
    local winner
    local anonymousAmbiguous
    for id, group in pairs(batch.recordMatches) do
        winner, anonymousAmbiguous =
            Internal.ResolveStartupRehydrateGroup(group)
        if anonymousAmbiguous then
            markBlocked(
                batch,
                group.items[1].record,
                "ambiguous_anonymous_rehydrate"
            )
        end
        if winner then
            winner.rehydrateWinner = true
            if winner.rehydrateTracked == true then
                batch.stats.pendingRehydrate =
                    batch.stats.pendingRehydrate + 1
                markBlocked(batch, winner.record, "rehydration_pending")
            end
        end

        -- A positional carrier match is safe only when it is one-to-one. If
        -- there is no positive rehydration winner and several shells compete,
        -- leave positional-only bodies in place and defer the record.
        if group.rehydrate <= 0
            and group.positional > 0
            and (#group.items > 1 or group.positional > 1)
        then
            markBlocked(batch, group.items[1].record,
                "ambiguous_record_shells")
            for i = 1, #group.items do
                match = group.items[i]
                if match.reason == "signature_position" then
                    match.disabled = true
                end
            end
        end
    end

    for zombie, match in pairs(batch.matches) do
        if not match.disabled then
            batch.stats.matched = batch.stats.matched + 1
        else
            batch.stats.ambiguous = batch.stats.ambiguous + 1
            batch.ambiguousBodies[zombie] = {
                reason = match.ambiguousReason
                    or "ambiguous_record_shells",
                candidates = { match },
            }
        end
    end
    return batch
end

function Lifecycle.BuildStartupBodyBatch(now, force)
    local state = Lifecycle.StartupCleanup
    local previous
    now = tonumber(now) or Core.Now()
    previous = state and state.lastBatch or nil
    if force ~= true and previous
        and now - (tonumber(previous.at) or 0) < 250
    then
        return previous
    end
    previous = buildBatch(now)
    if state then
        state.lastBatch = previous
    end
    return previous
end

function Lifecycle.GetStartupBodyBatch(now)
    return Lifecycle.BuildStartupBodyBatch(now, false)
end

function Lifecycle.IsStartupRecordBlocked(record, now)
    local batch
    local reason
    local group
    local i
    if not record or record.id == nil then
        return false, nil
    end
    batch = Lifecycle.GetStartupBodyBatch(now)
    if not batch or batch.available ~= true then
        return false, nil
    end
    reason = batch.blockedRecords[tostring(record.id)]
    if reason == "rehydration_pending" then
        return true, reason
    end
    if reason ~= nil then
        -- Let the record-local preflight remove a separate, positively
        -- identified shell first. The unmarked body still keeps the gate
        -- closed after that cleanup pass, so this does not authorize a
        -- replacement beside an unresolved ordinary zombie.
        group = batch.recordMatches[tostring(record.id)]
        if group then
            for i = 1, #group.items do
                if group.items[i].disabled ~= true then
                    return false, nil
                end
            end
        end
    end
    return reason ~= nil, reason
end

function Lifecycle.GetStartupBatchMatch(zombie, now)
    local batch = Lifecycle.GetStartupBodyBatch(now)
    if not batch or batch.available ~= true or not zombie then
        return nil, nil
    end
    if batch.ambiguousBodies[zombie] then
        return nil, batch.ambiguousBodies[zombie].reason
    end
    if batch.matches[zombie] and not batch.matches[zombie].disabled then
        return batch.matches[zombie], nil
    end
    if batch.orphanLedger[zombie] then
        return {
            reason = "legacy_ledger",
            ledgerEntry = batch.orphanLedger[zombie],
        }, nil
    end
    if batch.orphanStrong[zombie] then
        return batch.orphanStrong[zombie], nil
    end
    return nil, nil
end
