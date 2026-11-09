local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "client", "PNC/UI/Map/")
    .. "PNC_MapActorPresentation.lua"
local PALETTE =
    T.path("ProjectHoomans", "client", "PNC/Presentation/")
    .. "PNC_NPCTypePalette.lua"

local sourceID
local sourceDefinition
local decoratorID
local decoratorDefinition
local namesVisible = true

PNC = {
    Const = {
        ORDER_FOLLOW = "follow",
    },
    TravelDirectory = {
        ListSupplementalActors = function()
            return {
                {
                    id = "core_actor",
                    actorID = "core_actor",
                    name = "Duplicate Core Actor",
                },
                {
                    id = "supplemental_actor",
                    name = "Supplemental Actor",
                    tacticalClass = "neutral",
                    role = "trader",
                    iconID = "supplemental_icon",
                    x = 30,
                    y = 40,
                },
            }
        end,
    },
    MapDisplay = {
        AreNamesVisible = function() return namesVisible end,
    },
    MapMarkerIcons = {
        Resolve = function(iconID)
            if iconID ~= "supplemental_icon" then return nil end
            return {
                glyph = "X",
                size = 10,
                color = { r = 1, g = 0, b = 0, a = 1 },
            }
        end,
    },
    NPCIdentityPresentation = {
        GetName = function(entry)
            return entry and entry.name or "Unknown"
        end,
        GetKnownName = function(entry)
            return entry and entry.name or nil
        end,
        IsNameKnown = function() return true end,
    },
}

local coreEntries = {
    {
        actorID = "core_actor",
        label = "Core Actor",
        provider = "DTHoomans",
        providerState = "materialized",
        position = { x = 10, y = 20, z = 0 },
    },
}

local CoreClient = {
    ListActors = function(raw)
        T.equal(raw, false,
            "Hoomans queried the unspread canonical actor list incorrectly")
        return coreEntries
    end,
}
package.preload[
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
] = function()
    return CoreClient
end

local CoreActorMap = {
    RegisterSource = function(id, definition)
        sourceID = id
        sourceDefinition = definition
        return true
    end,
    RegisterDecorator = function(id, definition)
        decoratorID = id
        decoratorDefinition = definition
        return true
    end,
}
package.preload[
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldActorMap"
] = function()
    return CoreActorMap
end

T.load(PALETTE)
package.preload["PNC/Presentation/PNC_NPCTypePalette"] =
    function() return PNC.NPCTypePalette end
package.preload["PNC/Knowledge/PNC_NPCIdentityPresentation"] =
    function() return PNC.NPCIdentityPresentation end
T.load(FILE)

T.equal(sourceID, "ProjectHoomans:SupplementalActors",
    "Hoomans did not register the provider-neutral supplemental source")
T.truthy(sourceDefinition and sourceDefinition.list,
    "supplemental source did not expose a list query")
T.equal(decoratorID, "ProjectHoomans",
    "Hoomans did not register its Core presentation decorator")
T.truthy(decoratorDefinition and decoratorDefinition.decorate,
    "Hoomans decorator did not expose a decorate function")
local rows = sourceDefinition.list()
T.equal(#rows, 1,
    "supplemental source reintroduced canonical Core actors")
T.equal(rows[1].id, "supplemental_actor",
    "supplemental source returned the wrong actor")

local supplementalStyle = decoratorDefinition.decorate(rows[1], {})
T.equal(supplementalStyle.label, "Supplemental Actor [trader]",
    "Hoomans did not preserve the actor label convention")
T.equal(supplementalStyle.color.r, 0.95,
    "supplemental actor did not use the shared neutral palette")
T.equal(supplementalStyle.size, 9,
    "Hoomans actor marker did not use the Core marker size")
T.truthy(supplementalStyle.showLabel,
    "Hoomans names-visible setting did not reach Core marker style")
T.equal(supplementalStyle.icon.glyph, "X",
    "Hoomans marker icon was not translated into the Core style contract")

local coreStyle = decoratorDefinition.decorate(coreEntries[1], {})
T.equal(coreStyle.label, "Core Actor",
    "Hoomans decorator did not style canonical Core actors")

local traderStyle = decoratorDefinition.decorate(rows[1], {
    label = "Dynamic Trader",
    hoverMetadata = { traderID = "trader:1" },
})
T.equal(traderStyle.label, "Dynamic Trader",
    "Hoomans decorator replaced DynamicTrading trader identity")

namesVisible = false
local hiddenStyle = decoratorDefinition.decorate(rows[1], {})
T.falsy(hiddenStyle.showLabel,
    "Hoomans marker label remained visible after names were disabled")
T.finish("pnc_map_actor_presentation_smoke")
