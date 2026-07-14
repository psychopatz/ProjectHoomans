-- Loaded-world reconciliation for live bodies and reanimated corpse bodies.

PNC = PNC or {}
PNC.BodyLifecycle = PNC.BodyLifecycle or {}
PNC.BodyLifecycle.Internal = PNC.BodyLifecycle.Internal or {}

local Lifecycle = PNC.BodyLifecycle
local Internal = Lifecycle.Internal
local Core = PNC.Core
local Const = PNC.Const

function Lifecycle.AuditLoadedBodies(now, force)
    local reg = Internal.registry()
    local cell
    local zombieList
    local accepted = {}
    local stats = { scanned = 0, removed = 0, rebound = 0, duplicates = 0, corpses = 0 }
    local i
    local zombie
    local modData
    local npcId
    local kind
    local lease
    local tagVersion
    local record
    local expected
    now = tonumber(now) or Core.Now()
    if not Core.IsAuthority() or not reg or not reg.EnsureLoaded then
        return stats
    end
    if not force and now < (tonumber(Lifecycle.NextAuditAt) or 0) then
        Internal.pumpPendingCorpses()
        return Lifecycle.LastAudit
    end
    Lifecycle.NextAuditAt = now + (tonumber(Const.BODY_AUDIT_INTERVAL_MS) or 250)
    reg.EnsureLoaded()
    cell = getCell and getCell() or nil
    zombieList = cell and cell.getZombieList and cell:getZombieList() or nil
    if zombieList then
        for i = zombieList:size() - 1, 0, -1 do
            zombie = zombieList:get(i)
            modData = zombie and zombie.getModData and zombie:getModData() or nil
            if modData and modData.PNC_NPC == true then
                stats.scanned = stats.scanned + 1
                npcId = modData.PNC_UUID and tostring(modData.PNC_UUID) or nil
                kind = tostring(modData.PNC_BodyKind or "live")
                lease = modData.PNC_BodyLease and tostring(modData.PNC_BodyLease) or nil
                tagVersion = tonumber(modData.PNC_TagVersion)
                record = npcId and reg.Get(npcId) or nil
                if kind == "corpse" and record and record.alive == false then
                    stats.corpses = stats.corpses + 1
                    local infection = record.health and record.health.body and record.health.body.infection or nil
                    if infection and infection.fatal == true and Lifecycle.ReleaseReanimatedNPC then
                        Lifecycle.ReleaseReanimatedNPC(record, zombie)
                    else
                        record.runtime = record.runtime or {}
                        record.runtime.corpseRecoveryAttempts = (tonumber(record.runtime.corpseRecoveryAttempts) or 0) + 1
                        if record.runtime.corpseRecoveryAttempts <= (tonumber(Const.CORPSE_REANIMATE_RETRY_MAX) or 3) then
                            Lifecycle.CreateInertCorpse(record, zombie, "corpse_reanimated")
                        else
                            Internal.removeZombie(zombie)
                            Internal.ensureRuntime(record).corpseState = "missing"
                            Internal.mark(record, "corpse", "stale_cleaned", "corpse_recovery_capped", "reanimation_retry_limit")
                        end
                    end
                elseif kind == "live"
                    and record
                    and record.alive ~= false
                    and record.presenceState == Const.PRESENCE_LIVE
                    and record.runtime
                    and record.runtime.bodyLease
                    and lease == tostring(record.runtime.bodyLease)
                    and tagVersion == tonumber(Const.BODY_TAG_VERSION)
                then
                    if not accepted[npcId] then
                        accepted[npcId] = zombie
                        expected = reg.LiveByID and reg.LiveByID[npcId] or nil
                        if expected ~= zombie then
                            reg.LiveByID[npcId] = zombie
                            record.liveBodyInstanceID = zombie.getPersistentOutfitID and zombie:getPersistentOutfitID() or nil
                            record.liveBodyOnlineID = Internal.normalizeOnlineID(zombie)
                            stats.rebound = stats.rebound + 1
                        end
                        Internal.ensureRuntime(record).lastAuditAt = now
                        Internal.mark(record, "live", "bound", "body_audit_valid")
                    else
                        stats.duplicates = stats.duplicates + 1
                        stats.removed = stats.removed + 1
                        Internal.noteCleanup(record, "duplicate", "duplicate_lease_removed")
                        Internal.removeZombie(zombie)
                    end
                else
                    stats.removed = stats.removed + 1
                    if record then
                        Internal.noteCleanup(record, "stale_cleaned", "orphan_body_removed")
                        Internal.mark(record, record.presenceState, "stale_cleaned", "orphan_body_removed")
                    end
                    Internal.removeZombie(zombie)
                end
            end
        end
    end
    if zombieList then
        reg.ForEach(function(candidate)
            local id = tostring(candidate.id)
            local registered = reg.LiveByID and reg.LiveByID[id] or nil
            if candidate.presenceState == Const.PRESENCE_LIVE and not accepted[id] then
                if registered then
                    Internal.removeZombie(registered)
                end
                reg.LiveByID[id] = nil
                candidate.runtime = candidate.runtime or {}
                candidate.runtime.bodyLease = nil
                candidate.liveBodyInstanceID = nil
                candidate.liveBodyOnlineID = nil
                candidate.presenceState = Const.PRESENCE_ABSTRACT
                candidate.presenceRevision = (tonumber(candidate.presenceRevision) or 0) + 1
                Internal.mark(candidate, "abstract", "missing", registered and "body_invalid" or "body_pruned")
            end
        end)
    end
    Internal.pumpPendingCorpses()
    if force or now >= (tonumber(Lifecycle.NextCorpseAuditAt) or 0) then
        Lifecycle.NextCorpseAuditAt = now + (tonumber(Const.CORPSE_AUDIT_INTERVAL_MS) or 1000)
        Internal.auditCorpseBatch(reg)
    end
    Lifecycle.LastAudit = stats
    return stats
end
