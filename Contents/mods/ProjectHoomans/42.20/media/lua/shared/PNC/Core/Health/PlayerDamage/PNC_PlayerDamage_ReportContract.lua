-- Compact, versioned player-hit payload shared by client and server adapters.

PNC = PNC or {}
PNC.PlayerDamage = PNC.PlayerDamage or {}

local Report = PNC.PlayerDamage.Report or {}
PNC.PlayerDamage.Report = Report

local MAX_ID_LENGTH = 128

local function finiteNumber(value)
    local number = tonumber(value)
    if number == nil or number ~= number
        or number == math.huge or number == -math.huge
    then
        return nil
    end
    return number
end

local function boundedString(value, allowEmpty)
    local valueType = type(value)
    local text
    if valueType ~= "string" and valueType ~= "number" then
        return nil
    end
    if valueType == "number" and finiteNumber(value) == nil then
        return nil
    end
    text = tostring(value)
    if #text > MAX_ID_LENGTH or (not allowEmpty and text == "") then
        return nil
    end
    return text
end

local function optionalNumber(value)
    if value == nil then
        return nil, true
    end
    local number = finiteNumber(value)
    if number == nil then
        return nil, false
    end
    return number, true
end

local function optionalString(value)
    if value == nil then
        return nil, true
    end
    local text = boundedString(value, true)
    return text, text ~= nil
end

function Report.Normalize(input)
    local version
    local id
    local attackerOnlineID
    local bodyOnlineID
    local bodyInstanceID
    local bodyLease
    local weaponFullType
    local damage
    local valid
    if type(input) ~= "table" or input.id == nil then
        return nil, "invalid_report"
    end
    if input.schemaVersion ~= nil then
        version = finiteNumber(input.schemaVersion)
        if version ~= 1 then
            return nil, "unsupported_report_version"
        end
    end
    id = boundedString(input.id, false)
    if not id then
        return nil, "invalid_report"
    end
    attackerOnlineID, valid = optionalNumber(input.attackerOnlineID)
    if not valid then return nil, "invalid_report" end
    bodyOnlineID, valid = optionalNumber(input.bodyOnlineID)
    if not valid then return nil, "invalid_report" end
    bodyInstanceID, valid = optionalString(input.bodyInstanceID)
    if not valid then return nil, "invalid_report" end
    bodyLease, valid = optionalString(input.bodyLease)
    if not valid then return nil, "invalid_report" end
    weaponFullType, valid = optionalString(input.weaponFullType or "")
    if not valid then return nil, "invalid_report" end
    damage = finiteNumber(input.damage) or 0
    return {
        schemaVersion = 1,
        id = id,
        attackerOnlineID = attackerOnlineID,
        bodyOnlineID = bodyOnlineID,
        bodyInstanceID = bodyInstanceID,
        bodyLease = bodyLease,
        weaponFullType = weaponFullType,
        damage = damage,
    }
end

function Report.Create(fields)
    if type(fields) ~= "table" then
        return nil, "invalid_report"
    end
    return Report.Normalize({
        schemaVersion = 1,
        id = fields.id,
        attackerOnlineID = fields.attackerOnlineID,
        bodyOnlineID = fields.bodyOnlineID,
        bodyInstanceID = fields.bodyInstanceID,
        bodyLease = fields.bodyLease,
        weaponFullType = fields.weaponFullType,
        damage = fields.damage,
    })
end
