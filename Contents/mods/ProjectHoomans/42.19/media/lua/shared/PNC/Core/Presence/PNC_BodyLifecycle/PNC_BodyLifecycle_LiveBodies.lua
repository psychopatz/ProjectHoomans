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
    modData.PNC_NPC = true
    modData.PNC_UUID = tostring(record.id)
    modData.PNC_BodyKind = "live"
    modData.PNC_BodyLease = tostring(record.runtime.bodyLease)
    modData.PNC_CorpseToken = nil
    modData.PNC_TagVersion = Const.BODY_TAG_VERSION
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
    end
    return true
end

function Lifecycle.RemoveLiveBody(record, zombie, reason)
    if zombie then
        Internal.removeZombie(zombie)
    end
    return Internal.detachLiveBody(record, reason)
end
