local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local records = {
    hostile = { id = "hostile", faction = "hostile", alive = true },
    neutral = { id = "neutral", faction = "neutral", alive = true },
    companion = { id = "companion", faction = "colonist", recruited = true },
}
local affiliations = {
    hostile = { factionID = "raiders" },
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
                status = "active",
                renamePending = true,
            }
            playerCommunities[#playerCommunities + 1] = community
            return true, "created", community
        end,
        AddNPC = function()
            communityAdds = communityAdds + 1
            return true, "added"
        end,
        Save = function() communitySaves = communitySaves + 1 end,
    },
    ConversationScene = {
        End = function() endedCalls = endedCalls + 1 end,
    },
}

local Recruit = dofile(ROOT .. "PNC_DebugCompanionRecruit.lua")
local player = { getUsername = function() return "Tester" end }

assertEqual(Recruit.IsEligible(records.hostile), true, "hostile eligible")
assertEqual(Recruit.IsEligible(records.neutral), true, "neutral eligible")
assertEqual(Recruit.IsEligible(records.companion), false, "companion not eligible")

local ok, reason = Recruit.Try(player, { npcID = "hostile" })
assertEqual(ok, true, "hostile recruit succeeds")
assertEqual(reason, "recruited", "hostile recruit result")
assertEqual(transferCalls, 1, "hostile uses canonical transfer")
assertEqual(records.hostile.recruited, true, "hostile becomes companion")
assertEqual(records.hostile.orderSpec.kind, "follow", "hostile follows recruiter")

ok, reason = Recruit.Try(player, { npcID = "neutral" })
assertEqual(ok, true, "neutral recruit succeeds")
assertEqual(addCalls, 1, "unaffiliated neutral uses canonical add")
assertEqual(records.neutral.recruited, true, "neutral becomes companion")
assertEqual(needsCalls, 2, "companion needs initialized")
assertEqual(endedCalls, 2, "conversation lease ended after recruitment")
assertEqual(orderCalls, 2, "every recruit receives a follow order")
assertEqual(communityCreates, 1, "first companion creates a player community")
assertEqual(communityAdds, 2, "recruits populate the player community")
assertEqual(registrySaves, 2, "each recruit commits its NPC record")
assertEqual(factionSaves, 2, "each recruit commits faction membership")
assertEqual(communitySaves, 2, "each recruit commits community membership")

ok, reason = Recruit.Try(player, { npcID = "companion" })
assertEqual(ok, false, "existing companion rejected")
assertEqual(reason, "npc_not_debug_recruitable", "existing companion reason")

print("pnc_debug_companion_recruit_smoke: ok")
