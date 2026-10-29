-- Live-body identity leases and removal transitions.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

-- MP replicas cannot inherit server object identity. Keep one process-local,
-- weak shell receipt so restored/provider leases cannot be reused for a new
-- physical incarnation. SP deliberately retains its local lease semantics.
local shellReceipts = setmetatable({}, { __mode = "k" })
local shellSerial = 0
local function ensureIncarnation(record, zombie, runtime)
    if not isServer or isServer() ~= true then
        if not runtime.bodyLease or tostring(runtime.bodyLease) == "" then
            runtime.bodyLease = Core.GenerateID("body")
        end
        return
    end
    local receipt = shellReceipts[zombie]
    if receipt and receipt.id == record.id and runtime.bodyLease ~= nil then
        runtime.bodyLease = receipt.lease
        return
    end
    shellSerial = shellSerial + 1
    runtime.bodyLease = Core.GenerateID("body") .. "_" .. tostring(shellSerial)
    shellReceipts[zombie] = { id = record.id, lease = runtime.bodyLease }
end

local function validEngineIdentity(value)
    local numeric
    if value == nil or tostring(value) == "" or tostring(value) == "0" then
        return false
    end
    numeric = tonumber(value)
    return numeric == nil or numeric ~= 0
end

local function readPersistentOutfitID(zombie)
    local ok
    local value
    if not zombie or not zombie.getPersistentOutfitID then
        return nil, false
    end
    ok, value = pcall(zombie.getPersistentOutfitID, zombie)
    if not ok then
        return nil, true
    end
    return validEngineIdentity(value) and tostring(value) or nil, true
end

local function carrierIdentityAllowed(zombie, source)
    local modData
    if source == "body_stamp" then
        return true
    end
    if not zombie or not zombie.getModData then
        return false
    end
    local ok, value = pcall(function()
        modData = zombie:getModData()
        return modData and modData.PNC_ShellCarrier or nil
    end)
    return ok and value ~= nil
        and tostring(value) == tostring(Const.BODY_SHELL_OUTFIT)
end

-- Capture identity after the engine has finished registering the body. The
-- create event is too early for populationId on PZ: createRealZombieAlways
-- fires OnZombieCreate before ZombiePopulationManager.registerZombie. This
-- helper is therefore also called by the loaded-body audit on later ticks.
function Lifecycle.RefreshLiveBodyIdentity(record, zombie, source)
    local outfitID
    local outfitAPI
    local populationID
    local changed = false
    local runtime
    local carrierAllowed
    if not record or not zombie then
        return false
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    runtime.identityCaptureAttempts =
        (tonumber(runtime.identityCaptureAttempts) or 0) + 1
    outfitID, outfitAPI = readPersistentOutfitID(zombie)
    if outfitID ~= nil and record.liveBodyInstanceID ~= outfitID then
        record.liveBodyInstanceID = outfitID
        changed = true
    end
    if Lifecycle.GetBodyPopulationID then
    populationID = Lifecycle.GetBodyPopulationID(zombie)
    end
    if validEngineIdentity(populationID)
        and record.liveBodyPopulationID ~= tostring(populationID)
    then
        record.liveBodyPopulationID = tostring(populationID)
        changed = true
    end
    runtime.lastIdentitySource = tostring(source or "unknown")
    runtime.lastIdentityAt = Core.Now and Core.Now() or 0
    if outfitID ~= nil then
        runtime.lastIdentityOutfitID = outfitID
        carrierAllowed = carrierIdentityAllowed(zombie, source)
        if carrierAllowed and Lifecycle.NoteShellCarrierID then
            pcall(Lifecycle.NoteShellCarrierID, outfitID)
        elseif Lifecycle.NoteShellOutfitID then
            pcall(Lifecycle.NoteShellOutfitID, outfitID)
        end
    end
    if validEngineIdentity(populationID) then
        runtime.lastIdentityPopulationID = tostring(populationID)
    end
    if changed then
        local registry = Internal.registry and Internal.registry() or nil
        if source ~= "body_stamp" and registry and registry.MarkDirty then
            registry.MarkDirty(record, "live_body_identity")
        end
        if Core.LogInfo then
            pcall(Core.LogInfo, "PNC live_body_identity npc="
                .. tostring(record.id)
                .. " source=" .. tostring(source or "unknown")
                .. " outfitID=" .. tostring(outfitID or "nil")
                .. " populationID=" .. tostring(populationID or "nil"))
        end
    elseif outfitAPI and outfitID == nil
        and runtime.identityUnavailableFor ~= tostring(runtime.bodyLease or "")
    then
        -- One warning per body lease is enough to expose the engine boundary
        -- without turning the audit pump into a log generator.
        runtime.identityUnavailableFor = tostring(runtime.bodyLease or "")
        if Core.LogWarn then
            pcall(Core.LogWarn, "PNC live_body_identity_unavailable npc="
                .. tostring(record.id)
                .. " source=" .. tostring(source or "unknown")
                .. " outfitID=0_or_nil populationID="
                .. tostring(populationID or "nil"))
        end
    end
    return outfitID ~= nil or validEngineIdentity(populationID)
