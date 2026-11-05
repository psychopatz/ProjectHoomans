local T = require "tests/support/test"
T.addPackagePaths()

local providers = {}
local requests = 0
local knownName

PNC = {
    Network = {
        ClientState = {
            npcKnowledge = {},
            npcPresentations = {
                ["npc:map:one"] = {
                    state = "unknown",
                    knowledgePending = false,
                },
            },
        },
    },
    Client = {
        RequestNPCKnowledge = function(actorID)
            requests = requests + 1
            return true, actorID
        end,
    },
    NPCIdentityPresentation = {
        GetKnownName = function()
            return knownName
        end,
        GetFaction = function()
            return {
                id = "faction:map",
                name = "Map Faction",
                role = "trader",
            }
        end,
        GetFactionName = function()
            return "Map Faction"
        end,
    },
}

package.preload[
    "PNC/Knowledge/PNC_NPCIdentityPresentation"
] = function()
    return PNC.NPCIdentityPresentation
end
package.preload[
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
] = function()
    return {
        RegisterActorKnowledgeProvider = function(id, adapter)
            providers[id] = adapter
            return true, id
        end,
    }
end
package.preload[
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldMapHover"
] = function()
    return {
        RegisterProvider = function(id, adapter)
            providers["hover:" .. id] = adapter
            return true, id
        end,
    }
end

local Adapter = T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/Map/PNC_MapCoreActorKnowledge.lua"
)
T.truthy(Adapter and providers.ProjectHoomans,
    "Project Hoomans did not register the Core knowledge adapter")
T.truthy(providers.DTHoomans,
    "DTHoomans did not reuse the Project Hoomans knowledge adapter")
T.truthy(providers["hover:ProjectHoomans"],
    "Project Hoomans did not register the shared Core hover adapter")

local entry = {
    id = "npc:map:one",
    portrait = {
        identitySeed = 7,
        isFemale = true,
        appearance = { hairModel = "Long" },
        equipment = { worn = { Hat = "Base.Hat_HardHat" } },
    },
}
local unknown = providers.ProjectHoomans.get(entry)
T.falsy(unknown.nameKnown,
    "Project Hoomans exposed an unknown actor as known to Core")
T.truthy(providers.ProjectHoomans.request(entry.id),
    "Project Hoomans knowledge request did not reach its client transport")
T.equal(requests, 1,
    "Project Hoomans knowledge request was not issued exactly once")

knownName = "Mara Voss"
local known = providers.ProjectHoomans.get(entry)
T.truthy(known.nameKnown and known.knownName == knownName,
    "Core adapter did not consume the learned Hoomans identity")
T.equal(known.state, "known",
    "learned Hoomans identity did not override stale unknown presentation")
local portrait = providers.ProjectHoomans.getPortraitSpec(entry)
T.truthy(portrait and portrait.preferDescriptor
    and portrait.includeCurrentClothing
    and portrait.equipment.worn.Hat == "Base.Hat_HardHat",
    "Core hover adapter lost the Hoomans portrait/equipment projection")

T.finish("pnc_map_hover_portrait_smoke")
