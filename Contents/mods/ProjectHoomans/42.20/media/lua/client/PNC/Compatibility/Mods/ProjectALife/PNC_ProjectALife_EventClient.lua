-- Route A-Life meta events and Hoomans server events through the adapter.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.ProjectALifeEvents =
    PNC.Compatibility.ProjectALifeEvents or {}

require "PNC/Compatibility/Mods/ProjectALife/PNC_ProjectALife_EventNormalizer"
require "PNC/Compatibility/Mods/ProjectALife/PNC_ProjectALife_EventPresenter"

local Client = PNC.Compatibility.ProjectALifeEvents.Client
local function emit(eventName, payload)
    local api = PNC.Compatibility and PNC.Compatibility.API
    if api and type(api.EmitEvent) == "function" then
        local ok, emitted = pcall(api.EmitEvent, eventName, payload)
        return ok and (tonumber(emitted) or 0) > 0
    end
    return false
end

local function installMetaClientHook()
    local meta = ProjectALife and ProjectALife.MetaClient
    if type(meta) ~= "table" or type(meta.onEvent) ~= "function" then
        return false
    end
    if Client.metaClient == meta and meta.onEvent == Client.metaWrapper then
        return true
    end

    local original = meta.onEvent
    local wrapper = function(payload)
        local result = original(payload)
        if type(payload) == "table" then
            pcall(emit, "projectalife_meta_event", payload)
        end
        return result
    end
    meta.onEvent = wrapper
    Client.metaClient = meta
    Client.metaOriginal = original
    Client.metaWrapper = wrapper
    return true
end

local function removeRetry()
    if Client.retry and Events and Events.OnTick
        and Events.OnTick.Remove
    then
        Events.OnTick.Remove(Client.retry)
    end
    Client.retry = nil
end

local function retryInstall()
    Client.installAttempts = Client.installAttempts + 1
    if installMetaClientHook() or Client.installAttempts >= 1200 then
        removeRetry()
    end
end

local internal = PNC.Client and PNC.Client.Internal
if internal and type(internal.RegisterServerCommand) == "function" then
    internal.RegisterServerCommand(Client.COMMAND, function(payload)
        return emit("projectalife_client_flavor", payload)
    end)
end

if Events and Events.OnTick and Events.OnTick.Add then
    Client.retry = retryInstall
    Events.OnTick.Add(retryInstall)
end
retryInstall()

return Client
