local T = require "tests/support/test"
T.addPackagePaths()

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
                ["supplemental:actor"] = {
                    id = "supplemental:actor",
                    name = "Supplemental Actor",
                    tacticalClass = "neutral",
                    presenceState = "live",
                    alive = true,
                    x = 120,
                    y = 240,
                    z = 0,
                    affiliation = {
                        factionID = "faction:supplemental",
                        role = "member",
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

local entries = Directory.ListSupplementalActors(10)
T.equal(#entries, 1,
    "supplemental actor directory did not return its bounded records")
local entry = entries[1]
T.equal(entry.id, "supplemental:actor",
    "supplemental actor identity changed")
T.equal(entry.name, "Supplemental Actor",
    "supplemental actor name was not retained")
T.equal(entry.x, 120,
    "supplemental actor position was not retained")
T.equal(entry.y, 240,
    "supplemental actor position was not retained")
T.equal(entry.organizationalFaction.id, "faction:supplemental",
    "supplemental actor affiliation was not retained")
T.finish("pnc_core_survivor_world_travel_directory_smoke")
