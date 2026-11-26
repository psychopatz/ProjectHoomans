local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "common_lua" },
    { "PsychopatzCore", "common" },
})

PNC = { Core = { Now = function() return 100000 end, NowWorldAgeHours = function() return 24 end } }

-- 1. Parse & verify all 5 new ConvoDSL packs + trait-conditioned replies
local Catalog = require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
local ConvoDSL = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL"
local files = {
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/branches/story_looter_toll.convo",
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/world/world_looter_toll.convo",
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/world/world_surrender_ceasefire.convo",
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/branches/story_surrender_mercy.convo",
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/world/world_combat_flee.convo",
}
for _, path in ipairs(files) do
    local fh = assert(io.open(path, "r"), "convo file exists: " .. path)
    local text = fh:read("*a")
    fh:close()
    local script, err = ConvoDSL.ParseText(text, path, "EN")
    T.equal(err, nil, "parse clean: " .. path)
    ConvoDSL.ApplyScripts({ script }, "EN")
end

T.truthy(ConvoDSL.GetStory("convo.faction.looter_toll") ~= nil, "story_looter_toll compiled")
T.truthy(ConvoDSL.GetStory("convo.combat.surrender_mercy") ~= nil, "story_surrender_mercy compiled")

local braveReply = Catalog.Select("semantic.world.toll.demand",
    { npcID = "n1", combatReactionRole = "toll_refused_reply", speakerStyle = "brave" }, "s1")
local defReply = Catalog.Select("semantic.world.toll.demand",
    { npcID = "n1", combatReactionRole = "toll_refused_reply", speakerStyle = "neutral" }, "s1")
T.truthy(braveReply and defReply and braveReply.id ~= defReply.id,
    "brave target uses distinct trait-conditioned toll reply")

