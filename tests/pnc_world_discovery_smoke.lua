local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/"
local CORE_ROOT = "../psychopatzCore/Contents/mods/PsychopatzCore/42.19/media/lua/"
local CORE_COMMON = "../psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = ROOT .. "shared/?.lua;" .. ROOT .. "server/?.lua;"
    .. CORE_COMMON .. "?.lua;" .. CORE_ROOT .. "shared/?.lua;"
    .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local persisted = {}
local nowMS = 0
local hour = 10
local characterUUID = "character:test"
local player = {
    x = 1000, y = 1000,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getUsername = function() return "Casey Morgan" end,
    getAccessLevel = function() return "admin" end,
}

isClient = function() return false end
isServer = function() return false end
isDebugEnabled = function() return true end
getSpecificPlayer = function() return player end
getGameTime = function()
    return { getWorldAgeHours = function() return hour end }
end
ModData = {
    getOrCreate = function(key)
        persisted[key] = persisted[key] or {}
        return persisted[key]
    end,
}
Events = {
    OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end },
    OnTick = { Add = function() end },
}

PNC = {
    Core = { Now = function() return nowMS end },
    PlayerCharacters = {
        GetCharacterUUID = function() return characterUUID end,
    },
}

dofile(CORE_ROOT
    .. "shared/PsychopatzCore/00_PsychopatzCore_Init.lua")
local airedBroadcasts = {}
PsychopatzCore.CustomRadio.AirEvent = function(channelID, eventType, context)
    airedBroadcasts[#airedBroadcasts + 1] = {
        channelID = channelID,
        eventType = eventType,
        context = context,
    }
    return true
end
dofile(ROOT .. "shared/PNC/Core/Discovery/PNC_WorldDiscoveryTypes.lua")
dofile(ROOT .. "shared/PNC/Core/Discovery/PNC_RadioDiscoveryChannel.lua")

