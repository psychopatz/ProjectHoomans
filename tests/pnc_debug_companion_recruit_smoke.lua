local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/")

local records = {
    hostile = { id = "hostile", faction = "hostile", alive = true },
    neutral = { id = "neutral", faction = "neutral", alive = true },
    companion = { id = "companion", faction = "colonist", recruited = true },
    stale = {
        id = "stale",
        faction = "colonist",
        recruited = true,
        alive = true,
    },
    orphaned = {
        id = "orphaned", faction = "colonist", recruited = true,
        alive = true, ownerUsername = "Tester",
        orderSpec = { kind = "guard" },
    },
}
local affiliations = {
    hostile = { factionID = "raiders" },
    stale = { factionID = "player-faction" },
}
local transferCalls = 0
local addCalls = 0
local needsCalls = 0
local endedCalls = 0
local orderCalls = 0
local communityCreates = 0
local communityAdds = 0
local registrySaves = 0
local factionSaves = 0
local communitySaves = 0
local playerCommunities = {}
local communityByNPC = {}

PNC = {
    Const = {
        FACTION_NEUTRAL = "neutral",
        FACTION_HOSTILE = "hostile",
        FACTION_COLONIST = "colonist",
        ORDER_FOLLOW = "follow",
    },
    Core = { LogInfo = function() end },
    Types = {
        NormalizeFaction = function(value) return tostring(value or "") end,
    },
    Registry = {
        Get = function(id) return records[id] end,
        GetLiveZombie = function() return nil end,
        MarkDirty = function() end,
        Save = function() registrySaves = registrySaves + 1 end,
    },
    Factions = {
        EnsurePlayerFaction = function()
            return true, "existing", { id = "player-faction" }
        end,
        GetNPCAffiliation = function(id) return affiliations[id] end,
        GetPlayerFaction = function() return { id = "player-faction" } end,
        GetNPCFaction = function(id)
            return affiliations[id]
                and { id = affiliations[id].factionID } or nil
        end,
        TransferNPC = function(id, factionID)
            transferCalls = transferCalls + 1
            records[id].faction = "colonist"
            records[id].recruited = true
            affiliations[id] = { factionID = factionID }
            return true, "transferred"
        end,
        AddNPC = function(factionID, id)
            addCalls = addCalls + 1
            records[id].faction = "colonist"
            records[id].recruited = true
            affiliations[id] = { factionID = factionID }
            return true, "added"
        end,
        Save = function() factionSaves = factionSaves + 1 end,
    },
    IndividualNeeds = {
        Ensure = function() needsCalls = needsCalls + 1 end,
    },
    OrderSystem = {
        SetOrder = function(record, order)
            orderCalls = orderCalls + 1
            record.orderSpec = order
        end,
    },
    Communities = {
        GetForFaction = function() return playerCommunities end,
        Create = function()
            communityCreates = communityCreates + 1
            local community = {
                id = "community_player",
                factionID = "player-faction",
                status = "active",
                renamePending = true,
            }
            playerCommunities[#playerCommunities + 1] = community
            return true, "created", community
        end,
        AddNPC = function(_, npcID)
            communityAdds = communityAdds + 1
            communityByNPC[npcID] = playerCommunities[1]
            return true, "added"
        end,
        GetNPCCommunity = function(npcID)
            return communityByNPC[npcID]
        end,
        Save = function() communitySaves = communitySaves + 1 end,
    },
    ConversationScene = {
        End = function() endedCalls = endedCalls + 1 end,
    },
    CompanionCommands = {
        IsOwnedByPlayer = function(record, owner)
            return record.recruited == true
                and record.ownerUsername == owner:getUsername()
        end,
    },
}

local Recruit = T.load(ROOT .. "PNC_DebugCompanionRecruit.lua")
local player = { getUsername = function() return "Tester" end }

T.equal(Recruit.IsEligible(records.hostile), true, "hostile eligible")
T.equal(Recruit.IsEligible(records.neutral), true, "neutral eligible")
T.equal(Recruit.IsEligible(records.companion), false, "companion not eligible")

local ok, reason = Recruit.Try(player, { npcID = "hostile" })
T.equal(ok, true, "hostile recruit succeeds")
T.equal(reason, "recruited", "hostile recruit result")
T.equal(transferCalls, 1, "hostile uses canonical transfer")
T.equal(records.hostile.recruited, true, "hostile becomes companion")
T.equal(records.hostile.orderSpec.kind, "follow", "hostile follows recruiter")

ok, reason = Recruit.Try(player, { npcID = "neutral" })
T.equal(ok, true, "neutral recruit succeeds")
T.equal(addCalls, 1, "unaffiliated neutral uses canonical add")
T.equal(records.neutral.recruited, true, "neutral becomes companion")
T.equal(needsCalls, 2, "companion needs initialized")
T.equal(endedCalls, 2, "conversation lease ended after recruitment")
T.equal(orderCalls, 2, "every recruit receives a follow order")
T.equal(communityCreates, 1, "first companion creates a player community")
T.equal(communityAdds, 2, "recruits populate the player community")
T.equal(registrySaves, 2, "each recruit commits its NPC record")
T.equal(factionSaves, 2, "each recruit commits faction membership")
T.equal(communitySaves, 2, "each recruit commits community membership")

ok, reason = Recruit.Try(player, { npcID = "companion" })
T.equal(ok, false, "existing companion rejected")
T.equal(reason, "npc_not_debug_recruitable", "existing companion reason")

ok, reason = Recruit.Assign(player, records.stale, {
    source = "starting_companion_repair",
    endConversation = false,
})
T.equal(ok, true, "existing faction member can repair enrollment")
T.equal(reason, "recruited", "existing membership repair result")
T.equal(transferCalls, 1,
    "same-faction repair does not attempt an invalid transfer")
T.equal(addCalls, 2,
    "same-faction repair uses idempotent faction add")

local ordersBeforeRepair = orderCalls
ok, reason = Recruit.ReconcileOwned(player, records.orphaned)
T.equal(ok, true, "owned orphan membership repaired")
T.equal(reason, "recruited", "owned orphan repair result")
T.equal(affiliations.orphaned.factionID, "player-faction",
    "owned orphan joined player faction")
T.equal(records.orphaned.orderSpec.kind, "guard",
    "membership repair preserves current companion order")
T.equal(orderCalls, ordersBeforeRepair,
    "membership repair did not force follow")

records.canonical = {
    id = "canonical", faction = "colonist", recruited = true,
    alive = true, ownerUsername = "Tester",
}
affiliations.canonical = { factionID = "player-faction" }
communityByNPC.canonical = playerCommunities[1]
ok, reason = Recruit.ReconcileOwned(player, records.canonical)
T.equal(ok, true, "canonical membership remains valid")
T.equal(reason, "unchanged", "canonical membership is not rebuilt")
T.equal(records.canonical.affiliation.communityID, "community_player",
    "canonical community is mirrored onto the NPC record")
T.equal(records.canonical.communityId, "community_player",
    "legacy scheduler community field is repaired")
T.finish("pnc_debug_companion_recruit_smoke")

T.finish("pnc_debug_companion_recruit_smoke")
