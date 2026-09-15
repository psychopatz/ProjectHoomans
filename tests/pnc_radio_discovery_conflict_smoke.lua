local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "root", "")
local CORE_ROOT = T.path("PsychopatzCore", "root", "")
T.addPackagePaths()

local characterUUID = "character:radio-conflict"
local player = {
    getX = function() return 100 end,
    getY = function() return 100 end,
}

PNC = {
    Core = { Now = function() return 0 end },
    PlayerCharacters = {
        GetCharacterUUID = function() return characterUUID end,
    },
}

T.load(CORE_ROOT .. "shared/PsychopatzCore/00_PsychopatzCore_Init.lua")
T.load(ROOT .. "shared/PNC/Core/Discovery/PNC_WorldDiscoveryTypes.lua")
T.load(ROOT .. "shared/PNC/Core/Discovery/PNC_RadioDiscoveryChannel.lua")

local factions = {
    faction_looter = {
        id = "faction_looter", name = "Red Hand",
        archetypeID = "looter",
    },
    faction_neutral = {
        id = "faction_neutral", name = "Wayfarers",
        archetypeID = "wanderer",
    },
    faction_player = {
        id = "faction_player", name = "Camp Survivors",
        archetypeID = "settler",
    },
}
local records = {
    npc_looter = {
        id = "npc_looter", name = "Bob Jones", alive = true,
        tacticalClass = "neutral",
        identity = { displayName = "Bob Jones", survivor = {
            forename = "Bob", surname = "Jones",
        } },
        affiliation = { factionID = "faction_looter" },
    },
    npc_neutral = {
        id = "npc_neutral", name = "Janet Smith", alive = true,
        tacticalClass = "neutral",
        identity = { displayName = "Janet Smith", survivor = {
            forename = "Janet", surname = "Smith",
        } },
        affiliation = { factionID = "faction_neutral" },
    },
    npc_colonist = {
        id = "npc_colonist", name = "Casey Doe", alive = true,
        recruited = true, tacticalClass = "colonist",
        identity = { displayName = "Casey Doe", survivor = {
            forename = "Casey", surname = "Doe",
        } },
        affiliation = { factionID = "faction_player" },
    },
}
local groups = {
    group_looter = {
        id = "group_looter", factionId = "faction_looter",
        groupType = "LOOTER", memberIds = { "npc_looter" },
        location = { x = 110, y = 110, z = 0 },
    },
    group_neutral = {
        id = "group_neutral", factionId = "faction_neutral",
        groupType = "WANDERER", memberIds = { "npc_neutral" },
        location = { x = 120, y = 120, z = 0 },
    },
    group_player = {
        id = "group_player", factionId = "faction_player",
        groupType = "SETTLEMENT_PARTY", memberIds = { "npc_colonist" },
        location = { x = 130, y = 130, z = 0 },
    },
}

PNC.Factions = {
    Get = function(id) return factions[id] end,
    GetPlayerFaction = function() return factions.faction_player end,
}
PNC.Registry = {
    Get = function(id) return records[id] end,
}
PNC.AbstractGroups = {
    List = function()
        return { groups.group_looter, groups.group_neutral,
            groups.group_player }
    end,
    Get = function(id) return groups[id] end,
}
PNC.PlayerContext = {
    Resolve = function()
        return { characterUUID = characterUUID, playerNameKnowledge = {} }
    end,
}
PNC.Identity = {
    GetCharacterSummary = function(record)
        return {
            displayName = record.identity.displayName,
            survivor = record.identity.survivor,
        }
    end,
}

T.load(ROOT .. "server/PNC/WorldDiscovery/PNC_WorldDiscovery.lua")
local Discovery = PNC.WorldDiscovery
local Types = PNC.WorldDiscoveryTypes
local Internal = Discovery.RadioBroadcastsInternal

Discovery.RadioRandomIndex = function() return 1 end
Discovery.RadioConflictRoll = function() return 0 end
Discovery.RadioArgumentRoll = function() return 99 end
Discovery.RadioIdentityRevealRoll = function() return 99 end

local function entityOf(entityID)
    for _, entity in ipairs(Discovery.ListWorldEntities()) do
        if entity.entityID == entityID then return entity end
    end
    return nil
end

local looterEntity = T.truthy(entityOf("group_looter"),
    "looter entity is available to radio discovery")
local conflictContext = Discovery.BuildRadioTemplateContext(
    player, looterEntity, Types.PHASE_RUMORED)
