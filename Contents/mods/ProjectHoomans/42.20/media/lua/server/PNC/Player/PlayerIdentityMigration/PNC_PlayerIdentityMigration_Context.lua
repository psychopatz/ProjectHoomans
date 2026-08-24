-- Shared primitives for player identity migration providers.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerIdentityMigration = PNC.PlayerIdentityMigration or {}
PNC.PlayerIdentityMigration.Internal = PNC.PlayerIdentityMigration.Internal or {}

local Internal = PNC.PlayerIdentityMigration.Internal
local Core = PNC.Core
local EntityRef = PNC.EntityRef

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function call(value, method)
    local fn = value and value[method]
    if not fn then return nil end
    local ok, result = pcall(fn, value)
    return ok and result or nil
end

local function atNow(value)
    value = tonumber(value)
    if value then return math.max(0, value) end
    local gameTime = getGameTime and getGameTime()
    return gameTime and gameTime.getWorldAgeHours
        and math.max(0, tonumber(gameTime:getWorldAgeHours()) or 0) or 0
end

local function fingerprint(player)
    local descriptor = call(player, "getDescriptor")
    local first = descriptor and call(descriptor, "getForename") or nil
    local last = descriptor and call(descriptor, "getSurname") or nil
    if not first and not last then return nil end
    return string.lower(tostring(first or "")) .. "\31"
        .. string.lower(tostring(last or ""))
end

local function recordFingerprint(record)
    if not record or (not record.forename and not record.surname) then
        return nil
    end
    return string.lower(tostring(record.forename or "")) .. "\31"
        .. string.lower(tostring(record.surname or ""))
end

local function keyVariants(record)
    local result = {}
    local function add(identity)
        local key = identity and EntityRef.ForPlayerIdentity(identity, record.uuid)
        if key then result[key] = true end
    end
    add(record.accountKey)
    add(record.accountIdentity)
    for identity, enabled in pairs(record.legacyAccountIdentities or {}) do
        if enabled == true then add(identity) end
    end
    return result
end

local function mergeListByID(target, source)
    local byID = {}
    for _, item in ipairs(target or {}) do
        if item.id then byID[item.id] = item end
    end
    for _, item in ipairs(source or {}) do
        if item.id and (not byID[item.id]
            or (tonumber(item.lastUpdatedAt or item.editedAt or item.createdAt) or 0)
                > (tonumber(byID[item.id].lastUpdatedAt
                    or byID[item.id].editedAt or byID[item.id].createdAt) or 0))
        then
            byID[item.id] = copy(item)
        end
    end
    local result = {}
    for _, item in pairs(byID) do result[#result + 1] = item end
    table.sort(result, function(a, b)
        local aa = tonumber(a.createdAt) or 0
        local bb = tonumber(b.createdAt) or 0
        if aa ~= bb then return aa < bb end
        return tostring(a.id) < tostring(b.id)
    end)
    return result
end

local function replaceKey(value, oldKeys, canonicalKey)
    return type(value) == "string" and oldKeys[value] and canonicalKey or value
end

Internal.Copy = copy
Internal.Call = call
Internal.AtNow = atNow
Internal.Fingerprint = fingerprint
Internal.RecordFingerprint = recordFingerprint
Internal.KeyVariants = keyVariants
Internal.MergeListByID = mergeListByID
Internal.ReplaceKey = replaceKey

return Internal
