-- Live-body identity leases and removal transitions.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

function Lifecycle.StampLiveBody(record, zombie)
    local modData
    if not record or not zombie or not zombie.getModData then
        return nil
    end
    record.runtime = record.runtime or {}
    if not record.runtime.bodyLease or tostring(record.runtime.bodyLease) == "" then
        record.runtime.bodyLease = Core.GenerateID("body")
    end
    modData = zombie:getModData()
    modData.PNC_Owner = "ProjectHoomans"
    modData.PNC_OwnerVersion = 1
    modData.PNC_NPC = true
    modData.PNC_UUID = tostring(record.id)
    modData.PNC_BodyKind = "live"
    local factionID = PNC.Factions
        and type(PNC.Factions.GetFactionID) == "function"
        and PNC.Factions.GetFactionID(record) or nil
    modData.PNC_FactionID = factionID and tostring(factionID) or nil
    modData.PNC_BodyLease = tostring(record.runtime.bodyLease)
    modData.PNC_CorpseToken = nil
    modData.PNC_TagVersion = Const.BODY_TAG_VERSION
    modData.PNC_PersistedShell = true
    modData.PNC_ShellVersion = Const.BODY_SHELL_VERSION
    modData.PNC_BaseOutfit = "Naked"
    if PNC.RecipeKnowledge and PNC.RecipeKnowledge.BindLiveBody then
        PNC.RecipeKnowledge.BindLiveBody(record, zombie)
    end
    record.runtime.startupBodyHint = nil
    -- Remember the persistent outfit PNC uses for shells. It survives
    -- virtualization (unlike ModData) and is the only durable hint that a body
    -- later handed back by the population manager was one of ours.
    if Lifecycle.NoteShellOutfitID and zombie.getPersistentOutfitID then
        pcall(Lifecycle.NoteShellOutfitID, zombie:getPersistentOutfitID())
    end
    Internal.mark(record, "live", "bound", "body_stamped")
    return record.runtime.bodyLease
end

function Internal.detachLiveBody(record, reason)
    local reg = Internal.registry()
    if record then
        record.runtime = record.runtime or {}
        record.runtime.bodyLease = nil
        if reg and reg.LiveByID then
            reg.LiveByID[record.id] = nil
        end
        record.liveBodyInstanceID = nil
        record.liveBodyOnlineID = nil
        record.presenceRevision = (tonumber(record.presenceRevision) or 0) + 1
        if record.presenceState ~= Const.PRESENCE_CORPSE then
            record.presenceState = Const.PRESENCE_ABSTRACT
            Internal.mark(record, "abstract", "missing", reason or "body_removed")
        else
            Internal.mark(record, "corpse", "missing", reason or "source_body_removed")
        end
        if reg and reg.MarkDirty then
            reg.MarkDirty(record, "live_body_hint")
        end
    end
    return true
end

--[[
    True when a LIVE record's leased shell is no longer in the loaded world.

    The engine virtualizes an outdoor, ground-level shell that pathfinds outside
    the loaded area, and it virtualizes every shell of an unloading chunk. It
    persists only position, direction, persistent outfit id and state booleans,
    so the body that comes back is anonymous. A record in this state can never
    recover its body: presence must abstract it (the ledger/reaper lane then
    owns the husk), even when forceLive or a combat target would normally hold
    the record embodied.
]]
function Lifecycle.IsRecordBodyLost(record)
    local registry
    local zombie
    local runtime
    local now
    local graceMs
    if not record or record.presenceState ~= Const.PRESENCE_LIVE then
        return false
    end
    runtime = record.runtime
    if runtime and runtime.vehiclePassenger
        and runtime.vehiclePassenger.active == true
    then
        -- A boarding passenger intentionally has no body yet.
        return false
    end
    registry = Internal.registry and Internal.registry() or nil
    zombie = registry and registry.GetLiveZombie
        and registry.GetLiveZombie(record.id) or nil
    if zombie and Internal.isBodyAttached(zombie) == true then
        if runtime then
            runtime.bodyLostSince = nil
        end
        return false
    end
    -- An unleased LIVE record has no body to recover, so there is nothing to
    -- wait for.
    if runtime == nil or runtime.bodyLease == nil then
        return true
    end
    -- Losing a leased body is permanent once it happens, but a single
    -- square-less frame (engine cull, teleport in progress) must not abstract
    -- the record and arm a reap. Require the condition to persist across the
    -- grace window.
    now = Core and Core.Now and Core.Now() or 0
    graceMs = tonumber(Const.BODY_LOST_GRACE_MS) or 400
    if runtime.bodyLostSince == nil then
        runtime.bodyLostSince = now
    end
    if graceMs > 0
        and (now - (tonumber(runtime.bodyLostSince) or now)) < graceMs
    then
        return false
    end
    return true
end

--[[
    Release the live shell of `record`.

    Removal is verified and identity-guarded:
      * a handle that no longer matches the record's lease is never touched
        (the engine recycles removed IsoZombie objects, so a stale reference
        can point at an unrelated body),
      * a body that was already virtualized away, or whose removal did not
        take, is written to the husk ledger so the reaper can delete it when
        the population manager hands it back.
]]
function Lifecycle.RemoveLiveBody(record, zombie, reason)
    local attached
    local verified
    if zombie and Internal.matchesRecordBody
        and Internal.matchesRecordBody(record, zombie)
    then
        attached = Internal.isBodyAttached(zombie)
        verified = Internal.removeZombie(zombie) == true
        if (not attached or not verified) and Lifecycle.NoteLostBody then
            Lifecycle.NoteLostBody(
                record,
                zombie,
                verified and "removal_after_virtualization"
                    or "removal_unverified"
            )
        end
    elseif zombie then
        if Lifecycle.NoteLostBody then
            Lifecycle.NoteLostBody(record, zombie, "stale_body_handle")
        end
        if Core and Core.LogWarn then
            pcall(Core.LogWarn, "PNC live body handle rejected npc="
                .. tostring(record and record.id or "unknown")
                .. " reason=lease_mismatch release="
                .. tostring(reason or "abstract"))
        end
    elseif record and record.runtime and record.runtime.bodyLease ~= nil
        and Lifecycle.NoteLostBody
    then
        -- The lease survives but no handle does: the shell was virtualized and
        -- the engine holds an anonymous copy. Record the loss from the lease
        -- hint so the reaper can still delete the husk.
        Lifecycle.NoteLostBody(record, nil, "missing_body_handle")
    end
    return Internal.detachLiveBody(record, reason)
end
