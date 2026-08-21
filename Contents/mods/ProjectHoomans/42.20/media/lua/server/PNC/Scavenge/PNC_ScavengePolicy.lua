if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ScavengePolicy = PNC.ScavengePolicy or {}

local Policy = PNC.ScavengePolicy
local MODDATA_KEY = "PNC_ScavengePolicy"
local SCHEMA_VERSION = 1
local MAX_AUTO_TYPES = 512

Policy.Data = Policy.Data or { schemaVersion = SCHEMA_VERSION, owners = {} }
Policy.Loaded = Policy.Loaded or false
Policy.Dirty = Policy.Dirty or false

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function normalizePreferences(value)
    value = type(value) == "table" and value or {}
    return {
        containers = value.containers ~= false,
        floorItems = value.floorItems ~= false,
        corpses = value.corpses ~= false,
    }
end

local function normalizeAutoGrab(value)
    local output = {}
    local count = 0
    for fullType, enabled in pairs(type(value) == "table" and value or {}) do
        fullType = tostring(fullType or "")
        if enabled == true and fullType ~= "" and count < MAX_AUTO_TYPES then
            output[fullType] = true
            count = count + 1
        end
    end
    return output
end

local function normalizeData(value)
    local output = { schemaVersion = SCHEMA_VERSION, owners = {} }
    for ownerKey, entry in pairs(type(value) == "table"
        and type(value.owners) == "table" and value.owners or {})
    do
        ownerKey = tostring(ownerKey or "")
        if ownerKey ~= "" then
            output.owners[ownerKey] = {
                preferences = normalizePreferences(entry and entry.preferences),
                autoGrab = normalizeAutoGrab(entry and entry.autoGrab),
            }
        end
    end
    return output
end

function Policy.Load()
    local raw = ModData and ModData.getOrCreate
        and ModData.getOrCreate(MODDATA_KEY) or {}
    Policy.Data = normalizeData(raw)
    Policy.Loaded = true
    return true
end

function Policy.EnsureLoaded()
    if not Policy.Loaded then return Policy.Load() end
    return true
end

function Policy.Save(flushGlobal)
    Policy.EnsureLoaded()
    if not Policy.Dirty then return false, "not_dirty" end
    local target = ModData and ModData.getOrCreate
        and ModData.getOrCreate(MODDATA_KEY) or nil
    if not target then return false, "moddata_unavailable" end
    for key, _ in pairs(target) do target[key] = nil end
    local normalized = normalizeData(Policy.Data)
    for key, value in pairs(normalized) do target[key] = copy(value) end
    Policy.Data = normalized
    Policy.Dirty = false
    if flushGlobal ~= false and GlobalModData and GlobalModData.save then
        GlobalModData.save()
    end
    return true
end

function Policy.OwnerKey(player)
    local key = PNC.PlayerCharacters and PNC.PlayerCharacters.GetEntityKey
        and PNC.PlayerCharacters.GetEntityKey(player) or nil
    if key and tostring(key) ~= "" then return tostring(key) end
    local username = player and player.getUsername
        and tostring(player:getUsername() or "") or ""
    return username ~= "" and "account:" .. username or nil
end

local function ownerEntry(player, create)
    Policy.EnsureLoaded()
    local ownerKey = Policy.OwnerKey(player)
    if not ownerKey then return nil, "owner_identity_unavailable" end
    local entry = Policy.Data.owners[ownerKey]
    if not entry and create then
        entry = { preferences = normalizePreferences(), autoGrab = {} }
        Policy.Data.owners[ownerKey] = entry
        Policy.Dirty = true
    end
    return entry or {
        preferences = normalizePreferences(), autoGrab = {},
    }, nil, ownerKey
end

function Policy.GetPreferences(player)
    local entry, reason = ownerEntry(player, false)
    return entry and copy(entry.preferences) or nil, reason
end

function Policy.SetPreferences(player, preferences)
    local entry, reason = ownerEntry(player, true)
    if not entry then return false, reason end
    entry.preferences = normalizePreferences(preferences)
    Policy.Dirty = true
    return true, copy(entry.preferences)
end

function Policy.GetAutoGrab(player)
    local entry, reason = ownerEntry(player, false)
    return entry and copy(entry.autoGrab) or nil, reason
end

function Policy.SetAutoGrab(player, fullType, enabled)
    fullType = tostring(fullType or "")
    if fullType == "" then return false, "full_type_required" end
    local entry, reason = ownerEntry(player, true)
    if not entry then return false, reason end
    if enabled == true then
        local count = 0
        for _, _ in pairs(entry.autoGrab) do count = count + 1 end
        if not entry.autoGrab[fullType] and count >= MAX_AUTO_TYPES then
            return false, "auto_grab_limit"
        end
        entry.autoGrab[fullType] = true
    else
        entry.autoGrab[fullType] = nil
    end
    Policy.Dirty = true
    return true, copy(entry.autoGrab)
end

function Policy.Matches(player, fullType)
    local values = Policy.GetAutoGrab(player)
    return values and values[tostring(fullType or "")] == true or false
end

function Policy.Snapshot(player)
    return {
        preferences = Policy.GetPreferences(player),
        autoGrab = Policy.GetAutoGrab(player),
    }
end

if Events and Events.OnInitGlobalModData and not Policy.LoadHookRegistered then
    Events.OnInitGlobalModData.Add(Policy.Load)
    Policy.LoadHookRegistered = true
end

return Policy
