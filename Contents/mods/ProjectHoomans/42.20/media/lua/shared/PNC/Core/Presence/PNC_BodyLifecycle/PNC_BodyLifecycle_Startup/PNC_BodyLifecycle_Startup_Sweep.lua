local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core

local function hasRehydrateClaim(record)
    local runtime = record and record.runtime or nil
    return runtime
        and (
            runtime.startupRehydrateExpected == true
            or runtime.lateStreamRehydrateExpected == true
        )
        or false
end

local function quarantineRehydrateCandidate(zombie, source)
    if not zombie then return end
    if PNC.LiveBodyControl
        and PNC.LiveBodyControl.ApplyHumanizedBodyFlags
    then
        PNC.LiveBodyControl.ApplyHumanizedBodyFlags(zombie)
        if PNC.LiveBodyControl.SuppressZombieSounds then
            PNC.LiveBodyControl.SuppressZombieSounds(zombie)
        end
    elseif Internal.clearBodyCombat then
        Internal.clearBodyCombat(zombie)
    end
    if PNC.LiveBodyControl
        and PNC.LiveBodyControl.EnforceManagedSafety
        and Core.IsManagedNPCBody
        and Core.IsManagedNPCBody(zombie)
    then
        PNC.LiveBodyControl.EnforceManagedSafety(
            zombie,
            source or "startup_rehydrate_quarantine"
        )
    end
end

Internal.QuarantineRehydrateCandidate = quarantineRehydrateCandidate

