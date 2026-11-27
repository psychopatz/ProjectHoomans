-- Smoke test for Phase 1 (mobile-only 14d/7d starvation + settlement provision backing)
-- and Phase 2 (actor-agnostic opportunistic WorldLoot with safe-zone bounds, looter theft
-- override, physical removal into unified PNC.Inventory, consumption, and capacity checks).

local T = require "tests/support/test"

T.addPackagePaths()

local worldAgeH = 100.0
local nowMs = 50000

getGameTime = function()
    return { getWorldAgeHours = function() return worldAgeH end }
end

PNC = PNC or {}
PNC.Core = {
    Now = function() return nowMs end,
    NowWorldAgeHours = function() return worldAgeH end,
    IsAuthority = function() return true end,
}
PNC.NeedsUtils = {
    WorldAgeHours = function() return worldAgeH end,
}

-- Load Phase 1 + Phase 2 modules
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Needs/PNC_DeterministicStat.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Needs/PNC_WorldHourNeeds.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Communities/PNC_CommunityMath.lua"))
T.load(T.path("ProjectHoomans", "server", "PNC/Scavenge/PNC_WorldLoot_Policy.lua"))
T.load(T.path("ProjectHoomans", "server", "PNC/Scavenge/PNC_WorldLoot_Scanner.lua"))
T.load(T.path("ProjectHoomans", "server", "PNC/Scavenge/PNC_WorldLoot_Transfer.lua"))
T.load(T.path("ProjectHoomans", "server", "PNC/Scavenge/PNC_Behavior_Loot.lua"))

local WorldNeeds = PNC.WorldHourNeeds
local WorldLoot = PNC.WorldLoot
local BehaviorLoot = PNC.BehaviorLoot

-- Mock communities (NPC settlement at 200,200 radius 25) and player settlement (50,50 radius 20)
local communitySupplies = {
    comm_oak = { food = 15, water = 12 },
}
PNC.Communities = {
    GetSupply = function(cid, cat)
        return communitySupplies[cid] and communitySupplies[cid][cat] or 0
    end,
    List = function()
        return {
            comm_oak = { id = "comm_oak", home = { x = 200, y = 200, z = 0, radius = 25 } },
        }
    end,
}
PNC.SettlementRepository = {
    List = function()
        return {
            base_player = { id = "base_player", x = 50, y = 50, z = 0, radius = 20 },
        }
    end,
}

-- 1. Settlement NPC never starves while colony has provision points
local settler = {
    id = "settler_1", alive = true, communityID = "comm_oak",
    pseudoNeeds = { fedH = 0, drankH = 0 },
}
local sSurv = WorldNeeds.EvaluateSurvival(settler, 600)
T.equal(sSurv.alive, true, "settlement NPC stays alive while colony has supplies")
T.equal(sSurv.backedBy, "settlement", "settlement NPC is backed by settlement")
T.equal(settler.alive, true, "settlement NPC record remains alive")

-- 2. Mobile group draws from compact group.resources before starving
local mobileGroup = {
    id = "grp_nomads",
    memberIds = { "nomad_1" },
    resources = { food = 1, water = 1 },
}
local nomad = {
    id = "nomad_1", alive = true, groupId = "grp_nomads",
    pseudoNeeds = { fedH = 100, drankH = 100 },
}
PNC.AbstractGroups = {
    Get = function(gid) return gid == "grp_nomads" and mobileGroup or nil end,
}
PNC.Registry = {
    Get = function(id) return id == "nomad_1" and nomad or nil end,
    MarkDirty = function() end,
}

-- After 30h, nomad draws 1 food + 1 water from mobileGroup.resources
local mSurv1 = WorldNeeds.EvaluateSurvival(nomad, 130)
T.equal(mSurv1.alive, true, "mobile NPC survives by drawing group provisions")
T.equal(mobileGroup.resources.food, 0, "group food provision point decremented")
T.equal(mobileGroup.resources.water, 0, "group water provision point decremented")

-- 3. Mobile group with 0 provisions dies of dehydration at 7 days (168h)
local mSurvDehyd = WorldNeeds.EvaluateSurvival(nomad, 130 + 180)
T.equal(mSurvDehyd.alive, false, "mobile NPC with empty provisions dies after 7d without water")
T.equal(mSurvDehyd.cause, "dehydration", "death cause is dehydration")
T.equal(nomad.alive, false, "mobile NPC record marked dead on dehydration")