end

function Lifecycle.StampLiveBody(record, zombie)
    local modData
    local runtime
    local restoredBodyRebind
    local startupBodyHint
    if not record or not zombie or not zombie.getModData then
        return nil
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    restoredBodyRebind = runtime.restoredBodyRebindPending == true
    startupBodyHint = restoredBodyRebind and runtime.startupBodyHint or nil
    ensureIncarnation(record, zombie, runtime)
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
    modData.PNC_BodyLease = tostring(runtime.bodyLease)
    modData.PNC_CorpseToken = nil
    modData.PNC_TagVersion = Const.BODY_TAG_VERSION
    modData.PNC_PersistedShell = true
    modData.PNC_ShellVersion = Const.BODY_SHELL_VERSION
    modData.PNC_ShellCarrier = Const.BODY_SHELL_OUTFIT
    modData.PNC_ShellCarrierVersion = Const.BODY_SHELL_CARRIER_VERSION
    modData.PNC_BaseOutfit = Const.BODY_SHELL_OUTFIT
    if PNC.RecipeKnowledge and PNC.RecipeKnowledge.BindLiveBody then
        PNC.RecipeKnowledge.BindLiveBody(record, zombie)
    end
    record.runtime.startupBodyHint = nil
    record.liveBodyInstanceID = nil
    record.liveBodyPopulationID = nil
    record.runtime.lastIdentitySource = nil
    record.runtime.lastIdentityOutfitID = nil
    record.runtime.lastIdentityPopulationID = nil
    record.runtime.identityUnavailableFor = nil
    Lifecycle.RefreshLiveBodyIdentity(record, zombie, "body_stamp")
    if restoredBodyRebind and startupBodyHint then
        -- A population-restored body may expose outfit/persistent ids one or
        -- more ticks after the rebind. Keep only the fields that the engine
        -- did not provide; a conflicting live engine value always wins.
        if record.liveBodyInstanceID == nil
            and validEngineIdentity(startupBodyHint.instanceID)
        then
            record.liveBodyInstanceID = tostring(startupBodyHint.instanceID)
        end
        if record.liveBodyPopulationID == nil
            and validEngineIdentity(startupBodyHint.populationId)
        then
            record.liveBodyPopulationID = tostring(startupBodyHint.populationId)
        end
        if record.liveBodyInstanceID ~= nil
            or record.liveBodyPopulationID ~= nil
        then
            runtime.lastIdentitySource = "restored_body_hint"
            runtime.lastIdentityOutfitID = record.liveBodyInstanceID
            runtime.lastIdentityPopulationID = record.liveBodyPopulationID
            runtime.lastLiveBodyInstanceID = record.liveBodyInstanceID
            runtime.lastLiveBodyPopulationID = record.liveBodyPopulationID
            runtime.lastLiveBodyOnlineID = record.liveBodyOnlineID
            runtime.lastLiveBodyLease = runtime.bodyLease
        end
    end
    if Lifecycle.IdentityAudit and Lifecycle.IdentityAudit.Capture then
        Lifecycle.IdentityAudit.Capture(
            zombie,
            "body_stamp",
            record.id,
            true
        )
    end
    local registry = Internal.registry and Internal.registry() or nil
    if registry and registry.MarkDirty then
        registry.MarkDirty(record, "live_body_hint")
    end
    Internal.mark(record, "live", "bound", "body_stamped")
    return runtime.bodyLease
