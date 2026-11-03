local T = require "tests/support/test"
T.addPackagePaths()

isClient = function() return false end
isServer = function() return false end

local roots = {}
ModData = {
    get = function(key) return roots[key] end,
    getOrCreate = function(key)
        roots[key] = roots[key] or {}
        return roots[key]
    end,
}
Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
}
getGameTime = function()
    return {
        getWorldAgeHours = function() return 25 end,
    }
end

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
    PlayerCharacters = {
        GetCharacterUUID = function()
            return "character:cutover"
        end,
    },
}
require "PNC/Core/Persistence/PNC_ModDataStore"
require "PNC/Core/Discovery/PNC_WorldDiscoveryTypes"

PNC.WorldDiscovery = {
    Internal = {},
    Registry = {
        schemaVersion =
            PNC.WorldDiscoveryTypes.SCHEMA_VERSION,
        revision = 0,
        players = {},
    },
    Loaded = false,
    Dirty = false,
}
require "PNC/WorldDiscovery/PNC_WorldDiscovery_Storage"

local Types = PNC.WorldDiscoveryTypes
roots[Types.MODDATA_KEY] = {
    schemaVersion = Types.SCHEMA_VERSION,
    revision = 4,
    players = {
        ["character:cutover"] = {
            revision = 3,
            lastRadioScanAt = 20,
            radioScanCount = 2,
            entities = {
                settlement = {
                    community_cutover = {
                        entityID = "community_cutover",
                        kind = "settlement",
                        phase = Types.PHASE_LOCATED,
                        source = "legacy",
                        discoveredAt = 10,
                        updatedAt = 15,
                        x = 100, y = 200, z = 0,
                        arrivalState = Types.ARRIVAL_SEARCHED,
                        searchedAt = 15,
                        presenceStatus = Types.PRESENCE_ABSENT,
                        factionKnown = true,
                        factionID = "faction_cutover",
                        factionName = "Cutover Faction",
                    },
                },
                mobile_group = {
                    group_cutover = {
                        entityID = "group_cutover",
                        kind = "mobile_group",
                        phase = Types.PHASE_RUMORED,
                        source = "radio",
                        discoveredAt = 12,
                        updatedAt = 12,
                        x = 300, y = 400, z = 0,
                        arrivalState = Types.ARRIVAL_UNCHECKED,
                        presenceStatus = Types.PRESENCE_UNKNOWN,
                    },
                },
            },
        },
    },
}

assert(PNC.WorldDiscovery.Load())
assert(PNC.WorldDiscovery.Registry.players
    ["character:cutover"].entities.settlement
    .community_cutover, "legacy source did not load")

local World = require
    "PsychopatzCore/SurvivorWorld/PsychopatzSurvivorWorld"
World.RuntimeStore.ResetForTests()
local core = assert(World.NewRegistry({
    worldSeed = 9191,
}))
assert(World.RuntimeStore.Replace(
    core:Snapshot(),
    "cutover_fixture"
))
PNC.CoreSurvivorWorldAuthority = {
    Registry = World.GetRuntimeRegistry(),
    World = World,
}

local Adapter = require
    "PNC/WorldDiscovery/PNC_CoreWorldDiscoveryAdapter"
local active, reason = Adapter.ActivateCutover()
T.truthy(active, reason)
T.truthy(Adapter.Active, "cutover active")

local canonical =
    World.GetRuntimeRegistry():GetDiscovery()
local player = canonical.players["character:cutover"]
T.truthy(player, "legacy player discovery not imported")
T.truthy(player.entities.community.community_cutover,
    "legacy settlement did not map to Core community")
T.truthy(player.entities.group.group_cutover,
    "legacy mobile group did not map to Core group")
T.equal(
    player.entities.community.community_cutover.phase,
    Types.PHASE_LOCATED,
    "community phase changed during migration"
)
T.equal(
    player.entities.community.community_cutover.searchedAt,
    15,
    "arrival timestamp changed during migration"
)
T.equal(
    next(roots[Types.MODDATA_KEY]),
    nil,
    "legacy PNC discovery root was not retired"
)
T.truthy(
    roots["PsychopatzCore.SurvivorWorld"]
        and roots["PsychopatzCore.SurvivorWorld"].registry,
    "Core SurvivorWorld was not persisted"
)

local alias = PNC.WorldDiscovery.Registry.players
    ["character:cutover"]
T.truthy(alias.entities.settlement.community_cutover,
    "PNC compatibility settlement view missing")
T.truthy(alias.entities.mobile_group.group_cutover,
    "PNC compatibility group view missing")

-- Core supports discovery kinds the legacy PNC view does not. Compatibility
-- saves must preserve them rather than treating the PNC view as total truth.
assert(World.Discovery.RegisterEntityProvider(
    "cutover_signal_fixture",
    {
        list = function()
            return {
                {
                    entityID = "signal:cutover",
                    kind = "signal",
                    name = "Cutover Signal",
                    position = { x = 450, y = 550, z = 0 },
                },
            }
        end,
    }
))
assert(World.Discovery.SetPhase(
    World.GetRuntimeRegistry(),
    "character:cutover",
    "signal",
    "signal:cutover",
    World.Discovery.PHASE_LOCATED,
    "fixture",
    25
))

alias.entities.mobile_group.group_cutover.phase =
    Types.PHASE_CONTACTED
alias.entities.mobile_group.group_cutover.contactedAt = 26
PNC.WorldDiscovery.Dirty = true
local saved, saveReason = PNC.WorldDiscovery.Save()
T.truthy(saved, saveReason)
T.equal(
    World.GetRuntimeRegistry():GetDiscovery()
        .players["character:cutover"]
        .entities.group.group_cutover.phase,
    Types.PHASE_CONTACTED,
    "compatibility mutation did not update Core discovery"
)
T.equal(
    next(roots[Types.MODDATA_KEY]),
    nil,
    "compatibility save resurrected legacy discovery root"
)
T.truthy(
    World.GetRuntimeRegistry():GetDiscovery()
        .players["character:cutover"]
        .entities.signal["signal:cutover"],
    "PNC compatibility save erased Core-only signal discovery"
)

PNC.WorldDiscovery.Registry = {
    schemaVersion = Types.SCHEMA_VERSION,
    revision = 0,
    players = {},
}
PNC.WorldDiscovery.Loaded = false
assert(PNC.WorldDiscovery.Load())
T.equal(
    PNC.WorldDiscovery.Registry.players
        ["character:cutover"]
        .entities.mobile_group.group_cutover.phase,
    Types.PHASE_CONTACTED,
    "reload did not rebuild PNC view from Core"
)

T.finish("pnc_core_world_discovery_cutover_smoke")