-- 4. Mobile NPC with water but 0 food dies of starvation at 14 days (336h)
local starver = {
    id = "nomad_2", alive = true,
    pseudoNeeds = { fedH = 100, drankH = 440 },
}
local mSurvStarve = WorldNeeds.EvaluateSurvival(starver, 440)
T.equal(mSurvStarve.alive, false, "mobile NPC with 0 food dies after 14d")
T.equal(mSurvStarve.cause, "starvation", "death cause is starvation")

-- 5. Safe-zone protection: player settlement & NPC settlement block normal followers & AI,
--    but looter variant override is allowed to steal!
local follower = {
    id = "fol_1", alive = true, recruited = true, opportunisticLootEnabled = true,
    x = 52, y = 52, z = 0,
}
local aiScav = {
    id = "scav_1", alive = true, x = 205, y = 205, z = 0,
}
local looter = {
    id = "raider_1", alive = true, lootVariant = "looter", x = 52, y = 52, z = 0,
}

local okFolPlayer, zKind1 = WorldLoot.CanLootAt(follower, 52, 52, 0)
T.equal(okFolPlayer, false, "follower cannot loot inside own player settlement safe zone")
T.equal(zKind1, "own_settlement", "zoneKind identifies own_settlement for player follower in player colony")

local okAiNpc, zKind2 = WorldLoot.CanLootAt(aiScav, 205, 205, 0)
T.equal(okAiNpc, false, "AI scavenger cannot loot inside NPC settlement safe zone")
T.equal(zKind2, "npc_settlement", "zoneKind identifies npc_settlement")

local okLooter = WorldLoot.CanLootAt(looter, 52, 52, 0)
T.equal(okLooter, true, "looter variant override allows stealing inside protected safe zones")

local okWild = WorldLoot.CanLootAt(follower, 500, 500, 0)
T.equal(okWild, true, "looting outside safe zones is allowed")

-- Smart stealing guard: even with allowProtectedZoneTheft=true, a follower can steal
-- from a rival NPC settlement but NEVER from their own player colony!
local stealPolicy = { enabled = true, allowProtectedZoneTheft = true }
local okStealOwn, ownReason = WorldLoot.CanLootAt(follower, 52, 52, 0, stealPolicy)
T.equal(okStealOwn, false, "follower with allowStealing=ON must NEVER steal from own player colony")
T.equal(ownReason, "own_settlement", "own-colony block reports own_settlement")
local okStealRival = WorldLoot.CanLootAt(follower, 205, 205, 0, stealPolicy)
T.equal(okStealRival, true, "follower with allowStealing=ON CAN steal from rival NPC settlement")

-- 6. End-to-end physical removal -> unified PNC.Inventory -> eating consumes the item!
WorldLoot.ResetScannerRuntime()
local mockItem = {
    fullType = "Base.TinnedBeans",
    category = "food",
    weight = 0.8,
    calories = 350,
    hungerChange = -0.35,
}
local mockContainer = {
    _items = { mockItem },
    getItems = function(self) return self._items end,
}
local mockSquare = {
    _objects = { { container = mockContainer } },
    getObjects = function(self) return self._objects end,
    getWorldObjects = function() return {} end,
    getDeadBodys = function() return {} end,
}
local mockCell = {
    getGridSquare = function(_, sx, sy, sz)
        if sx == 501 and sy == 500 and sz == 0 then return mockSquare end
        return nil
    end,
}