T.equal(Discovery.RADIO_CONFLICT_CHANCE, 15,
    "cross-faction conflict remains an occasional flavor variant")
T.equal(conflictContext.conflictVariant, true,
    "deterministic conflict roll enables cross-faction flavor")
T.equal(conflictContext.conflictScenario, "looter_neutral",
    "looter versus neutral is preferred when both are available")
T.equal(conflictContext.conflictPrimaryFactionID, "faction_looter",
    "the scanned faction remains the conflict primary")
T.equal(conflictContext.conflictSecondaryFactionID, "faction_neutral",
    "the conflict secondary belongs to a different faction")
T.equal(conflictContext.speakerNPCID, "npc_looter",
    "the primary conflict voice comes from the scanned entity")
T.equal(conflictContext.secondarySpeakerNPCID, "npc_neutral",
    "the secondary conflict voice comes from the other faction")
T.equal(conflictContext.conflictPrimaryName, "Bob",
    "the primary target name is available only to conflict flavor")
T.equal(conflictContext.conflictSecondaryName, "Janet",
    "the secondary target name is available only to conflict flavor")
T.equal(conflictContext.identityIntroduced, false,
    "conflict names do not depend on the identity introduction roll")
T.equal(conflictContext.npcFullName, "unknown caller",
    "conflict names do not leak through normal identity fields")
T.equal(conflictContext.argumentVariant, false,
    "cross-faction conflict takes precedence over same-faction argument")

conflictContext.random = function() return 1 end
local conflictFlavor = PsychopatzCore.CustomRadio.SelectMessage(
    PNC.RadioDiscoveryChannel.ID, "discovery", conflictContext)
T.equal(conflictFlavor.packID, "projecthoomans.conflict",
    "cross-faction flavor uses the dedicated conflict message pack")
T.equal(conflictFlavor.lines[2].speakerRole, "primary",
    "conflict starts with the scanned faction speaker")
T.equal(conflictFlavor.lines[3].speakerRole, "secondary",
    "conflict replies with the other faction speaker")
T.equal(conflictFlavor.lines[2].text,
    "Janet, you're an idiot.",
    "conflict flavor names the other faction's target")
T.equal(conflictFlavor.lines[3].text,
    "No, Bob, you're the one who's an idiot here.",
    "conflict flavor lets the second speaker name its target")

local disclosures = {}
PNC.NPCKnowledge = {
    GetDescriptor = function() return nil end,
    DiscoverTopicForPlayer = function(_, npcID, topicID, _, sourceType)
        disclosures[#disclosures + 1] = {
            npcID = npcID, topicID = topicID, sourceType = sourceType,
        }
        return { revealed = { "faction.identity" } }
    end,
}
PNC.Network = nil
Discovery.MarkFactionRevealed = function()
    return nil, "unchanged"
end
Discovery.RadioIdentityRevealRoll = function() return 0 end
local introducedContext = Discovery.BuildRadioTemplateContext(
    player, looterEntity, Types.PHASE_RUMORED)
Internal.PersistIntroduction(player, introducedContext)
T.equal(#disclosures, 1,
    "conflict introduction persists one faction knowledge record")
T.equal(disclosures[1].npcID, "npc_looter",
    "radio faction knowledge remains scoped to the scanned speaker")
T.equal(disclosures[1].topicID, "faction",
    "conflict names never persist as the identity name topic")

PNC.AbstractGroups.List = function()
    return { groups.group_player, groups.group_looter }
end
local playerEntity = T.truthy(entityOf("group_player"),
    "player faction entity is available for the colonist conflict case")
local colonistContext = Discovery.BuildRadioTemplateContext(
    player, playerEntity, Types.PHASE_RUMORED)
T.equal(colonistContext.conflictScenario, "looter_colonist",
    "looter versus player colonist is supported as a secondary scenario")
T.equal(colonistContext.conflictPrimaryFactionID, "faction_player",
    "player colonist remains the scanned primary when selected")
T.equal(colonistContext.conflictSecondaryFactionID, "faction_looter",
    "looter colonist conflict keeps factions distinct")
T.equal(colonistContext.conflictPrimaryName, "Casey",
    "player colonist supplies a presentation-only target name")
T.equal(colonistContext.conflictSecondaryName, "Bob",
    "looter supplies a presentation-only target name")

T.finish("pnc_radio_discovery_conflict_smoke")
