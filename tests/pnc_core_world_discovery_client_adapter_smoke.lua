local T = require "tests/support/test"
T.addPackagePaths()

local coreCalls = {}
local currentCoreSnapshot = {
    state = "known",
    playerKey = "character:client-adapter",
    revision = 4,
    lastRadioScanAt = 12,
    radioScanCount = 2,
    serverWorldHour = 30,
    entities = {
        {
            entityID = "community:one",
            kind = "community",
            phase = 2,
            phaseName = "LOCATED",
            x = 100,
            y = 200,
            z = 0,
        },
        {
            entityID = "group:one",
            kind = "group",
            phase = 3,
            phaseName = "CONTACTED",
            x = 300,
            y = 400,
            z = 0,
        },
        {
            entityID = "signal:one",
            kind = "signal",
            phase = 1,
            phaseName = "RUMORED",
            x = 500,
            y = 600,
            z = 0,
        },
    },
}
local CoreClient = {
    COMMAND_DISCOVERY_SNAPSHOT =
        "SurvivorWorldDiscoverySnapshot",
    GetDiscoverySnapshot = function()
        return currentCoreSnapshot
    end,
    RequestDiscovery = function()
        coreCalls[#coreCalls + 1] = { action = "snapshot" }
        return true
    end,
    RequestDiscoveryIfDue = function(interval, force)
        coreCalls[#coreCalls + 1] = {
            action = "snapshot_due",
            interval = interval,
            force = force,
        }
        return true
    end,
    DiscoveryAction = function(action, args)
        coreCalls[#coreCalls + 1] = {
            action = action,
            args = args,
        }
        return true
    end,
}
package.preload[
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
] = function()
    return CoreClient
end

local hooks = {}
Events = {
    OnServerCommand = {
        Add = function(fn)
            hooks[#hooks + 1] = fn
        end,
    },
}
PsychopatzCore = {
    COMMAND_MODULE = "PsychopatzCore",
}

local applied
local legacyCalls = {}
PNC = {
    Core = {
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, child in pairs(value) do
                output[key] = PNC.Core.DeepCopy(child)
            end
            return output
        end,
    },
    Network = {
        ClientState = {},
    },
    Client = {
        Internal = {
            ApplyWorldDiscoverySnapshot = function(payload)
                applied = payload
                PNC.Network.ClientState.worldDiscovery = payload
                return true
            end,
        },
        RequestWorldDiscovery = function(action, options)
            legacyCalls[#legacyCalls + 1] = {
                action = action,
                options = options,
            }
            return true, "legacy"
        end,
    },
}

local Adapter = T.load(
    "ProjectHoomans",
    "client",
    "PNC/WorldDiscovery/PNC_CoreWorldDiscoveryClientAdapter.lua"
)
T.truthy(Adapter.Installed, "client discovery bridge not installed")
T.truthy(applied, "initial Core snapshot not projected to PNC")
T.equal(applied.characterUUID, "character:client-adapter",
    "Core player key did not map to PNC character UUID")
local byID = {}
for _, entity in ipairs(applied.entities) do
    byID[entity.entityID] = entity
end
T.equal(byID["community:one"].kind, "settlement",
    "Core community did not map to PNC settlement")
T.equal(byID["group:one"].kind, "mobile_group",
    "Core group did not map to PNC mobile group")
T.equal(byID["signal:one"].kind, "signal",
    "Core signal was lost from compatibility snapshot")

local ok, reason = PNC.Client.RequestWorldDiscovery(
    "snapshot",
    { intervalMs = 4321 }
)
T.truthy(ok, reason)
T.equal(coreCalls[#coreCalls].action, "snapshot_due",
    "generic snapshot did not use Core transport")
T.equal(coreCalls[#coreCalls].interval, 4321,
    "generic snapshot refresh interval changed")
T.equal(#legacyCalls, 0,
    "generic snapshot unexpectedly used PNC legacy transport")

ok, reason = PNC.Client.RequestWorldDiscovery(
    "debug_discover_all",
    { scope = "groups" }
)
T.truthy(ok, reason)
T.equal(coreCalls[#coreCalls].action, "debug_discover_all",
    "generic debug action did not use Core transport")
T.equal(coreCalls[#coreCalls].args.scope, "groups",
    "generic debug action payload changed")

ok, reason = PNC.Client.RequestWorldDiscovery(
    "radio_scan",
    { range = 50 }
)
T.truthy(ok, reason)
T.equal(#legacyCalls, 1,
    "Hoomans radio policy did not remain on adopter transport")
T.equal(legacyCalls[1].action, "radio_scan",
    "Hoomans action changed during fallback")

currentCoreSnapshot = {
    state = "known",
    playerKey = "character:client-adapter",
    revision = 5,
    entities = {
        {
            entityID = "community:two",
            kind = "community",
            phase = 3,
            phaseName = "CONTACTED",
            x = 700,
            y = 800,
            z = 0,
        },
    },
}
T.equal(#hooks, 1, "Core discovery server hook not registered")
hooks[1](
    "PsychopatzCore",
    "SurvivorWorldDiscoverySnapshot",
    currentCoreSnapshot
)
T.equal(
    PNC.Network.ClientState.worldDiscovery.revision,
    5,
    "Core server snapshot did not refresh PNC compatibility state"
)
T.equal(
    PNC.Network.ClientState.worldDiscovery.entities[1].entityID,
    "community:two",
    "Core server snapshot content not applied"
)

T.finish("pnc_core_world_discovery_client_adapter_smoke")