local wildScav = {
    id = "wild_scav", alive = true, x = 500, y = 500, z = 0,
    pseudoNeeds = { fedH = 100, drankH = 100 }, -- not hungry yet so item stays in bag
    equipment = { back = { capacity = 12 } },
}
local active, status, collected = BehaviorLoot.Tick(wildScav, nowMs, {
    cell = mockCell,
    bypassCooldown = true,
    bypassBudget = true,
})
T.equal(active, true, "BehaviorLoot collects nearby item within pickup range")
T.equal(status, "collected", "status is collected")
T.equal(#mockContainer._items, 0, "physical item was removed from the world container")
T.truthy(collected and wildScav.inventory and wildScav.inventory.items[collected.id] ~= nil,
    "looted item was inserted into unified PNC.Inventory (ready for corpse drop or eating)")

-- Now advance time so wildScav becomes hungry and enacts eating -> item is consumed!
worldAgeH = 120.0
local beforeEat = WorldNeeds.GetPseudoNeed(wildScav, "hunger", worldAgeH)
local ateOk, ateType = WorldNeeds.ConsumePersonalSustenance(wildScav, "hunger", worldAgeH)
T.equal(ateOk, true, "NPC consumes looted food from unified PNC.Inventory")
T.equal(ateType, "Base.TinnedBeans", "consumed item matches looted food")
T.equal(wildScav.inventory.items[collected.id], nil, "consumed item is removed from PNC.Inventory")
local afterEat = WorldNeeds.GetPseudoNeed(wildScav, "hunger", worldAgeH)
T.truthy(afterEat < beforeEat, "consuming looted food reduces world-hour hunger")

-- 7. Capacity check: full backpack prevents further looting
local fullNpc = {
    id = "full_npc", alive = true, x = 500, y = 500, z = 0,
    inventory = {
        rootMaxWeight = 2.0,
        items = {
            heavy1 = { id = "heavy1", fullType = "Base.Log", weight = 2.0 },
        },
    },
}
T.equal(WorldLoot.GetRemainingCapacity(fullNpc), 0, "full NPC reports 0 remaining capacity")

-- 8. CompactGroupLootOnAbstract folds excess looted food into group provisions
local compGroup = { id = "g_comp", memberIds = { "wild_scav" }, resources = { food = 0, water = 0 } }
wildScav.inventory.items = {
    f1 = { id = "f1", fullType = "Base.Apple", category = "food", looted = true },
    f2 = { id = "f2", fullType = "Base.Apple", category = "food", looted = true },
    f3 = { id = "f3", fullType = "Base.Apple", category = "food", looted = true },
}
local foldedFood = WorldLoot.CompactGroupLootOnAbstract(wildScav, compGroup, 1)
T.equal(foldedFood, 2, "excess looted food descriptors fold into group provisions")
T.equal(compGroup.resources.food, 2, "group.resources.food receives folded provision points")

-- 9. Safe-zone theft witness alert, pickup cue, ConvoDSL reload & ActorReference pronouns
local ConvoDSL = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL"
local Catalog = require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
local diag = ConvoDSL.Reload("EN")
T.equal(#(diag.errors or {}), 0,
    "EN ConvoBlocks including world_loot.convo must load with zero errors: " .. table.concat(diag.errors or {}, "; "))
local lootPool = Catalog.Get("semantic.social.world_loot")
T.truthy(lootPool and type(lootPool.variants) == "table" and #lootPool.variants >= 16,
    "semantic.social.world_loot pool must contain pickup, pack_full, sustenance, and theft lines")

local theftEvents = {}
local perfCues = {}
local emittedDialogueBeats = {}
PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Events = {
    emit = function(ev, p) theftEvents[#theftEvents + 1] = { event = ev, payload = p } end,
}
PNC.Semantics = {
    SpeechPerformance = {
        Perform = function(rec, spec) perfCues[#perfCues + 1] = { id = rec.id, anim = spec.anim } end,
    },
    DialogueBeats = {
        RegisterHook = function() end,
        Emit = function(ev, payload)
            emittedDialogueBeats[#emittedDialogueBeats + 1] = { eventName = ev, payload = payload }
            return true
        end,
    },
}
T.load(T.path("ProjectHoomans", "shared", "PNC/Semantics/PNC_ActorReference.lua"))
T.load(T.path("ProjectHoomans", "server", "PNC/Semantics/Beats/PNC_SemanticBeats_WorldLoot.lua"))

looter.name = "Vex Morgan"
looter.isFemale = true
local guardColonist = {
    id = "guard_1", name = "Marcus", alive = true, recruited = true, x = 54, y = 52, z = 0,
}
PNC.Registry.ForEach = function(fn) fn(guardColonist) end
local stolenItem = { fullType = "Base.WaterBottleFull", category = "water", weight = 0.7 }
local baseContainer = { _items = { stolenItem }, getItems = function(self) return self._items end }
local okSteal = WorldLoot.CollectTarget(looter, {
    kind = "container", x = 52, y = 52, z = 0,
    item = stolenItem, container = baseContainer,
    fullType = stolenItem.fullType, category = "water", weight = 0.7,
    targetKey = "cont:52:52:0:1:1",
}, nowMs)
T.equal(okSteal, true, "looter steals item from inside player settlement")
T.equal(#theftEvents, 1, "safe-zone theft emits WORLD_LOOT_PROTECTED_THEFT event")
T.equal(theftEvents[1].event, "WORLD_LOOT_PROTECTED_THEFT", "theft event name matches")
T.equal(guardColonist.runtime and guardColonist.runtime.theftAlertTargetId, "raider_1",
    "nearby settlement guard witnesses theft and flags thief")
T.truthy(#perfCues >= 1 and perfCues[#perfCues].anim == "PNC_Anim_Loot",
    "pickup triggers PNC_Anim_Loot performance cue")
T.truthy(#emittedDialogueBeats >= 1 and emittedDialogueBeats[1].eventName == "ambient.world_loot_theft",
    "safe-zone theft emits semantic ambient.world_loot_theft beat")
local theftTokens = emittedDialogueBeats[1].payload.tokens
T.equal(theftTokens["addressee.name"], "thief", "unknown looter does not bleed proper name")
T.equal(theftTokens["thief.subj"], "she", "ActorReference resolves female subject pronoun")
T.equal(theftTokens["thief.obj"], "her", "ActorReference resolves female object pronoun")
T.equal(theftTokens["thief.poss"], "her", "ActorReference resolves female possessive pronoun")
T.equal(theftTokens["slot.item"], "water bottle full", "item name is humanized for dialogue")

-- 10. MarketSense-aware "just found" variants (treat, high-value jackpot, quality, container source)
local Beats = PNC.Semantics.DialogueBeats
local iceCtx = Beats.DescribeLootContext(
    { fullType = "Base.Icecream", displayName = "Ice Cream", category = "food", price = 18 },
    { fullType = "Base.Icecream", category = "food" },
    { kind = "container", container = { type = "freezer" } }
)
T.equal(iceCtx.role, "loot_found_treat", "ice cream selects excited treat discovery role")
T.equal(iceCtx.tokens["slot.item"], "ice cream", "display name preserved for treat")
T.equal(iceCtx.tokens["slot.source"], "in the freezer", "container type maps to natural source phrase")

local jackpotCtx = Beats.DescribeLootContext(
    { fullType = "Base.Katana", displayName = "Katana", category = "weapons", price = 250, condition = 0.95 },
    { fullType = "Base.Katana", category = "weapons" },
    { kind = "container", container = { type = "shelves" } }
)
T.equal(jackpotCtx.role, "loot_found_jackpot", "MarketSense high price selects jackpot discovery role")
T.equal(jackpotCtx.tokens["slot.source"], "on the shelf", "shelves map to 'on the shelf'")

local wornCtx = Beats.DescribeLootContext(
    { fullType = "Base.BaseballBat", displayName = "Baseball Bat", category = "weapons", price = 25, condition = 0.20 },
    { fullType = "Base.BaseballBat", category = "weapons" },
    { kind = "floor" }
)
T.equal(wornCtx.role, "loot_found_worn", "low-condition weapon selects worn discovery role")
T.equal(wornCtx.tokens["slot.source"], "on the floor", "floor target maps to 'on the floor'")

-- 11. Unseen looter stealing inside protected safe zone emits ambient.world_loot_steal_solo
PNC.Registry.ForEach = function() end -- no witnesses nearby
local soloBefore = #emittedDialogueBeats
local soloItem = { fullType = "Base.CannedCorn", displayName = "Canned Corn", category = "food", price = 20, weight = 0.6 }
local soloCont = { _items = { soloItem }, type = "shelves", getItems = function(self) return self._items end }
local okSoloSteal = WorldLoot.CollectTarget(looter, {
    kind = "container", x = 52, y = 52, z = 0,
    item = soloItem, container = soloCont,
    fullType = soloItem.fullType, category = "food", weight = 0.6,
    targetKey = "cont:52:52:0:2:1",
}, nowMs)
T.equal(okSoloSteal, true, "unseen looter steals inside player settlement")
T.equal(emittedDialogueBeats[soloBefore + 1].eventName, "ambient.world_loot_steal_solo",
    "unseen safe-zone theft emits ambient.world_loot_steal_solo")
T.equal(emittedDialogueBeats[soloBefore + 1].payload.openRole, "loot_steal_sneaky",
    "normal-value unseen theft uses loot_steal_sneaky role")

T.finish("pnc_world_loot_and_survival_smoke")
