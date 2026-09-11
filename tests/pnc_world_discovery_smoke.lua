local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "root", "")
local CORE_ROOT = T.path("PsychopatzCore", "root", "")
local CORE_COMMON = T.path("PsychopatzCore", "common", "")
T.addPackagePaths()

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

T.load(CORE_ROOT
    .. "shared/PsychopatzCore/00_PsychopatzCore_Init.lua")
local airedBroadcasts = {}
PsychopatzCore.CustomRadio.AirEvent = function(channelID, eventType, context)
    airedBroadcasts[#airedBroadcasts + 1] = {
        channelID = channelID,
        eventType = eventType,
        context = context,
    }
    return true, PsychopatzCore.CustomRadio.SelectMessage(
        channelID, eventType, context
    )
end
T.load(ROOT .. "shared/PNC/Core/Discovery/PNC_WorldDiscoveryTypes.lua")
T.load(ROOT .. "shared/PNC/Core/Discovery/PNC_RadioDiscoveryChannel.lua")

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

T.load(ROOT .. "server/PNC/WorldDiscovery/PNC_WorldDiscovery.lua")
local Discovery = PNC.WorldDiscovery
local Types = PNC.WorldDiscoveryTypes
T.equal(PNC.RadioDiscoveryChannel.FREQUENCY, 69000,
    "scan channel uses 69.0 MHz")

