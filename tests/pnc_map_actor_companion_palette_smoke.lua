-- Verifies ProjectHoomans' unified CoreActorMap decorator resolves companion,
-- colonist, hostile, neutral, and dead colors from Hoomans client state even
-- when PsychopatzCore's canonical projection entry carries no Hoomans-private
-- fields, while preserving DynamicTrading trader styling and server-side
-- per-player visibility culling.

local T = require "tests/support/test"
T.addPackagePaths()

isClient = function() return false end
isServer = function() return true end

PNC = PNC or {}
PNC.Const = {
    TACTICAL_CLASS_COLONIST = "colonist",
    TACTICAL_CLASS_NEUTRAL = "neutral",
    TACTICAL_CLASS_HOSTILE = "hostile",
    ORDER_FOLLOW = "follow",
    PRESENCE_CORPSE = "corpse",
}

local coreActors = {
    {
        actorID = "npc_follower",
        label = "Anton patz",
        provider = "ProjectHoomans",
        providerState = "live",
        presenceState = "live",
        position = { x = 100, y = 100, z = 0 },
        factionID = "faction_player",
    },
    {
        actorID = "npc_colonist",
        label = "Jarvis patz",
        provider = "ProjectHoomans",
        providerState = "live",
        presenceState = "live",
        position = { x = 110, y = 100, z = 0 },
        factionID = "faction_player",
    },
    {
        actorID = "core_actor_camped_tod",
        label = "Tod patz",
        provider = "ProjectHoomans",
        providerState = "abstract",
        presenceState = "abstract",
        position = { x = 115, y = 100, z = 0 },
        factionID = "faction_player",
    },
    {
        actorID = "npc_hostile",
        label = "Raider Bob",
        provider = "ProjectHoomans",
        providerState = "live",
        presenceState = "live",
        position = { x = 120, y = 100, z = 0 },
        factionID = "faction_raiders",
    },
    {
        actorID = "npc_neutral",
        label = "Wandering Joe",
        provider = "ProjectHoomans",
        providerState = "live",
        presenceState = "live",
        position = { x = 130, y = 100, z = 0 },
        factionID = "faction_neutrals",
    },
    {
        actorID = "npc_trader",
        label = "Merchant Ada",
        provider = "DynamicTrading",
        providerState = "abstract",
        presenceState = "abstract",
        position = { x = 140, y = 100, z = 0 },
        factionID = "faction_traders",
    },
}

PNC.ClientState = {
    snapshots = {
        npc_follower = {
            id = "npc_follower",
            recruited = true,
            colonyOwned = true,
            tacticalClass = "colonist",
            orderKind = "follow",
            alive = true,
        },
        npc_colonist = {
            id = "npc_colonist",
            recruited = true,
            colonyOwned = true,
            tacticalClass = "colonist",
            orderKind = "guard",
            alive = true,
        },
        npc_camped_tod = {
            id = "npc_camped_tod",
            coreActorID = "core_actor_camped_tod",
            recruited = true,
            colonyOwned = true,
            tacticalClass = "colonist",
            orderKind = "camp",
            alive = true,
        },
        npc_hostile = {
            id = "npc_hostile",
            recruited = false,
            tacticalClass = "hostile",
            alive = true,
        },
        npc_neutral = {
            id = "npc_neutral",
            recruited = false,
            tacticalClass = "neutral",
            alive = true,
        },
    },
}

local fakeClient = {
    Selection = {},
    RequestActorsIfDue = function() return false, "not_due" end,
    ListActors = function() return coreActors end,
    GetTracked = function() return nil end,
    SetSelected = function() end,
    SetHighlighted = function() end,
    SetTracked = function() end,
}
package.preload["PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"] =
    function() return fakeClient end
package.preload["PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldMapHover"] =
    function() return { Update = function() end, Hide = function() end } end
package.preload["PsychopatzCore/UI/Map/PsychopatzMapHost"] =
    function()
        return {
            Overlays = { Register = function() end },
            Events = { Register = function() end },
            Contexts = { Register = function() end },
        }
    end

