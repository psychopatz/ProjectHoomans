-- Opt-in, read-only diagnostics for player identity and combat callbacks.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then
    return
end

PNC = PNC or {}
PNC.PlayerCharacterDebug = PNC.PlayerCharacterDebug or {}

local Debug = PNC.PlayerCharacterDebug
local Core = PNC.Core

local function configFlag(name)
    return PNC.Config
        and PNC.Config.Relationships
        and PNC.Config.Relationships[name] == true
end

local function emit(prefix, fields)
    local keys = {
        "callback",
        "accountIdentity",
        "accountKey",
        "characterUUID",
        "status",
        "worldAgeHours",
        "onlineID",
        "result",
        "reason",
        "event",
        "encounterID",
        "threatID",
    }
    local parts = { prefix }
    local index
    local key
    local value
    for index = 1, #keys do
        key = keys[index]
        value = fields and fields[key] or nil
        if value ~= nil then
            parts[#parts + 1] = key .. "=" .. tostring(value)
        end
    end
    if Core and Core.LogDebug then
        Core.LogDebug(table.concat(parts, " "))
    elseif print then
        print(table.concat(parts, " "))
    end
end

function Debug.LogIdentity(fields)
    if configFlag("DebugPlayerIdentity") then
        emit("[PNC PlayerIdentity]", fields)
    end
end

function Debug.LogCombat(fields)
    if configFlag("DebugCombatCallbacks") then
        emit("[PNC CombatCallback]", fields)
    end
end

function Debug.FormatRecord(characterUUID)
    local service = PNC.PlayerCharacters
    local record = service
        and service.GetRegistryRecord
        and service.GetRegistryRecord(characterUUID) or nil
    if not record then
        return "Player Character Identity\nUUID: "
            .. tostring(characterUUID) .. "\nStatus: not found"
    end
    local snapshot = service.GetRegistrySnapshot
        and service.GetRegistrySnapshot() or {}
    local aliases = 0
    for _, canonicalUUID in pairs(snapshot.uuidAliases or {}) do
        if canonicalUUID == record.uuid then aliases = aliases + 1 end
    end
    return table.concat({
        "Player Character Identity",
        "UUID: " .. tostring(record.uuid),
        "Account: " .. tostring(record.accountIdentity),
        "Account key: " .. tostring(record.accountKey),
        "Superseded by: " .. tostring(record.supersededBy),
        "Aliases: " .. tostring(aliases),
        "Migration: " .. tostring(snapshot.migration
            and snapshot.migration.status),
        "Status: " .. tostring(record.status),
        "Created: " .. tostring(record.createdAt),
        "First seen: " .. tostring(record.firstSeenAt),
        "Last seen: " .. tostring(record.lastSeenAt),
        "Died: " .. tostring(record.diedAt),
        "Revision: " .. tostring(record.revision),
    }, "\n")
end

return Debug
