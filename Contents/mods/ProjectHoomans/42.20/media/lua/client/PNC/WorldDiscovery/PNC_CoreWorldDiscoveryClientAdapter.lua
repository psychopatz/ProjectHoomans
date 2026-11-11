-- Client bridge from the canonical Core SurvivorWorld discovery transport to
-- the Hoomans discovery presentation and policy surface. Generic
-- snapshot/debug actions use Core; Hoomans-only radio/contact actions remain
-- on the adopter-owned command surface.

PNC = PNC or {}
PNC.CoreWorldDiscoveryClientAdapter =
    PNC.CoreWorldDiscoveryClientAdapter or {}

local Adapter = PNC.CoreWorldDiscoveryClientAdapter
local CoreClient = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
local ClientState = PNC.Network and PNC.Network.ClientState or nil

local function pncKind(kind)
    kind = tostring(kind or "")
    if kind == "community" then return "settlement" end
    if kind == "group" then return "mobile_group" end
    return kind
end

local function copy(value)
    if PNC.Core and PNC.Core.DeepCopy then
        return PNC.Core.DeepCopy(value)
    end
    if type(value) ~= "table" then return value end
    local output = {}
    for key, child in pairs(value) do
        output[copy(key)] = copy(child)
    end
    return output
end

function Adapter.ToPNC(payload)
    payload = type(payload) == "table" and payload or {}
    local output = {
        state = tostring(payload.state or "unknown"),
        reason = payload.reason,
        characterUUID = payload.playerKey,
        playerKey = payload.playerKey,
        revision = math.max(
            0,
            math.floor(tonumber(payload.revision) or 0)
        ),
        entities = {},
        lastRadioScanAt = math.max(
            0,
            tonumber(payload.lastRadioScanAt) or 0
        ),
        radioScanCount = math.max(
            0,
            math.floor(tonumber(payload.radioScanCount) or 0)
        ),
        serverWorldHour = math.max(
            0,
            tonumber(payload.serverWorldHour) or 0
        ),
    }
    for _, raw in ipairs(payload.entities or {}) do
        local entity = copy(raw)
        entity.kind = pncKind(raw.kind)
        output.entities[#output.entities + 1] = entity
    end
    table.sort(output.entities, function(left, right)
        if tostring(left.kind) ~= tostring(right.kind) then
            return tostring(left.kind) < tostring(right.kind)
        end
        return tostring(left.entityID) < tostring(right.entityID)
    end)
    return output
end

function Adapter.SyncSnapshot(payload)
    payload = payload or CoreClient.GetDiscoverySnapshot()
    local translated = Adapter.ToPNC(payload)
    local internal = PNC.Client and PNC.Client.Internal or nil
    if internal
        and type(internal.ApplyWorldDiscoverySnapshot) == "function"
    then
        return internal.ApplyWorldDiscoverySnapshot(translated)
    end
    if ClientState then
        ClientState.worldDiscovery = translated
        return true
    end
    return false
end

local function canUseCoreTransport()
    return CoreClient
        and type(CoreClient.RequestDiscovery) == "function"
        and type(CoreClient.DiscoveryAction) == "function"
end

local function genericAction(action)
    action = tostring(action or "snapshot")
    return action == "snapshot"
        or action == "debug_discover_all"
        or action == "debug_reset"
        or action == "debug_reset_entity"
        or action == "set_phase"
        or action == "mark_contacted"
        or action == "mark_arrived"
end

function Adapter.Request(action, options)
    action = tostring(action or "snapshot")
    options = type(options) == "table"
        and copy(options) or {}

    if canUseCoreTransport() and genericAction(action) then
        local accepted, reason
        if action == "snapshot" then
            accepted, reason =
                CoreClient.RequestDiscoveryIfDue
                    and CoreClient.RequestDiscoveryIfDue(
                        options.intervalMs or 10000,
                        options.force == true
                    )
                    or CoreClient.RequestDiscovery()
            if accepted == true then
                return true, "core_sent"
            end
            if reason == "not_due" then
                Adapter.SyncSnapshot()
                return true, "core_current"
            end
        else
            accepted, reason =
                CoreClient.DiscoveryAction(action, options)
            if accepted == true then
                return true, "core_sent"
            end
        end
        Adapter.LastCoreFailure = reason
    end

    local fallback = Adapter.AdopterRequest
    if type(fallback) ~= "function" then
        return false, "discovery_transport_unavailable"
    end
    return fallback(action, options)
end

function Adapter.Install()
    if Adapter.Installed == true then return true end
    if not PNC.Client
        or type(PNC.Client.RequestWorldDiscovery) ~= "function"
    then
        return false, "pnc_discovery_client_unavailable"
    end
    Adapter.AdopterRequest = PNC.Client.RequestWorldDiscovery
    PNC.Client.RequestWorldDiscovery = Adapter.Request
    Adapter.Installed = true
    Adapter.SyncSnapshot()
    return true
end

local function commandModule()
    return PsychopatzCore and PsychopatzCore.COMMAND_MODULE
        or "PsychopatzCore"
end

local function onServerCommand(module, command, args)
    if module ~= commandModule()
        or not CoreClient
        or command ~= CoreClient.COMMAND_DISCOVERY_SNAPSHOT
    then
        return
    end
    Adapter.SyncSnapshot(args)
end

if Events and Events.OnServerCommand
    and type(Events.OnServerCommand.Add) == "function"
    and not Adapter.ServerHookRegistered
then
    Adapter.ServerHookRegistered = true
    Events.OnServerCommand.Add(onServerCommand)
end

Adapter.Install()

return Adapter