PsychopatzCore = PsychopatzCore or {}
getTimestampMs = function() return 5000 end

local CoreActorMap = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldActorMap"
local Palette = require "PNC/Presentation/PNC_NPCTypePalette"
require "PNC/UI/Map/PNC_MapActorPresentation"

-- Register a mock DynamicTrading trader decorator at priority 100 to verify
-- both mods share CoreActorMap cleanly without overriding each other.
local TRADER_COLOR = { r = 0.20, g = 0.85, b = 0.95, a = 1.0 }
CoreActorMap.RegisterDecorator("DynamicTrading:Trader", {
    priority = 100,
    decorate = function(entry, style)
        if entry.actorID == "npc_trader" then
            style.color = TRADER_COLOR
            style.hoverMetadata = { traderID = "trader:1" }
        end
        return style
    end,
})

local markers = CoreActorMap.BuildMarkers()
local byID = {}
for _, m in ipairs(markers) do byID[m.actorID] = m end

local function assertColor(actual, expected, label)
    T.truthy(actual, label .. " missing color")
    T.equal(actual.r, expected.r, label .. " r")
    T.equal(actual.g, expected.g, label .. " g")
    T.equal(actual.b, expected.b, label .. " b")
end

assertColor(byID.npc_follower.color, Palette.COLORS.follower,
    "following companion must render bright green (not yellow)")
assertColor(byID.npc_colonist.color, Palette.COLORS.colonist,
    "colony-owned colonist must render dark green (not yellow)")
assertColor(byID.core_actor_camped_tod.color, Palette.COLORS.colonist,
    "abstract camped colonist with separate coreActorID must render dark green (not yellow)")
assertColor(byID.npc_hostile.color, Palette.COLORS.hostile,
    "hostile NPC must render red")
assertColor(byID.npc_neutral.color, Palette.COLORS.neutral,
    "neutral NPC must render yellow")
assertColor(byID.npc_trader.color, TRADER_COLOR,
    "DynamicTrading trader must keep trader color via shared CoreActorMap")

-- Server visibility filter check (PNC_CoreSurvivorWorldPresentationAdapter)
PNC.Registry = {
    Get = function(id)
        if id == "npc_follower" then
            return { id = id, recruited = true, ownerUsername = "alice" }
        end
        return nil
    end,
}
PNC.Factions = {
    GetPlayerFaction = function() return { id = "faction_player" } end,
}
local Adapter = require "PNC/Director/PNC_CoreSurvivorWorldPresentationAdapter"
local alice = {
    getUsername = function() return "alice" end,
    getX = function() return 1000 end,
    getY = function() return 1000 end,
}
local mockWorldRegistry = {
    GetDiscovery = function()
        return {
            players = {
                ["player:alice"] = {
                    entities = {
                        group = {
                            group_discovered = { phase = 1 },
                        },
                        community = {},
                    },
                },
            },
        }
    end,
}

T.truthy(Adapter.IsVisibleToPlayer(
    { actorID = "npc_follower", factionID = "faction_player",
        position = { x = 9000, y = 9000 } },
    nil, nil, alice, mockWorldRegistry
), "player companion must stay visible at any distance")

T.truthy(Adapter.IsVisibleToPlayer(
    { actorID = "npc_nearby", groupID = "group_undiscovered",
        position = { x = 1050, y = 1050 } },
    nil, nil, alice, mockWorldRegistry
), "nearby NPC within 120 tiles must be visible")

T.falsy(Adapter.IsVisibleToPlayer(
    { actorID = "npc_far_hidden", groupID = "group_undiscovered",
        position = { x = 8000, y = 8000 } },
    nil, nil, alice, mockWorldRegistry
), "distant undiscovered group NPC must be culled server-side")

T.truthy(Adapter.IsVisibleToPlayer(
    { actorID = "npc_far_discovered", groupID = "group_discovered",
        position = { x = 8000, y = 8000 } },
    nil, nil, alice, mockWorldRegistry
), "distant discovered group NPC must be visible")

T.finish("pnc_map_actor_companion_palette_smoke")