-- 2. Verify MarketSense toll item valuation + unified headless conversation parser
require "PNC/Factions/FactionTollService/PNC_FactionTollService_Money"
local H = PNC.FactionTollServiceInternal
local mockItems = {
    {
        getFullType = function() return "Base.Jacket_Leather" end,
        getDisplayName = function() return "Leather Jacket" end,
        getActualWeight = function() return 2.0 end,
    },
}
local mockActor = {
    getInventory = function()
        return {
            getItemsFromType = function() return { size = function() return 0 end } end,
            getItems = function()
                return { size = function() return #mockItems end, get = function(_, i) return mockItems[i + 1] end }
            end,
        }
    end,
}
local mockMS = {
    GetPriceDetails = function(ft)
        if ft == "Base.Jacket_Leather" then return { finalPrice = 65 } end
        return nil
    end,
}
local tribute = H.InspectTargetTribute(mockActor, 20, { marketSense = mockMS })
T.equal(tribute.mode, "item_only", "cash-poor target gets dynamic item demand")
T.equal(tribute.itemName, "Leather Jacket", "MarketSense selects valuable Leather Jacket")

local TollConvo = require "PNC/Conversation/PNC_FactionTollConversation"
T.equal(TollConvo.ParseFreeTextDecision("fine, take it"), "pay", "free text parses pay")
T.equal(TollConvo.ParseFreeTextDecision("I'm backing out"), "leave", "free text parses leave")
T.equal(TollConvo.ParseFreeTextDecision("come take it yourself"), "refuse", "free text parses refuse")

-- 3. Verify CeasefireService (human-only, 80% one-shot, revocation, AI mercy vs no_mercy)
local Ceasefire = require "PNC/Social/PNC_CeasefireService"
local Flee = require "PNC/Core/Behaviors/PNC_Behavior_Flee"
local Emotes = require "PNC/Core/Commands/PNC_VanillaEmoteInteractions"
T.truthy(Emotes.Get("surrender") ~= nil, "surrender registered in VanillaEmoteInteractions")

Ceasefire.ResetRuntime()
local playerRef = { isPlayer = true, key = "player:1", id = "player:1", x = 100, y = 100 }
local zombieHostile = { id = "z1", kind = "zombie", isZombie = true, alive = true }
local okZ, reasonZ = Ceasefire.AttemptSurrender(playerRef, { zombieHostile }, { roll = 0.1 })
T.equal(okZ, false, "zombies never accept surrender")
T.equal(reasonZ, "no_human_opponents", "zombie excluded cleanly")

local looter = { id = "looter_1", factionID = "fac_gang", alive = true, x = 105, y = 100, runtime = { target = playerRef } }
local ok1, r1 = Ceasefire.AttemptSurrender(playerRef, { looter }, { roll = 0.75 })
T.equal(ok1, true, "80% roll (0.75) accepts ceasefire")
T.equal(r1, "ceasefire_accepted", "ceasefire accepted")
local ok2, r2 = Ceasefire.AttemptSurrender(playerRef, { looter }, { roll = 0.10 })
T.equal(ok2, false, "second surrender in same conflict is blocked")
T.equal(r2, "ceasefire_already_used", "one-shot enforced")

Ceasefire.RevokeCeasefire("player:1", "fac_bandit", "toll_refused")
local bandit = { id = "bandit_1", factionID = "fac_bandit", alive = true, x = 110, y = 100 }
local okRev, rRev = Ceasefire.AttemptSurrender(playerRef, { bandit }, { roll = 0.01 })
T.equal(okRev, false, "provoked faction refuses ceasefire even on 0.01 roll")
T.equal(rRev, "ceasefire_revoked", "revocation enforced")

-- AI last-man-standing surrenders to player -> pending_player_mercy -> no_mercy turns hostile again
local lastLooter = { id = "looter_last", alive = true, x = 108, y = 100, runtime = {} }
local okLms, rLms, meta = Ceasefire.CheckLastManStandingSurrender(lastLooter, 1, { playerRef })
T.equal(okLms, true, "last-man-standing AI surrenders to player")
T.equal(rLms, "pending_player_mercy", "opens player mercy choice")
T.equal(meta.storyID, "convo.combat.surrender_mercy", "uses surrender_mercy story")
local okNM, rNM = Ceasefire.ResolveMercyDecision(lastLooter, playerRef, "no_mercy")
T.equal(okNM, false, "no_mercy rejects surrender")
T.equal(rNM, "no_mercy_hostile_resumed", "no_mercy resumes hostility")
T.equal(lastLooter.isHostile, true, "NPC turned hostile again")

-- Spared NPC enters BehaviorFlee -> steps to safe distance -> triggers far-migration
local sparedLooter = { id = "looter_spared", alive = true, x = 105, y = 100, runtime = {} }
local okSp, rSp = Ceasefire.ResolveMercyDecision(sparedLooter, playerRef, "spare")
T.equal(okSp, true, "spare accepted")
T.equal(rSp, "spared_and_fleeing", "spared NPC starts fleeing")
T.equal(sparedLooter.activeBehavior, "flee", "activeBehavior switched to flee")

-- 4. Verify strengthened AbstractTraversal.ChooseFarMigrationDestination synthetic waypoint fallback
PNC.HoomansWorldView = { WorldAgeHours = function() return 24 end, Emit = function() end }
PNC.AbstractGroups = { Get = function() return nil end }
PNC.AbstractLocations = { GetNearby = function() return {} end }
PNC.AbstractTraversal = { Internal = {} }
require "PNC/Director/AbstractTraversal/PNC_AbstractTraversal_Destinations"
local group = { id = "grp_looters", location = { id = "loc_1", x = 8000, y = 11500, z = 0 }, visited = {} }
local farDest, farReason = PNC.AbstractTraversal.ChooseFarMigrationDestination(group, 8000, 11500, { minDistance = 400, maxDistance = 900 })
T.truthy(farDest ~= nil, "far migration destination always resolves even with empty location list")
T.equal(farReason, "far_waypoint_synthesized", "synthesizes bounded far waypoint")
local dx, dy = farDest.x - 8000, farDest.y - 11500
T.truthy(math.sqrt(dx * dx + dy * dy) >= 350, "synthesized waypoint is genuinely far from threat")

print("pnc_toll_surrender_flee_migration_smoke: ok")
