-- Public Health schema repository. The record envelope coordinates timing only.
PNC = PNC or {}
PNC.Health = PNC.Health or {}
local Health = PNC.Health
local Const = PNC.Const
local Body = require "PNC/Core/Health/Repository/PNC_HealthBodyCodec"
local Compact = require "PNC/Core/Health/Repository/PNC_HealthCompactCodec"
local Codec = require "PNC/Core/Base/PNC_RecordCodec"
local Repository = Health.Repository or {}
Health.Repository = Repository
function Repository.Normalize(raw, fallbackMax)
    return Compact.sanitizeHealth(raw, fallbackMax)
end

function Repository.Serialize(raw, fallbackMax)
    return Compact.serializeHealth(raw, fallbackMax)
end

function Repository.NormalizeBody(raw)
    return Body.sanitizeHealthBody(raw)
end

function Repository.RestoreHealth(record, raw)
    record.health = Repository.Normalize(raw,
        record.health and record.health.max or Const.DEFAULT_HP_MAX)
    record.alive = tostring(record.health.state or "") ~= "dead"
        and tostring(record.health.state or "") ~= "corpse"
end

function Repository.RestoreStamina(rawStamina, record)
    local output
    if type(rawStamina) ~= "table" then
        return nil
    end
    output = {
        current = Codec.normalizeNumber(rawStamina.current, 0),
        max = rawStamina.max ~= nil
            and math.max(1, Codec.normalizeNumber(rawStamina.max, 1)) or nil,
    }
    if record then
        record.stamina = output
    end
    return output
end

function Repository.SerializeStamina(rawStamina)
    local current
    local maximum
    if type(rawStamina) ~= "table" then return nil end
    current = tonumber(rawStamina.current)
    maximum = tonumber(rawStamina.max)
    if current == nil then return nil end
    if maximum and math.abs(current - maximum) < 0.01 then return nil end
    return { current = current }
end

return Repository