function Lifecycle.SweepPersistedLiveShells(now)
    local batch
    local stats
    local i
    local zombie
    local shellNpcId
    local strong
    local record
    local matchReason
    local passenger
    local legacyEntry
    local match
    local orphan
    now = tonumber(now) or Core.Now()
    batch = Lifecycle.BuildStartupBodyBatch(now, true)
    stats = batch and batch.stats or {
        available = false,
        scanned = 0,
        removed = 0,
        matched = 0,
    }
    stats.removed = 0
    stats.rebound = 0
    stats.blocked = 0
    if not batch or batch.available ~= true then
        return stats
    end

    -- An anonymous current-save body is not yet safe to adopt, but it is
    -- safe to make harmless while the engine finishes restoring the shell.
    -- This closes the hostile-zombie frame gap without role-specific logic.
    for anonymousBody in pairs(batch.anonymousRehydrate or {}) do
        quarantineRehydrateCandidate(
            anonymousBody,
            "startup_anonymous_rehydrate_settle"
        )
    end

    -- Rehydrate winners before deleting any competing shell. This makes the
    -- saved live body claim atomic from the perspective of the second cleanup
    -- pass: once one body is rebound, every other proven body for that record
    -- is unambiguously a duplicate.
    for i = 1, #batch.bodies do
        zombie = batch.bodies[i]
        match = batch.matches[zombie]
        if match and not match.disabled
            and match.rehydrateWinner == true
        then
            record = match.record
            passenger = record and record.runtime
                and record.runtime.vehiclePassenger or nil
            if not (passenger and passenger.active == true)
                and not Internal.IsCanonicalStartupBody(record, zombie)
            then
                if match.rehydrateTracked == true then
                    quarantineRehydrateCandidate(
                        zombie,
                        "startup_rehydrate_candidate"
                    )
                end
                if PNC.Presence and PNC.Presence.RebindRestoredBody
                    and PNC.Presence.RebindRestoredBody(
                        record,
                        zombie,
                        "startup_" .. tostring(match.reason or "rehydrate")
                    )
                then
                    match.rebound = true
                    stats.rebound = stats.rebound + 1
                    if Core and Core.LogInfo then
                        Core.LogInfo(
                            "PNC startup_rehydrate_rebound npc="
                                .. tostring(record.id)
                                .. " reason="
                                .. tostring(match.reason or "rehydrate")
                                .. " anonymous="
                                .. tostring(match.anonymous == true)
                        )
                    end
                    record.runtime.startupRehydrateExpected = nil
                    record.runtime.startupRehydrateMissed = nil
                    if match.ledgerEntry and Lifecycle.ConsumeHuskEntry then
                        Lifecycle.ConsumeHuskEntry(match.ledgerEntry)
                    end
                else
                    match.rebindFailed = true
                    if match.rehydrateTracked == true then
                        -- Do not destroy the only viable restored body because
                        -- a transient configure/engine call failed. Keep it
                        -- harmless and retry on the next startup pass.
                        stats.blocked = stats.blocked + 1
                    end
                end
            end
        end
    end

    -- batch.bodies is a snapshot. The removal API verifies detachment, so a
    -- body removed earlier in this pass is harmless if a later engine callback
    -- still exposes the stale reference.
    for i = 1, #batch.bodies do
        zombie = batch.bodies[i]
        match = batch.matches[zombie]
        legacyEntry = match and match.ledgerEntry or batch.orphanLedger[zombie]
        orphan = batch.orphanStrong[zombie]
        if match and not match.disabled then
            record = match.record
            matchReason = match.reason
            shellNpcId, strong = Internal.GetLiveShellIdentity(zombie)
            passenger = record and record.runtime
                and record.runtime.vehiclePassenger or nil
            if not Internal.IsCanonicalStartupBody(record, zombie) then
                if match.rebound == true then
                    -- Rebind succeeded in the first pass. Trust that result
                    -- for this snapshot even if a lightweight test/provider
                    -- does not expose the registry pointer immediately.
                elseif match.rehydrateWinner == true
                    and match.rebindFailed == true
                    and match.rehydrateTracked == true
                then
                    quarantineRehydrateCandidate(
                        zombie,
                        "startup_rehydrate_retry"
                    )
                elseif match.rehydrateWinner == true
                    and match.rebindFailed == true
                then
                    if Internal.RemoveStartupShell(
                        record,
                        zombie,
                        "startup_rebind_failed",
                        legacyEntry
                    ) then
                        stats.removed = stats.removed + 1
                    else
                        stats.blocked = stats.blocked + 1
                    end
                elseif match.rehydrateDuplicate == true then
                    if Internal.RemoveStartupShell(
                        record,
                        zombie,
                        "startup_rehydrate_duplicate",
                        legacyEntry
                    ) then
                        stats.removed = stats.removed + 1
                    else
                        stats.blocked = stats.blocked + 1
                    end
                elseif matchReason == "legacy_ledger" then
                    if Internal.RemoveStartupShell(
                        record,
                        zombie,
                        "startup_legacy_ledger",
                        legacyEntry
                    ) then
                        stats.removed = stats.removed + 1
                    else
                        stats.blocked = stats.blocked + 1
                    end
                elseif passenger and passenger.active == true
                    and (strong == true or match.identity == true)
                then
                    -- Vehicle passengers intentionally remain bodyless. Only
                    -- an identified PNC shell may be removed in this lane.
                    if Internal.RemoveStartupShell(
                        record,
                        zombie,
                        "startup_vehicle_passenger",
                        legacyEntry
                    ) then
                        stats.removed = stats.removed + 1
                    else
                        stats.blocked = stats.blocked + 1
                    end
                elseif match.rehydrateWinner == true then
                    -- A successful winner is canonical by now. Reaching this
                    -- branch means ownership could not be proven; fail closed.
                    quarantineRehydrateCandidate(
                        zombie,
                        "startup_rehydrate_unresolved"
                    )
                    stats.blocked = stats.blocked + 1
                elseif Internal.RemoveStartupShell(
                    record,
                    zombie,
                    "startup_" .. tostring(matchReason or "shell"),
                    legacyEntry
                ) then
                    stats.removed = stats.removed + 1
                else
                    stats.blocked = stats.blocked + 1
                end
            end
        elseif legacyEntry then
            -- A legacy ledger entry can survive after its NPC record was
            -- deleted. Its exact ledger proof still permits orphan cleanup.
            if Internal.RemoveStartupShell(
                nil,
                zombie,
                "startup_legacy_orphan",
                legacyEntry
            ) then
                stats.removed = stats.removed + 1
            else
                stats.blocked = stats.blocked + 1
            end
        elseif orphan then
            if Internal.RemoveStartupShell(
                nil,
                zombie,
                orphan.reason or "startup_orphan_signature"
            ) then
                stats.removed = stats.removed + 1
            else
                stats.blocked = stats.blocked + 1
            end
        end
    end
    return stats
end

