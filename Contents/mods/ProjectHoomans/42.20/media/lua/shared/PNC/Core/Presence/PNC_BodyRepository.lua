-- Durable corpse/carrier proof schema. Registry identity and M12 authority remain unchanged.
local Repository = {}
local Codec = require "PNC/Core/Base/PNC_RecordCodec"
local Const = PNC.Const

function Repository.NormalizeCorpse(rawCorpse, record)
    if type(rawCorpse) ~= "table" then
        return nil
    end
    return {
        token = Codec.normalizeString(rawCorpse.token),
        x = Codec.normalizeNumber(rawCorpse.x, record and record.x or 0),
        y = Codec.normalizeNumber(rawCorpse.y, record and record.y or 0),
        z = Codec.normalizeNumber(rawCorpse.z, record and record.z or 0),
        createdWorldHour = Codec.normalizeNumber(rawCorpse.createdWorldHour, 0),
    }
end

function Repository.RestoreCorpse(record, rawCorpse)
    record.corpse = Repository.NormalizeCorpse(rawCorpse, record)
    if record.alive == false and not record.corpse then
        record.corpse = {
            token = nil,
            x = record.x,
            y = record.y,
            z = record.z,
            createdWorldHour = 0,
        }
    end
end

function Repository.BuildHint(record)
    local runtime = record.runtime or {}
    local startupBodyHint = runtime.startupBodyHint
    local instanceID = record.liveBodyInstanceID
        or startupBodyHint and startupBodyHint.instanceID
        or runtime.lastLiveBodyInstanceID or nil
    local populationID = record.liveBodyPopulationID
        or startupBodyHint and startupBodyHint.populationId
        or runtime.lastLiveBodyPopulationID or nil
    local onlineID = record.liveBodyOnlineID
        or startupBodyHint and startupBodyHint.onlineID
        or runtime.lastLiveBodyOnlineID or nil
    local lease = runtime.bodyLease
        or startupBodyHint and startupBodyHint.lease
        or runtime.lastLiveBodyLease or nil
    local wasLive = record.presenceState == Const.PRESENCE_LIVE
        or runtime.startupRehydrateExpected == true
        or startupBodyHint and startupBodyHint.wasLive == true
    if instanceID == nil and populationID == nil
        and wasLive ~= true
    then
        return
    end
    return {
        instanceID = instanceID,
        wasLive = wasLive == true,
        onlineID = onlineID,
        lease = lease,
        populationId = populationID,
        x = Codec.normalizeNumber(
            startupBodyHint and startupBodyHint.x
                or runtime.lastLiveBodyX or record.x,
            0
        ),
        y = Codec.normalizeNumber(
            startupBodyHint and startupBodyHint.y
                or runtime.lastLiveBodyY or record.y,
            0
        ),
        z = Codec.normalizeNumber(
            startupBodyHint and startupBodyHint.z
                or runtime.lastLiveBodyZ or record.z,
            0
        ),
    }
end

function Repository.RestoreHint(record, raw)
    local bodyHint = type(raw.bodyHint) == "table"
        and raw.bodyHint or nil
    if bodyHint
        and (bodyHint.instanceID ~= nil
            or bodyHint.populationId ~= nil
            or bodyHint.wasLive == true)
    then
        local wasLive = bodyHint.wasLive == true
            or (bodyHint.wasLive == nil
                and Codec.normalizeString(bodyHint.lease) ~= nil)
        record.runtime.startupBodyHint = {
            instanceID = bodyHint.instanceID ~= nil
                and tostring(bodyHint.instanceID) or nil,
            onlineID = tonumber(bodyHint.onlineID),
            lease = Codec.normalizeString(bodyHint.lease),
            populationId = Codec.normalizeString(bodyHint.populationId),
            x = Codec.normalizeNumber(bodyHint.x, record.x),
            y = Codec.normalizeNumber(bodyHint.y, record.y),
            z = Codec.normalizeNumber(bodyHint.z, record.z),
            wasLive = wasLive == true,
        }
        -- Runtime presence is rebuilt as abstract until the engine body has
        -- been rediscovered. Preserve whether the save actually owned a live
        -- body so startup can adopt that body instead of treating it as an
        -- historical husk and spawning a replacement.
        record.runtime.startupRehydrateExpected = wasLive == true
        record.runtime.lastLiveBodyInstanceID =
            record.runtime.startupBodyHint.instanceID
        record.runtime.lastLiveBodyPopulationID =
            record.runtime.startupBodyHint.populationId
        record.runtime.lastLiveBodyOnlineID =
            record.runtime.startupBodyHint.onlineID
        record.runtime.lastLiveBodyLease =
            record.runtime.startupBodyHint.lease
        record.runtime.lastLiveBodyX = record.runtime.startupBodyHint.x
        record.runtime.lastLiveBodyY = record.runtime.startupBodyHint.y
        record.runtime.lastLiveBodyZ = record.runtime.startupBodyHint.z
    end
end

return Repository