local disclosures = {}
local knownNames = {}
PNC.PlayerContext = {
    Resolve = function()
        return { characterUUID = characterUUID }
    end,
}
PNC.NPCKnowledge = {
    DiscoverTopicForPlayer = function(_, npcID, topicID, _, sourceType)
        disclosures[#disclosures + 1] = {
            npcID = npcID, topicID = topicID, sourceType = sourceType,
        }
        return { revealed = { "identity.name", "faction.identity" } }
    end,
    GetDescriptor = function(_, npcID, descriptorID)
        if descriptorID == "identity.name" and knownNames[npcID] then
            return { value = npcID == "npc_one" and "Mara Cole"
                or "Jonas Reed" }
        end
        return nil
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
T.equal(refugeeFlavor.packID, "projecthoomans.refugee",
    "refugees use their dedicated believable message pack")
local looterFlavor = PsychopatzCore.CustomRadio.SelectMessage(
    PNC.RadioDiscoveryChannel.ID, "discovery", {
        kind = Types.KIND_MOBILE_GROUP,
        groupType = "LOOTER",
        location = "grid 10, 20",
        random = function() return 1 end,
    })
T.equal(looterFlavor.packID, "projecthoomans.looter",
    "looters use their deceptive message pack")

local function entityOf(snapshot, kind)
    for _, entity in ipairs(snapshot.entities or {}) do
        if entity.kind == kind then return entity end
    end
    return nil
end

Discovery.Load()
T.equal(#Discovery.BuildSnapshot(player).entities, 0,
    "new character starts with no discovered entities")
T.equal(Discovery.ResolveEntity(Types.KIND_SETTLEMENT, "settlement_one"), nil,
    "community without a claimed base emits no settlement signal")
settlementBaseAvailable = true

local rumor = Discovery.SetPhase(player, Types.KIND_SETTLEMENT,
    "settlement_one", Types.PHASE_RUMORED, "radio")
T.equal(rumor.phase, Types.PHASE_RUMORED,
    "radio can create a rumored settlement")
local rumoredSnapshot = Discovery.BuildSnapshot(player)
T.equal(rumoredSnapshot.entities[1].approximate, true,
    "rumored map position is approximate")
T.equal(rumoredSnapshot.entities[1].name, "Unknown settlement",
    "rumor does not leak settlement identity")
Discovery.SetPhase(player, Types.KIND_SETTLEMENT,
    "settlement_one", Types.PHASE_LOCATED, "traversal")
Discovery.SetPhase(player, Types.KIND_SETTLEMENT,
    "settlement_one", Types.PHASE_RUMORED, "radio")
T.equal(Discovery.BuildSnapshot(player).entities[1].phase,
    Types.PHASE_LOCATED, "discovery phases never regress")

player.x, player.y = 100, 200
hour = 11
local missed = Discovery.RadioScan(player, "wrong.channel",
    PNC.RadioDiscoveryChannel.FREQUENCY)
T.equal(missed.result.reason, "invalid_channel",
    "only the registered vanilla scan channel can discover signals")
local radio = Discovery.RadioScan(player,
    PNC.RadioDiscoveryChannel.ID, PNC.RadioDiscoveryChannel.FREQUENCY)
T.equal(radio.result.ok, true, "radio finds an undiscovered mobile group")
T.equal(radio.result.phase, Types.PHASE_RUMORED,
    "first radio hit records a rumor")
T.equal(entityOf(radio, Types.KIND_MOBILE_GROUP).factionKnown, true,
    "an introduced radio faction is added to the strategic contact")
T.equal(entityOf(radio, Types.KIND_MOBILE_GROUP).factionName,
    "Road Refugees",
    "the disclosed faction name is visible in the contact snapshot")
T.equal(radio.result.identityRevealed, true,
    "radio scan result preserves the broadcast identity reveal")
T.equal(radio.result.radioBroadcast.speech.effect_profile, "radio",
    "radio scan result selects the radio DSP profile")
T.truthy(#radio.result.radioBroadcast.lines > 0,
    "radio scan result carries speakable broadcast lines")
T.equal(#airedBroadcasts, 1,
    "a discovery trigger airs one native custom-channel broadcast")
local primaryRadioLine
local secondaryRadioLine
for _, line in ipairs(radio.result.radioBroadcast.lines) do
    if line.speakerRole == "secondary" then
        secondaryRadioLine = line
    elseif line.speakerRole == "primary" then
        primaryRadioLine = line
    end
end
T.equal(primaryRadioLine and primaryRadioLine.speakerNPCID,
    airedBroadcasts[1].context.speakerNPCID,
    "radio result keeps the selected primary speaker for voice continuity")
T.equal(secondaryRadioLine and secondaryRadioLine.speakerNPCID,
    airedBroadcasts[1].context.secondarySpeakerNPCID,
    "radio result keeps the selected secondary speaker for voice continuity")
T.equal(airedBroadcasts[1].context.groupType, "REFUGEE",
    "broadcast context identifies the discovered group kind")
T.equal(airedBroadcasts[1].context.playerFirstName, "listener",
    "unknown radio speakers do not receive the player's name")
T.equal(airedBroadcasts[1].context.playerNameKnown, false,
    "radio name addressing is scoped to the selected speaker's knowledge")
T.equal(airedBroadcasts[1].context.npcFullName, "Mara Cole",
    "radio speaker identity comes from a real group member")
T.equal(airedBroadcasts[1].context.factionName, "Road Refugees",
    "introduced speaker exposes the real faction name token")
T.equal(disclosures[1].npcID, "npc_one",
    "radio introduction persists knowledge for the speaking NPC")
T.equal(disclosures[1].topicID, "identity_name",
    "radio introduction uses the same identity topic as asking a name")
T.equal(disclosures[2].topicID, "faction",
    "radio introduction persists the explicitly claimed faction")
local throttled = Discovery.RadioScan(player,
    PNC.RadioDiscoveryChannel.ID, PNC.RadioDiscoveryChannel.FREQUENCY)
T.equal(throttled.result.reason, "radio_cooldown",
    "radio scans are server-throttled after a successful attempt")
T.equal(throttled.result.cooldownSeconds, 1800,
    "the default radio cooldown is thirty in-game minutes")
airedBroadcasts[1].context.random = function() return 1 end
local dynamicFlavor = PsychopatzCore.CustomRadio.SelectMessage(
    PNC.RadioDiscoveryChannel.ID, "discovery",
    airedBroadcasts[1].context
)
T.equal(dynamicFlavor.lines[2].text,
    "Mayday, mayday. Is anyone still listening?",
    "native chatter does not add a speaker label")
T.equal(dynamicFlavor.lines[2].speakerRole, "primary",
    "native chatter marks the primary speaker separately from its text")
T.equal(dynamicFlavor.lines[3].text,
    "Tell them about the wounded. The fever is getting worse.",
    "background reply does not add a speaker label")
T.equal(dynamicFlavor.lines[3].speakerRole, "secondary",
    "background reply marks the secondary speaker separately from its text")
T.equal(Discovery.RADIO_IDENTITY_REVEAL_CHANCE, 35,
    "radio identity introductions remain chance based")
Discovery.RadioIdentityRevealRoll = function() return 99 end
local anonymousContext = Discovery.BuildRadioTemplateContext(
    player,
    Discovery.ResolveEntity(Types.KIND_MOBILE_GROUP, "group_one"),
    Types.PHASE_RUMORED
)
T.equal(anonymousContext.identityIntroduced, false,
    "most broadcasts can remain anonymous")
T.equal(anonymousContext.npcFullName, "unknown caller",
    "anonymous broadcasts do not leak the selected member name")
T.equal(anonymousContext.speakerNPCID, "npc_one",
    "anonymous broadcasts still retain an internal voice-continuity identity")
knownNames.npc_one = true
local knownContext = Discovery.BuildRadioTemplateContext(
    player,
    Discovery.ResolveEntity(Types.KIND_MOBILE_GROUP, "group_one"),
    Types.PHASE_RUMORED
)
T.equal(knownContext.playerFirstName, "Casey",
    "a known speaker may address the player by name")
T.equal(knownContext.playerNameKnown, true,
    "known-name state is attached to the selected radio speaker")
local knownFlavor = PsychopatzCore.CustomRadio.SelectMessage(
    PNC.RadioDiscoveryChannel.ID, "discovery", knownContext
)
local addressedByName = false
for _, line in ipairs(knownFlavor.lines or {}) do
    if string.find(line.text or "", "Casey", 1, true) then
        addressedByName = true
    end
end
T.truthy(addressedByName,
    "known radio speakers may use the player's name in flavor text")
Discovery.RadioIdentityRevealRoll = function() return 0 end

characterUUID = "character:call-contact"
Discovery.SetPhase(player, Types.KIND_MOBILE_GROUP, "group_one",
    Types.PHASE_RUMORED, "radio")
Discovery.MarkFactionRevealed(player,
    Discovery.ResolveEntity(Types.KIND_MOBILE_GROUP, "group_one"),
    "Road Refugees", "radio_disclosure", true)
Discovery.Save()
local called = Discovery.HandleAction(player, {
    action = "call_contact",
    kind = Types.KIND_MOBILE_GROUP,
    entityID = "group_one",
})
T.equal(called.result.reason, "contact_located",
    "calling a known rumor triangulates its exact position")
T.equal(entityOf(called, Types.KIND_MOBILE_GROUP).approximate, false,
    "a called contact returns an exact map position")
T.equal(entityOf(called, Types.KIND_MOBILE_GROUP).factionName,
    "Road Refugees",
    "calling a contact preserves its previously disclosed faction")
characterUUID = "character:test"

hour = 12
local located = Discovery.RadioScan(player,
    PNC.RadioDiscoveryChannel.ID, PNC.RadioDiscoveryChannel.FREQUENCY)
T.equal(located.result.phase, Types.PHASE_LOCATED,
    "second radio hit triangulates the same signal")
T.equal(#airedBroadcasts, 2,
    "each successful discovery can randomize a fresh broadcast")

local mobileEntity = Discovery.ResolveEntity(
    Types.KIND_MOBILE_GROUP, "group_one")
local _, arrivalReason = Discovery.MarkArrived(
    player, mobileEntity, Types.PRESENCE_ABSENT, "traversal")
T.equal(arrivalReason, "advanced",
    "physical traversal records a separate arrival state")
local arrived = entityOf(Discovery.BuildSnapshot(player),
    Types.KIND_MOBILE_GROUP)
T.equal(arrived.arrivalState, Types.ARRIVAL_SEARCHED,
    "arrival state is included in the player snapshot")
T.equal(arrived.presenceStatus, Types.PRESENCE_ABSENT,
    "arrival preserves whether a physical group was found")

Discovery.DiscoverNPCContext(player, "npc_one")
local contacted = Discovery.BuildSnapshot(player)
T.equal(entityOf(contacted, Types.KIND_SETTLEMENT).phase,
    Types.PHASE_CONTACTED,
    "conversation contacts settlement")
T.equal(entityOf(contacted, Types.KIND_MOBILE_GROUP).phase,
    Types.PHASE_CONTACTED,
    "conversation contacts mobile group")
T.equal(entityOf(contacted, Types.KIND_MOBILE_GROUP).arrivalState,
    Types.ARRIVAL_CONTACTED,
    "conversation upgrades the arrival state without deleting knowledge")
T.equal(entityOf(contacted, Types.KIND_MOBILE_GROUP).presenceStatus,
    Types.PRESENCE_PRESENT,
    "conversation confirms physical presence")
T.equal(entityOf(contacted, Types.KIND_SETTLEMENT).name, "Haven",
    "contact reveals settlement identity")

characterUUID = "character:debug-all"
local debugAll = Discovery.HandleAction(player, {
    action = "debug_discover_all", scope = "all",
})
T.equal(debugAll.result.ok, true,
    "debug map can discover every strategic entity")
T.equal(debugAll.result.count, 2,
    "discover-all advances settlement and mobile group together")
T.equal(#debugAll.entities, 2,
    "discover-all returns both entities in one snapshot")
T.equal(debugAll.entities[1].phase, Types.PHASE_LOCATED,
    "debug discovery reveals an exact map location")

Discovery.Registry = {}
Discovery.Loaded = false
Discovery.Load()
T.equal(#Discovery.BuildSnapshot(player).entities, 2,
    "discovery persists across reload")

local reset = Discovery.HandleAction(player, { action = "debug_reset" })
T.equal(reset.result.ok, true,
    "debug modal can reset an accidentally revealed character")
T.equal(#reset.entities, 0,
    "reset restores radio discovery to an empty character map")
PNC.Sandbox = {
    RadioDiscoveryEnabled = function() return false end,
    RadioDiscoveryCooldownHours = function() return 0.5 end,
    RadioDiscoverySignalChance = function() return 100 end,
}
local disabledRadio = Discovery.RadioScan(player,
    PNC.RadioDiscoveryChannel.ID, PNC.RadioDiscoveryChannel.FREQUENCY)
T.equal(disabledRadio.result.reason, "radio_discovery_disabled",
    "sandbox can disable passive radio discovery")
PNC.Sandbox.RadioDiscoveryEnabled = function() return true end
PNC.Sandbox.RadioDiscoverySignalChance = function() return 0 end
local missedSignal = Discovery.RadioScan(player,
    PNC.RadioDiscoveryChannel.ID, PNC.RadioDiscoveryChannel.FREQUENCY)
T.equal(missedSignal.result.reason, "no_signal",
    "sandbox signal chance can suppress a valid candidate")
local throttledMiss = Discovery.RadioScan(player,
    PNC.RadioDiscoveryChannel.ID, PNC.RadioDiscoveryChannel.FREQUENCY)
T.equal(throttledMiss.result.reason, "radio_cooldown",
    "failed signal attempts still receive request pacing")
PNC.Sandbox = nil

local manyGroups = {}
for index = 1, 100 do
    manyGroups[index] = {
        id = "scale_group_" .. tostring(index),
        factionId = "scale_faction",
        groupType = "WANDERER",
        memberIds = {},
        location = { x = 5000 + index, y = 5000, z = 0 },
    }
end
PNC.AbstractGroups.List = function() return manyGroups end
player.x, player.y = 0, 0
Discovery.PROXIMITY_SCAN_BUDGET = 5
Discovery.ProximityStateByPlayer = {}
Discovery.InvalidateWorldEntityCache()
nowMS = 10000
Discovery.UpdateProximity()
T.equal(Discovery.ProximityStateByPlayer[characterUUID].cursor, 6,
    "proximity discovery processes only its fixed per-tick budget")
nowMS = 10050
Discovery.UpdateProximity()
T.equal(Discovery.ProximityStateByPlayer[characterUUID].cursor, 6,
    "proximity slices respect their short continuation throttle")
nowMS = 10100
Discovery.UpdateProximity()
T.equal(Discovery.ProximityStateByPlayer[characterUUID].cursor, 11,
    "large discovery scans resume from their cursor instead of restarting")

local airedBeforeAmbient = #airedBroadcasts
Discovery.RadioAmbientState = {
    lastAiredAt = nil,
    hasAired = false,
    lastVariant = nil,
    sequence = 0,
    lastRequestAtByPlayer = {},
}
Discovery.RadioAmbientRoll = function() return 0 end
nowMS = 20000
local ambient = Discovery.RadioAmbient(player,
    PNC.RadioDiscoveryChannel.ID, PNC.RadioDiscoveryChannel.FREQUENCY)
T.equal(ambient.result.ok, true,
    "ambient radio can air without a discovery target")
T.equal(ambient.result.eventType, "ambient",
    "ambient radio uses a separate event type")
T.equal(ambient.result.radioBroadcast.packID,
    "projecthoomans.ambient_open_band",
    "ambient radio starts with the open-band variant")
T.equal(#airedBroadcasts, airedBeforeAmbient + 1,
    "ambient radio airs one native broadcast")
T.equal(Discovery.BuildSnapshot(player).result, nil,
    "ambient radio does not add a discovery result")

nowMS = 20000
local ambientThrottled = Discovery.RadioAmbient(player,
    PNC.RadioDiscoveryChannel.ID, PNC.RadioDiscoveryChannel.FREQUENCY)
T.equal(ambientThrottled.result.reason, "ambient_request_cooldown",
    "ambient requests are throttled per listener")

nowMS = 110000
Discovery.RadioAmbientRoll = function() return 99 end
local ambientMissed = Discovery.RadioAmbient(player,
    PNC.RadioDiscoveryChannel.ID, PNC.RadioDiscoveryChannel.FREQUENCY)
T.equal(ambientMissed.result.reason, "ambient_missed",
    "ambient chatter is not guaranteed at every eligible trigger")
T.equal(#airedBroadcasts, airedBeforeAmbient + 1,
    "a missed ambient roll does not air a broadcast")

nowMS = 200000
Discovery.RadioAmbientRoll = function() return 0 end
local ambientCrossTalk = Discovery.RadioAmbient(player,
    PNC.RadioDiscoveryChannel.ID, PNC.RadioDiscoveryChannel.FREQUENCY)
T.equal(ambientCrossTalk.result.radioBroadcast.packID,
    "projecthoomans.ambient_cross_talk",
    "ambient selection rotates to the cross-talk variant")
T.equal(airedBroadcasts[#airedBroadcasts].context.hasSecondSpeaker, true,
    "cross-talk ambience carries a separate secondary radio voice")
T.equal(#airedBroadcasts, airedBeforeAmbient + 2,
    "only successful ambient rolls add broadcasts")
T.finish("pnc_world_discovery_smoke")

T.finish("pnc_world_discovery_smoke")
