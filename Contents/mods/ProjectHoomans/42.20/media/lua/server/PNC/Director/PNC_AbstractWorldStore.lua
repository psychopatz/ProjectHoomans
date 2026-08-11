-- Authority-owned persistence boundary and local event bus for abstract state.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.AbstractWorldStore = PNC.AbstractWorldStore or {}

local Store = PNC.AbstractWorldStore
local Types = PNC.AbstractWorldTypes
local Config = PNC.DirectorConfig
local Core = PNC.Core

Store.Registry = Store.Registry or Types.NewRegistry()
Store.Loaded = Store.Loaded or false
Store.Dirty = Store.Dirty or false
Store.Listeners = Store.Listeners or {}

local function authority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

local function assign(target, source)
    for key in pairs(target) do target[key] = nil end
    for key, value in pairs(source) do target[key] = value end
end

function Store.WorldAgeHours()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and math.max(0, tonumber(gameTime:getWorldAgeHours()) or 0) or 0
end

function Store.Load()
    if not authority() then return false, "not_authority" end
    local raw = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Config.MODDATA_KEY) or {}
    local needsMigration = tonumber(raw.schemaVersion) ~= Config.SCHEMA_VERSION
        or type(raw.groupsByID) ~= "table"
        or type(raw.locationsByID) ~= "table"
        or type(raw.encounters) ~= "table"
    for _, group in pairs(type(raw.groupsByID) == "table"
        and raw.groupsByID or {}) do
        if type(group) ~= "table"
            or tonumber(group.schemaVersion) ~= Config.SCHEMA_VERSION
            or type(group.simulation) ~= "table"
            or type(group.resources) ~= "table"
            or group.combatProfileDirty == nil
            or group.morale == nil
            or type(group.recentAvoidedLocations) ~= "table"
        then needsMigration = true break end
    end
    Store.Registry = Types.NormalizeRegistry(raw)
    Store.Loaded = true
    -- Older or malformed saves are rewritten through the normalizer.
    Store.Dirty = needsMigration
    return true, Store.Dirty
end

function Store.EnsureLoaded()
    if not Store.Loaded then return Store.Load() end
    return true
end

function Store.Touch(reason)
    Store.Registry.revision = (tonumber(Store.Registry.revision) or 0) + 1
    Store.Dirty = true
    Store.LastMutationReason = tostring(reason or "unspecified")
end

function Store.Save()
    Store.EnsureLoaded()
    if not Store.Dirty then return false, "not_dirty" end
    local target = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Config.MODDATA_KEY) or nil
    local normalized
    if not target then return false, "moddata_unavailable" end
    normalized = Types.NormalizeRegistry(Store.Registry)
    assign(target, Core.DeepCopy(normalized))
    Store.Registry = normalized
    Store.Dirty = false
    return true, "saved"
end

function Store.RegisterListener(eventName, callback)
    eventName = tostring(eventName or "")
    if eventName == "" or type(callback) ~= "function" then return false end
    Store.Listeners[eventName] = Store.Listeners[eventName] or {}
    Store.Listeners[eventName][#Store.Listeners[eventName] + 1] = callback
    return true
end

function Store.Emit(eventName, payload)
    for index, callback in ipairs(Store.Listeners[tostring(eventName or "")] or {}) do
        local ok, err = pcall(callback, payload)
        if not ok and Core and Core.LogWarn then
            Core.LogWarn("Abstract-world listener failed event="
                .. tostring(eventName) .. " index=" .. tostring(index)
                .. " error=" .. tostring(err))
        end
    end
end

local function onInitGlobalModData() Store.Load() end
if Events and Events.OnInitGlobalModData and not Store.LoadHookRegistered then
    Events.OnInitGlobalModData.Add(onInitGlobalModData)
    Store.LoadHookRegistered = true
end
return Store