local communities = {
    settlement_one = {
        id = "settlement_one", name = "Haven", status = "active",
        factionID = "faction_haven", currentPopulation = 6,
        memberIDs = { npc_two = true }, leaderNPCID = "npc_two",
        site = { home = { x = 100, y = 200, z = 0 } },
    },
}
local groups = {
    group_one = {
        id = "group_one", factionId = "faction_roam",
        groupType = "REFUGEE", memberIds = { "npc_one", "npc_two" },
        location = { x = 120, y = 220, z = 0 },
    },
}
PNC.Communities = {
    List = function() return { communities.settlement_one } end,
    Get = function(id) return communities[id] end,
}
PNC.AbstractGroups = {
    List = function() return { groups.group_one } end,
    Get = function(id) return groups[id] end,
    FindByFactionID = function(id)
        return id == "faction_roam" and groups.group_one or nil
    end,
}
PNC.Factions = {
    Get = function(id)
        return { id = id, name = id == "faction_roam"
            and "Road Refugees" or "Haven Faction",
            archetypeID = id == "faction_roam" and "refugee" or "settler" }
    end,
}
local settlementBaseAvailable = false
PNC.BaseService = {
    GetForColony = function(id)
        if settlementBaseAvailable and id == "settlement_one" then
            return { id = "base_one", colonyId = id }
        end
    end,
    BuildSnapshot = function(base)
        if not base then return nil end
        return { geometry = { bounds = {
            minX = 90, minY = 190, maxX = 110, maxY = 210,
            minZ = 0, maxZ = 0,
        } } }
    end,
}
PNC.Registry = {
    Get = function(id)
        return {
            id = id,
            name = id == "npc_one" and "Mara Cole" or "Jonas Reed",
            alive = true,
            identity = { displayName = id == "npc_one"
                and "Mara Cole" or "Jonas Reed", survivor = {
                forename = id == "npc_one" and "Mara" or "Jonas",
                surname = id == "npc_one" and "Cole" or "Reed",
            } },
            affiliation = {
            communityID = "settlement_one",
            factionID = "faction_roam",
        } }
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

dofile(ROOT .. "server/PNC/WorldDiscovery/PNC_WorldDiscovery.lua")
local Discovery = PNC.WorldDiscovery
local Types = PNC.WorldDiscoveryTypes
equal(PNC.RadioDiscoveryChannel.FREQUENCY, 69000,
    "scan channel uses 69.0 MHz")

local disclosures = {}
PNC.NPCKnowledge = {
    DiscoverTopicForPlayer = function(_, npcID, topicID, _, sourceType)
        disclosures[#disclosures + 1] = {
            npcID = npcID, topicID = topicID, sourceType = sourceType,
        }
        return { revealed = { "identity.name", "faction.identity" } }
    end,
    BuildPlayerSnapshotForPlayer = function(_, npcID)
        return { npcID = npcID, categories = {} }
    end,
}
PNC.Network = { SendNPCKnowledge = function() end }
Discovery.RadioIdentityRevealRoll = function() return 0 end
Discovery.RadioRandomIndex = function() return 1 end

local refugeeFlavor = PsychopatzCore.CustomRadio.SelectMessage(
    PNC.RadioDiscoveryChannel.ID, "discovery", {
        kind = Types.KIND_MOBILE_GROUP,
        groupType = "REFUGEE",
        location = "grid 10, 20",
        random = function() return 1 end,
    })
equal(refugeeFlavor.packID, "projecthoomans.refugee",
    "refugees use their dedicated believable message pack")
local looterFlavor = PsychopatzCore.CustomRadio.SelectMessage(
    PNC.RadioDiscoveryChannel.ID, "discovery", {
        kind = Types.KIND_MOBILE_GROUP,
        groupType = "LOOTER",
        location = "grid 10, 20",
        random = function() return 1 end,
    })
equal(looterFlavor.packID, "projecthoomans.looter",
    "looters use their deceptive message pack")

local function entityOf(snapshot, kind)
    for _, entity in ipairs(snapshot.entities or {}) do
        if entity.kind == kind then return entity end
    end
    return nil
end

Discovery.Load()
equal(#Discovery.BuildSnapshot(player).entities, 0,
    "new character starts with no discovered entities")
equal(Discovery.ResolveEntity(Types.KIND_SETTLEMENT, "settlement_one"), nil,
    "community without a claimed base emits no settlement signal")
settlementBaseAvailable = true

local rumor = Discovery.SetPhase(player, Types.KIND_SETTLEMENT,
    "settlement_one", Types.PHASE_RUMORED, "radio")
equal(rumor.phase, Types.PHASE_RUMORED,
    "radio can create a rumored settlement")
local rumoredSnapshot = Discovery.BuildSnapshot(player)
equal(rumoredSnapshot.entities[1].approximate, true,
    "rumored map position is approximate")
equal(rumoredSnapshot.entities[1].name, "Unknown settlement",
    "rumor does not leak settlement identity")
Discovery.SetPhase(player, Types.KIND_SETTLEMENT,
    "settlement_one", Types.PHASE_LOCATED, "traversal")
Discovery.SetPhase(player, Types.KIND_SETTLEMENT,
    "settlement_one", Types.PHASE_RUMORED, "radio")
equal(Discovery.BuildSnapshot(player).entities[1].phase,
    Types.PHASE_LOCATED, "discovery phases never regress")

player.x, player.y = 100, 200
hour = 11
local missed = Discovery.RadioScan(player, "wrong.channel",
    PNC.RadioDiscoveryChannel.FREQUENCY)
equal(missed.result.reason, "invalid_channel",
    "only the registered vanilla scan channel can discover signals")
local radio = Discovery.RadioScan(player,
    PNC.RadioDiscoveryChannel.ID, PNC.RadioDiscoveryChannel.FREQUENCY)
equal(radio.result.ok, true, "radio finds an undiscovered mobile group")
equal(radio.result.phase, Types.PHASE_RUMORED,
    "first radio hit records a rumor")
equal(#airedBroadcasts, 1,
    "a discovery trigger airs one native custom-channel broadcast")
equal(airedBroadcasts[1].context.groupType, "REFUGEE",
    "broadcast context identifies the discovered group kind")
equal(airedBroadcasts[1].context.playerFirstName, "Casey",
    "broadcast templates expose the player's first name")
equal(airedBroadcasts[1].context.npcFullName, "Mara Cole",
    "radio speaker identity comes from a real group member")
equal(airedBroadcasts[1].context.factionName, "Road Refugees",
    "introduced speaker exposes the real faction name token")
equal(disclosures[1].npcID, "npc_one",
    "radio introduction persists knowledge for the speaking NPC")
equal(disclosures[1].topicID, "identity_name",
    "radio introduction uses the same identity topic as asking a name")
airedBroadcasts[1].context.random = function() return 1 end
local dynamicFlavor = PsychopatzCore.CustomRadio.SelectMessage(
    PNC.RadioDiscoveryChannel.ID, "discovery",
    airedBroadcasts[1].context
)
equal(dynamicFlavor.lines[2].text,
    "Mara Cole: Mayday, mayday. Is anyone still listening?",
    "native chatter names the real selected group member")
equal(dynamicFlavor.lines[3].text,
    "Jonas: Tell them about the wounded. The fever is getting worse.",
    "background reply uses another real group member")
equal(Discovery.RADIO_IDENTITY_REVEAL_CHANCE, 35,
    "radio identity introductions remain chance based")
Discovery.RadioIdentityRevealRoll = function() return 99 end
local anonymousContext = Discovery.BuildRadioTemplateContext(
    player,
    Discovery.ResolveEntity(Types.KIND_MOBILE_GROUP, "group_one"),
    Types.PHASE_RUMORED
)
equal(anonymousContext.identityIntroduced, false,
    "most broadcasts can remain anonymous")
equal(anonymousContext.npcFullName, "unknown caller",
    "anonymous broadcasts do not leak the selected member name")
Discovery.RadioIdentityRevealRoll = function() return 0 end

hour = 12
local located = Discovery.RadioScan(player,
    PNC.RadioDiscoveryChannel.ID, PNC.RadioDiscoveryChannel.FREQUENCY)
equal(located.result.phase, Types.PHASE_LOCATED,
    "second radio hit triangulates the same signal")
equal(#airedBroadcasts, 2,
    "each successful discovery can randomize a fresh broadcast")

Discovery.DiscoverNPCContext(player, "npc_one")
local contacted = Discovery.BuildSnapshot(player)
equal(entityOf(contacted, Types.KIND_SETTLEMENT).phase,
    Types.PHASE_CONTACTED,
    "conversation contacts settlement")
equal(entityOf(contacted, Types.KIND_MOBILE_GROUP).phase,
    Types.PHASE_CONTACTED,
    "conversation contacts mobile group")
equal(entityOf(contacted, Types.KIND_SETTLEMENT).name, "Haven",
    "contact reveals settlement identity")

characterUUID = "character:debug-all"
local debugAll = Discovery.HandleAction(player, {
    action = "debug_discover_all", scope = "all",
})
equal(debugAll.result.ok, true,
    "debug map can discover every strategic entity")
equal(debugAll.result.count, 2,
    "discover-all advances settlement and mobile group together")
equal(#debugAll.entities, 2,
    "discover-all returns both entities in one snapshot")
equal(debugAll.entities[1].phase, Types.PHASE_LOCATED,
    "debug discovery reveals an exact map location")

Discovery.Registry = {}
Discovery.Loaded = false
Discovery.Load()
equal(#Discovery.BuildSnapshot(player).entities, 2,
    "discovery persists across reload")

print("pnc_world_discovery_smoke: ok")