function Lifecycle.InterceptLoadedShell(zombie, source)
    local reg = Internal.registry()
    local registryWasLoaded
    local npcId
    local strong
    local weak
    local naked
    local record
    local matchReason
    local legacyEntry
    if not zombie or (zombie.isDead and zombie:isDead()) then
        return false
    end
    if Internal.IsProtectedBody and Internal.IsProtectedBody(zombie) then
        return false
    end
    if not Core.IsAuthority() then
        if Core.IsManagedNPCBody and Core.IsManagedNPCBody(zombie)
            and PNC.LiveBodyControl
            and PNC.LiveBodyControl.EnforceManagedSafety
        then
            PNC.LiveBodyControl.EnforceManagedSafety(
                zombie,
                source or "early_client_shell"
            )
        end
        return false
    end
    if not reg or not reg.EnsureLoaded then
        return false
    end
    registryWasLoaded = reg.Loaded == true
    reg.EnsureLoaded()
    if not registryWasLoaded then
        Lifecycle.StartupCleanup.earlyRegistryLoad = true
    end
    -- OnZombieUpdate can precede OnGameStart. Seed the current-save body hint
    -- now so a zero-ID restored shell can be proven and neutralized before it
    -- receives a vanilla hostile update. If this load was provisional, the
    -- world-ready coordinator resets the once-per-session guard and reseeds
    -- after the definitive registry reload.
    if Lifecycle.SeedHuskLedgerFromRecords then
        Lifecycle.SeedHuskLedgerFromRecords(Core.Now())
    end
    if Lifecycle.StartupCleanup.begun ~= true then
        Lifecycle.BeginStartupBodyCleanup(Core.Now(), false)
    end
    npcId, strong, weak = Internal.GetLiveShellIdentity(zombie)
    naked = Internal.IsNakedStartupShell(zombie)

    -- Dedicated restart shells may first become real only when a player
    -- streams their saved chunk. Give the bounded late-stream claim first
    -- chance to quarantine/rebind an identity-stripped carrier.
    if not strong
        and npcId == nil
        and Lifecycle.InterceptLateStreamRehydrateBody
        and Lifecycle.InterceptLateStreamRehydrateBody(
            zombie,
            Core.Now(),
            source
        )
    then
        return false
    end

    if not strong and Lifecycle.FindHuskEntry
        and Lifecycle.IsLegacyAnonymousHusk
    then
        legacyEntry = Lifecycle.FindHuskEntry(zombie)
        if legacyEntry
            and Lifecycle.IsLegacyAnonymousHusk(legacyEntry, zombie)
        then
            record = reg.Get and reg.Get(legacyEntry.npcId) or nil
            if hasRehydrateClaim(record)
                and not Internal.IsCanonicalStartupBody(record, zombie)
            then
                quarantineRehydrateCandidate(
                    zombie,
                    tostring(source or "early_shell") .. "_rehydrate_pending"
                )
                return false
            end
            if record and not Internal.IsCanonicalStartupBody(record, zombie) then
                return Internal.RemoveStartupShell(
                    record,
                    zombie,
                    tostring(source or "late_legacy_shell") .. "_legacy_ledger",
                    legacyEntry
                )
            elseif not record then
                return Internal.RemoveStartupShell(
                    nil,
                    zombie,
                    tostring(source or "late_legacy_shell") .. "_legacy_orphan",
                    legacyEntry
                )
            end
        end
    end
    -- Marked PNC bodies remain cheap to recognize throughout play. A naked
    -- restored shell may still carry a positive persisted body hint even when
    -- the engine dropped every PNC marker; let the identity provider consume
    -- that hint while continuing to reject ordinary position-only zombies.
    if not strong then
        if naked and Internal.ResolveRecordForStartupShell then
            record, matchReason = Internal.ResolveRecordForStartupShell(
                reg, zombie, npcId, strong, naked
            )
            if record and not (matchReason
                and string.sub(tostring(matchReason), 1, 10)
                    == "ambiguous_")
                and not Internal.IsCanonicalStartupBody(record, zombie)
            then
                if hasRehydrateClaim(record) then
                    quarantineRehydrateCandidate(
                        zombie,
                        tostring(source or "early_shell")
                            .. "_rehydrate_pending"
                    )
                    return false
                end
                return Internal.RemoveStartupShell(
                    record,
                    zombie,
                    tostring(source or "early_shell") .. "_"
                        .. tostring(matchReason or "matched")
                )
            end
        end
        return false
    end
    record, matchReason = Internal.ResolveRecordForStartupShell(reg, zombie, npcId, strong, naked)
    if matchReason and string.sub(tostring(matchReason), 1, 10)
        == "ambiguous_"
    then
        return false
    end
    if record and not Internal.IsCanonicalStartupBody(record, zombie) then
        if hasRehydrateClaim(record) then
            quarantineRehydrateCandidate(
                zombie,
                tostring(source or "early_shell") .. "_rehydrate_pending"
            )
            return false
        end
        return Internal.RemoveStartupShell(
            record,
            zombie,
            tostring(source or "early_shell") .. "_"
                .. tostring(matchReason or "matched")
        )
    end
    if strong and not record then
        return Internal.RemoveStartupShell(
            nil,
            zombie,
            tostring(source or "early_shell") .. "_orphan_signature"
        )
    end
    return false
end
