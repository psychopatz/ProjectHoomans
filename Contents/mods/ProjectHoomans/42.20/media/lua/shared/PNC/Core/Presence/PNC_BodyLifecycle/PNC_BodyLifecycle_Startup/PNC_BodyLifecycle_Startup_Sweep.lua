local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core

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

    -- `batch.bodies` is a snapshot. The removal API verifies detachment, so a
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
                if matchReason == "legacy_ledger" then
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
                elseif matchReason == "population_id"
                    and PNC.Presence
                    and PNC.Presence.RebindRestoredBody
                then
                    if PNC.Presence.RebindRestoredBody(
                        record,
                        zombie,
                        "startup_population_rebind"
                    ) then
                        stats.rebound = stats.rebound + 1
                    elseif Internal.RemoveStartupShell(
                        record,
                        zombie,
                        "startup_rebind_failed"
                    ) then
                        stats.removed = stats.removed + 1
                    else
                        stats.blocked = stats.blocked + 1
                    end
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
    if Lifecycle.StartupCleanup.begun ~= true then
        Lifecycle.BeginStartupBodyCleanup(Core.Now(), false)
    end
    npcId, strong, weak = Internal.GetLiveShellIdentity(zombie)
    naked = Internal.IsNakedStartupShell(zombie)
    if not strong and Lifecycle.FindHuskEntry
        and Lifecycle.IsLegacyAnonymousHusk
    then
        legacyEntry = Lifecycle.FindHuskEntry(zombie)
        if legacyEntry
            and Lifecycle.IsLegacyAnonymousHusk(legacyEntry, zombie)
        then
            record = reg.Get and reg.Get(legacyEntry.npcId) or nil
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
    -- Marked PNC bodies remain cheap to recognize throughout play. An
    -- anonymous body has no deletion proof here; record-local materialization
    -- preflight may defer a replacement, but it must not turn an ordinary
    -- zombie into a cleanup candidate.
    if not strong then
        return false
    end
    record, matchReason = Internal.ResolveRecordForStartupShell(reg, zombie, npcId, strong, naked)
    if matchReason and string.sub(tostring(matchReason), 1, 10)
        == "ambiguous_"
    then
        return false
    end
    if record and not Internal.IsCanonicalStartupBody(record, zombie) then
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
