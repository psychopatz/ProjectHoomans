-- Hoomans runtime view over Core SurvivorWorld plus Hoomans-only extension state.
-- It is not a persistence authority; pre-SurvivorWorld data is read only for cutover.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.HoomansWorldView = PNC.HoomansWorldView or {}

local Store = PNC.HoomansWorldView
local Types = PNC.AbstractWorldTypes
local Config = PNC.DirectorConfig
local Core = PNC.Core
local Reset = PNC.ModDataStore
    or require "PNC/Core/Persistence/PNC_ModDataStore"
local ImportSource = PNC.SurvivorWorldImportSource
    or require "PNC/Director/PNC_SurvivorWorldImportSource"

Store.Registry = Store.Registry or Types.NewRegistry()
Store.Loaded = Store.Loaded or false
Store.Dirty = Store.Dirty or false
Store.Listeners = Store.Listeners or {}

local function authority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

function Store.WorldAgeHours()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and math.max(0, tonumber(gameTime:getWorldAgeHours()) or 0) or 0
end

function Store.Load()
    if not authority() then return false, "not_authority" end

    local extensions = PNC.SurvivorWorldExtensions
    local coreAuthority = PNC.CoreSurvivorWorldAuthority
    local coreRegistry = coreAuthority and coreAuthority.Registry
    if extensions and extensions.Active == true
        and type(extensions.RebuildAll) == "function"
        and coreRegistry
        and type(coreRegistry.Snapshot) == "function"
    then
        local rebuilt, reason =
            extensions.RebuildAll(coreRegistry:Snapshot())
        if not rebuilt then return false, reason end
        return true, false
    end

    -- Before cutover, this view may be populated from the frozen old root so
    -- the one-way importer can capture Hoomans-only extension fields. After
    -- cutover the branch above is the only supported reload path.
    local raw, reason, sourceRaw =
        ImportSource.Read("abstractWorld")
    Store.Registry = Types.NormalizeRegistry(raw)
    Store.Loaded = true
    Store.Dirty = reason ~= nil and reason ~= "empty_state"
    if Store.Dirty then
        Reset.Mark(
            Store,
            sourceRaw,
            Config.SCHEMA_VERSION,
            reason,
            "hoomans_world_view_import"
        )
    end
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
            Core.LogWarn("Hoomans world-view listener failed event="
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
