local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core

function Lifecycle.SweepPersistedLiveShells(now)
    local reg = Internal.registry()
    local cell
    local zombieList
    local stats = { available = false, scanned = 0, removed = 0, matched = 0 }
    local i
    local zombie
    local npcId
    local strong
    local weak
    local naked
    local record
    local matchReason
    now = tonumber(now) or Core.Now()
    if not Core.IsAuthority() or not reg or not reg.EnsureLoaded then
        return stats
    end
    reg.EnsureLoaded()
    cell = getCell and getCell() or nil
    zombieList = cell and cell.getZombieList and cell:getZombieList() or nil
    if not zombieList then
        return stats
    end
    stats.available = true
    for i = zombieList:size() - 1, 0, -1 do
        zombie = zombieList:get(i)
        npcId, strong, weak = Internal.GetLiveShellIdentity(zombie)
        naked = Internal.IsNakedStartupShell(zombie)
        -- Unmarked naked-zombie correlation is a startup-only sweep. Distant
        -- cells loaded later use the record-local materialization preflight,
        -- avoiding an O(naked zombies * NPC records) steady-state scan.
        if strong or (Lifecycle.StartupCleanup.active == true and naked) then
            stats.scanned = stats.scanned + 1
            record, matchReason = Internal.ResolveRecordForStartupShell(reg, zombie, npcId, strong, naked)
            if (record and not Internal.IsCanonicalStartupBody(record, zombie))
                or (strong and not record)
            then
                stats.matched = stats.matched + 1
                Internal.RemoveStartupShell(
                    record,
                    zombie,
                    record and ("startup_" .. tostring(matchReason or "shell"))
                        or "startup_orphan_signature"
                )
                stats.removed = stats.removed + 1
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
    if not zombie or (zombie.isDead and zombie:isDead()) then
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
    -- Marked PNC bodies remain cheap to recognize throughout play. Expensive
    -- positional correlation for unmarked naked shells is restricted to the
    -- startup gate; later streamed cells use CleanupRecordShells immediately
    -- before their record can materialize.
    if not strong
        and not (Lifecycle.StartupCleanup.active == true and naked)
    then
        return false
    end
    record, matchReason = Internal.ResolveRecordForStartupShell(reg, zombie, npcId, strong, naked)
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
