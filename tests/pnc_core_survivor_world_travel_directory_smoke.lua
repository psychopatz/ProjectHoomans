local T = require "tests/support/test"
T.addPackagePaths()

local requests = 0
local coreEntries = {
    {
        actorID = "actor:core:map",
        label = "Core Map Actor",
        provider = "DTHoomans",
        providerState = "materialized",
        position = { x = 120, y = 240, z = 0 },
        canonicalPosition = { x = 117, y = 240, z = 0 },
        overlapIndex = 2,
        overlapCount = 3,
        groupID = "group:core:map",
        communityID = "community:core:map",
        factionID = "faction:core:map",
        role = "leader",
        portrait = {
            actorID = "actor:core:map",
            identitySeed = 42,
        },
        journey = {
            journeyID = "journey:core:map",
            state = "en_route",
            progress = 0.25,
            distanceTotal = 400,
            distanceTravelled = 100,
            eta = 12,
            ownerMod = "ProjectHoomans",
            ownerRef = "group:core:map",
            route = {
                points = {
                    { x = 100, y = 200, z = 0 },
                    { x = 200, y = 300, z = 0 },
                },
            },
        },
        positionSource = "ProjectHoomans.LiveBody",
    },
}
local CoreClient = {
    RequestActorsIfDue = function(interval)
        requests = requests + 1
        T.equal(interval, 500, "map refresh interval changed")
        return true
    end,
    ListActors = function(raw)
        T.equal(raw, false,
            "Hoomans map requested unspread Core actor entries")
        return coreEntries
    end,
    GetPortraitSpec = function(entry)
        return {
            actorID = entry.actorID,
            identitySeed = entry.actorID,
            isFemale = false,
            appearance = { hairModel = "Short" },
            equipment = {
                worn = {
                    Torso_Upper = "Base.Tshirt",
                },
            },
        }
    end,
}
package.preload[
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
] = function()
    return CoreClient
end

getGameTime = function()
    return {
        getWorldAgeHours = function() return 10 end,
    }
end
getSpecificPlayer = function()
    return {
        getUsername = function() return "MapUser" end,
    }
end

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_CORPSE = "corpse",
    },
    Core = {
        IsClientOnly = function() return true end,
    },
    Network = {
        ClientState = {
            snapshots = {
                ["actor:core:map"] = {
                    id = "actor:core:map",
                    name = "Hoomans Detail Name",
                    tacticalClass = "neutral",
                    presenceState = "live",
                    alive = true,
                    x = 999,
                    y = 999,
                    z = 0,
                    affiliation = {
                        groupID = "group:core:map",
                        communityID = "community:core:map",
                        factionID = "faction:core:map",
                        role = "leader",
                    },
                },
            },
            debugRoster = {},
        },
    },
    NPCIdentityPresentation = {
        GetName = function(snapshot)
            return snapshot and snapshot.name or "Unknown"
        end,
    },
}
package.preload[
    "PNC/Knowledge/PNC_NPCIdentityPresentation"
] = function()
    return PNC.NPCIdentityPresentation
end

local Directory = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Travel/PNC_TravelDirectory.lua"
)

local entries = Directory.ListProjected(10)
T.equal(requests, 1,
    "Core actor refresh was not demand-driven by map directory")
T.equal(#entries, 1,
    "canonical Core actor duplicated legacy PNC snapshot")
local entry = entries[1]
T.equal(entry.id, "actor:core:map",
    "canonical actor identity changed")
T.equal(entry.name, "Hoomans Detail Name",
    "Hoomans presentation metadata was not retained")
T.equal(entry.x, 120,
    "legacy PNC position overrode Core canonical projection")
T.equal(entry.y, 240,
    "legacy PNC position overrode Core canonical projection")
T.equal(entry.groupID, "group:core:map",
    "canonical group identity missing")
T.equal(entry.communityID, "community:core:map",
    "canonical community identity missing")
T.equal(entry.factionID, "faction:core:map",
    "canonical faction identity missing")
T.equal(entry.journeyId, "journey:core:map",
    "canonical group journey identity missing")
T.equal(entry.route.points[2].x, 200,
    "canonical route points missing")
T.equal(entry.percent, 0.25,
    "canonical route progress missing")
T.equal(entry.remainingWorldHours, 2,
    "canonical ETA projection changed")
T.truthy(entry.portrait
    and entry.portrait.actorID == "actor:core:map",
    "Core portrait contract missing")
T.equal(entry.overlapCount, 3,
    "Core overlap metadata missing")
T.equal(entry.coreActorProjection, true,
    "entry did not mark Core map authority")
T.equal(entry.positionSource, "ProjectHoomans.LiveBody",
    "live-body provider source missing")
T.falsy(entry.abstractOnly,
    "materialized Hoomans Core actor was incorrectly made abstract")
T.equal(entry.record.presenceState, "live",
    "materialized Hoomans Core actor lost live presence")

local abstract = Directory.ProjectCoreActor({
    actorID = "actor:core:abstract-trader",
    label = "Abstract Trader",
    provider = "DTAbstract",
    providerState = "abstract",
    position = { x = 500, y = 600, z = 0 },
    groupID = "group:abstract:trader",
    communityID = "community:abstract:trader",
    factionID = "faction:abstract:trader",
    role = "trader",
})
T.truthy(abstract,
    "abstract Core trader did not project through Hoomans directory")
T.truthy(abstract.abstractOnly,
    "DTAbstract Core actor was not marked permanently abstract")
T.equal(abstract.presenceState, "abstract",
    "DTAbstract Core actor presence mismatch")
T.equal(abstract.record.role, "trader",
    "abstract trader role was not promoted into Hoomans record")
T.truthy(abstract.record.roles
    and abstract.record.roles.trader,
    "abstract trader semantic role was not available on first render")
T.equal(
    abstract.record.equipment.worn.Torso_Upper,
    "Base.Tshirt",
    "abstract trader clothing did not survive Core->Hoomans projection"
)

T.finish("pnc_core_survivor_world_travel_directory_smoke")