end

local function captureDetachedBodyHint(record)
    local runtime
    local previous
    local instanceID
    local populationID
    local onlineID
    local lease
    local x
    local y
    local z
    if not record then
        return nil
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    previous = runtime.startupBodyHint
    instanceID = record.liveBodyInstanceID
        or runtime.lastLiveBodyInstanceID
        or previous and previous.instanceID or nil
    populationID = record.liveBodyPopulationID
        or runtime.lastLiveBodyPopulationID
        or previous and previous.populationId or nil
    onlineID = record.liveBodyOnlineID
        or runtime.lastLiveBodyOnlineID
        or previous and previous.onlineID or nil
    lease = runtime.bodyLease
        or runtime.lastLiveBodyLease
        or previous and previous.lease or nil
    x = record.x
    y = record.y
    z = record.z
    if x == nil and previous then x = previous.x end
    if y == nil and previous then y = previous.y end
    if z == nil and previous then z = previous.z end
    runtime.lastLiveBodyInstanceID = instanceID
    runtime.lastLiveBodyPopulationID = populationID
    runtime.lastLiveBodyOnlineID = onlineID
    runtime.lastLiveBodyLease = lease
    runtime.lastLiveBodyX = x
    runtime.lastLiveBodyY = y
    runtime.lastLiveBodyZ = z
    if instanceID ~= nil or populationID ~= nil then
        runtime.startupBodyHint = {
            instanceID = instanceID,
            onlineID = onlineID,
            lease = lease,
            populationId = populationID,
            x = x,
            y = y,
            z = z,
        }
    end
    return runtime.startupBodyHint
end

Internal.CaptureDetachedBodyHint = captureDetachedBodyHint

function Internal.detachLiveBody(record, reason)
    local reg = Internal.registry()
    if record then
        record.runtime = record.runtime or {}
        -- Keep the last engine identity alive long enough for the record
        -- serializer to persist it. PZ may restore the removed shell after a
        -- relog even when removeZombie() reported a successful detach.
        captureDetachedBodyHint(record)
        record.runtime.bodyReleasePending = nil
        record.runtime.bodyReleaseAttempts = nil
        record.runtime.bodyReleaseLastAt = nil
        record.runtime.bodyReleaseLastReason = nil
        record.runtime.bodyLease = nil
        if reg and reg.LiveByID then
            reg.LiveByID[record.id] = nil
        end
        record.liveBodyInstanceID = nil
        record.liveBodyPopulationID = nil
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
    local runtime
    if zombie and Internal.matchesRecordBody
        and Internal.matchesRecordBody(record, zombie)
    then
        attached = Internal.isBodyAttached(zombie)
        verified = Internal.removeZombie(zombie) == true
        if Lifecycle.IdentityAudit and Lifecycle.IdentityAudit.RecordRemoval then
            Lifecycle.IdentityAudit.RecordRemoval(
                zombie,
                "live_body_removal",
                record and record.id or nil,
                reason,
                verified
            )
        end
        -- An attached body that failed engine removal is still owned by this
        -- record. Do not clear its lease and turn it into an abstract record:
        -- the loaded-body audit would then see a marked, ownerless zombie and
        -- the husk reaper would intentionally skip it. Keep the lease and
        -- retry the direct removal on a later audit/reconcile pass instead.
        if attached and not verified then
            runtime = record and (record.runtime or {}) or nil
            if record then record.runtime = runtime end
            if runtime then
                runtime.bodyReleasePending = true
                runtime.bodyReleaseAttempts =
                    (tonumber(runtime.bodyReleaseAttempts) or 0) + 1
                runtime.bodyReleaseLastAt = Core and Core.Now
                    and Core.Now() or 0
                runtime.bodyReleaseLastReason = tostring(
                    reason or "removal_unverified")
            end
            if Internal.mark then
                Internal.mark(
                    record,
                    "live",
                    "release_pending",
                    "body_removal_unverified"
                )
            end
            return false
        end
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
