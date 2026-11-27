-- Dynamic Group Item Sharing smoke test:
-- Verifies need-driven teammate sharing, relationship/trait/kinship willingness,
-- canonical inventory transfer, AnimationScenes + ActionProps hand visuals,
-- kinship terms of address (Father -> "son"/"sweetheart", Child -> "Dad"),
-- multi-turn convo beats, and bidirectional relationship improvement.
package.path = "./tests/?.lua;./tests/?/init.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/server/?.lua;" .. package.path

local T = require "support.test"

local simNow = 100000
local spoken = {}
local scenesPlayed = {}
local relEffects = {}
local removedItems = {}
local addedItems = {}

local father = {
    id = "npc_father", name = "Rick", alive = true, presenceState = "live",
    isFemale = false, factionId = "fam_1",
    x = 10, y = 10, z = 0,
    needs = { hunger = 0.1, thirst = 0.1, fatigue = 0.1 },
    inventory = {
        items = {
            { id = "item_beans_1", fullType = "Base.CannedBeans", displayName = "Canned Beans", isFood = true },
        },
    },
    social = {
        personality = { compassion = 0.85, materialism = 0.2, loyalty = 0.9 },
        relationships = {
            ["npc:npc_son"] = { approval = 80, respect = 60, state = "family", bond = { kind = "child" } },
            ["npc:npc_daughter"] = { approval = 85, respect = 60, state = "family", bond = { kind = "daughter" } },
            ["npc:npc_rival"] = { approval = -50, respect = -30, state = "rival" },
        },
    },
    runtime = {},
}

local son = {
    id = "npc_son", name = "Carl", alive = true, presenceState = "live",
    isFemale = false, factionId = "fam_1",
    x = 12, y = 10, z = 0,
    needs = { hunger = 0.92, thirst = 0.1, fatigue = 0.1 },
    health = { state = "injured", body = { wholeBodyAilments = { starvation = { severity = 0.8 } } } },
    inventory = { items = {} },
    social = {
        relationships = {
            ["npc:npc_father"] = { approval = 85, respect = 80, state = "family", bond = { kind = "father" } },
        },
    },
    runtime = {},
}

local daughter = {
    id = "npc_daughter", name = "Judith", alive = true, presenceState = "live",
    isFemale = true, factionId = "fam_1",
    x = 13, y = 10, z = 0,
    needs = { hunger = 0.1, thirst = 0.1, fatigue = 0.1 },
    inventory = { items = {} },
    social = {
        relationships = {
            ["npc:npc_father"] = { approval = 90, respect = 85, state = "family", bond = { kind = "father" } },
        },
    },
    runtime = {},
}

local rival = {
    id = "npc_rival", name = "Shane", alive = true, presenceState = "live",
    isFemale = false, factionId = "fam_1",
    x = 14, y = 10, z = 0,
    needs = { hunger = 0.95, thirst = 0.1, fatigue = 0.1 },
    inventory = { items = {} },
    runtime = {},
}

local selfishPeer = {
    id = "npc_selfish", name = "Merle", alive = true, presenceState = "live",
    isFemale = false, factionId = "fam_1",
    social = { personality = { compassion = 0.1, materialism = 0.9, loyalty = 0.2 } },
    traits = { Selfish = true },
    needs = { hunger = 0.2 },
    runtime = {},
}

local generousPeer = {
    id = "npc_generous", name = "Glenn", alive = true, presenceState = "live",
    isFemale = false, factionId = "fam_1",
    social = { personality = { compassion = 0.9, materialism = 0.1, loyalty = 0.8 } },
    traits = { Generous = true },
    needs = { hunger = 0.2 },
    runtime = {},
}

local allRecords = { father, son, daughter, rival }

_G.PNC = {
    Core = {
        Now = function() return simNow end,
        NowWorldAgeHours = function() return 24.0 end,
    },
    Const = { PRESENCE_LIVE = "live" },
    Registry = {
        Get = function(id)
            for _, r in ipairs(allRecords) do
                if tostring(r.id) == tostring(id) then return r end
            end
            return nil
        end,
        GetLiveZombie = function(id) return { id = id } end,
        ForEach = function(fn)
            for _, r in ipairs(allRecords) do fn(r) end
        end,
    },
    Inventory = {
        EnsureRecordInventory = function(rec) return rec.inventory end,
        RemoveItems = function(rec, ids)
            removedItems[#removedItems + 1] = { recId = rec.id, ids = ids }
            for i = #rec.inventory.items, 1, -1 do
                if rec.inventory.items[i].id == ids[1] then
                    table.remove(rec.inventory.items, i)
                end
            end
            return true
        end,
        AddItemsAndSync = function(rec, _, specs)
            addedItems[#addedItems + 1] = { recId = rec.id, fullType = specs[1].fullType }
            rec.inventory.items[#rec.inventory.items + 1] = specs[1]
            return true
        end,
    },
    AnimationScenes = {
        Request = function(rec, _, sceneId, opts)
            scenesPlayed[#scenesPlayed + 1] = {
                recId = rec.id,
                sceneId = sceneId,
                propPrimary = opts and opts.propPrimary or (rec.runtime and rec.runtime.sceneActionProps and rec.runtime.sceneActionProps.primary),
            }
            return true
        end,
    },
    Relationships = {
        ApplyConversationEffect = function(actorId, targetKey, eff)
            relEffects[#relEffects + 1] = {
                actorId = actorId,
                targetKey = targetKey,
                approval = eff.approval,
                respect = eff.respect,
                memoryType = eff.memoryType,
            }
            return true
        end,
    },
    Semantics = {
        DialogueBeats = {},
        ConversationDirector = {
            RegisterTopicAxis = function() return true end,
        },
        SpeechTransport = {
            ResolveLine = function(speaker, spec)
                return tostring(speaker.id) .. ":" .. tostring(spec.role)
                    .. ":addr=" .. tostring(spec.tokens["addressee.name"])
                    .. ":giver=" .. tostring(spec.tokens["slot.giver_address"])
                    .. ":item=" .. tostring(spec.tokens["slot.item"]),
                    { poolID = spec.poolID }
            end,
            Deliver = function(_, _, opts)
                spoken[#spoken + 1] = opts.text
                return 1
            end,
        },
    },
}

require "PNC/Semantics/Beats/PNC_SemanticBeats_GroupItemShare"
local Beats = PNC.Semantics.DialogueBeats

-- 1) Kinship pronoun & term-of-address resolution
local fToSon, fToSonKind = Beats.ResolveKinshipAddress(father, son)
T.equal(fToSon, "son", "father addresses male child as 'son'")
T.equal(fToSonKind, "parent_to_child", "father -> son kinship role identified")

local fToDaughter = Beats.ResolveKinshipAddress(father, daughter)
T.equal(fToDaughter, "sweetheart", "father addresses female child as 'sweetheart'")

local sonToFather, sToFKind = Beats.ResolveKinshipAddress(son, father)
T.equal(sonToFather, "Dad", "son addresses male parent as 'Dad'")
T.equal(sToFKind, "child_to_parent", "son -> father kinship role identified")

-- 2) Willingness scoring (rival veto + trait scaling)
local rivalProb = Beats.EvaluateShareWillingness(father, rival, "eat", "critical", 2)
T.equal(rivalProb, 0.0, "rival/hostile teammate receives 0 share probability")

local selfishProb = Beats.EvaluateShareWillingness(selfishPeer, son, "eat", "medium", 1)
local generousProb = Beats.EvaluateShareWillingness(generousPeer, son, "eat", "medium", 1)
T.truthy(generousProb > selfishProb + 0.4, "generous/compassionate peer is much more willing to share than selfish peer")

-- 3) End-to-end group share: Father shares Canned Beans with starving Son
local ok, res = Beats.CheckGroupItemShare(simNow, { force = true, forceRoll = 0.05 })
T.equal(ok, true, "father shares food with starving son in same group")
T.equal(res.donorId, "npc_father", "donor is father")
T.equal(res.recipientId, "npc_son", "recipient is son")
T.equal(res.donorAddress, "son", "father calls recipient 'son'")
T.equal(res.recipAddress, "Dad", "son calls donor 'Dad'")

-- Inventory transferred
T.equal(#father.inventory.items, 0, "item removed from father inventory")
T.equal(#son.inventory.items, 1, "item added to son inventory")
T.equal(son.inventory.items[1].fullType, "Base.CannedBeans", "transferred exact item fullType")

-- Handover animations + held-item props played on BOTH NPCs
T.equal(#scenesPlayed, 2, "played give and receive handover scenes")
T.equal(scenesPlayed[1].sceneId, "social.item_share_give", "donor plays social.item_share_give")
T.equal(scenesPlayed[1].propPrimary, "Base.CannedBeans", "donor holds Base.CannedBeans in hand")
T.equal(scenesPlayed[2].sceneId, "social.item_share_receive", "recipient plays social.item_share_receive")
T.equal(scenesPlayed[2].propPrimary, "Base.CannedBeans", "recipient receives Base.CannedBeans in hand")

-- Multi-turn convo beats delivered with kinship terms & item name
T.equal(#spoken, 2, "delivered donor offer + recipient thanks turns")
T.truthy(string.find(spoken[1], "npc_father:share_give_eat:addr=son:", 1, true) ~= nil, "father spoke share_give_eat calling Carl 'son'")
T.truthy(string.find(spoken[2], "npc_son:share_thanks_eat:", 1, true) ~= nil and string.find(spoken[2], ":giver=Dad:", 1, true) ~= nil,
    "son spoke share_thanks_eat calling Rick 'Dad'")

-- Bidirectional relationship improved
T.equal(#relEffects, 2, "applied bidirectional relationship improvements")
T.equal(relEffects[1].actorId, "npc_son", "son's relationship toward father improved")
T.truthy(relEffects[1].approval >= 6 and relEffects[1].respect >= 4, "critical food share grants strong approval & respect gain")
T.equal(relEffects[2].actorId, "npc_father", "father's relationship toward son also improved")

-- 4) Provision integration: TryProvisionFromTeammate works for food rule & emits LogInfo
local logs = {}
PNC.Core.LogInfo = function(msg) logs[#logs + 1] = tostring(msg) end
father.inventory.items[#father.inventory.items + 1] = {
    id = "item_apple_2", type = "Base.Apple", displayName = "Apple", isFood = true,
}
daughter.needs.hunger = 0.85
local provOk, provRes = Beats.TryProvisionFromTeammate(daughter, "food", simNow + 20000, { forceRoll = 0.05 })
T.equal(provOk, true, "TryProvisionFromTeammate fulfills food provision rule from father")
T.equal(provRes.source, "provision", "share payload records source=provision")
T.equal(provRes.donorAddress, "sweetheart", "father calls daughter 'sweetheart' during provision share")
T.equal(provRes.recipAddress, "Dad", "daughter calls father 'Dad' during provision share")
T.equal(#daughter.inventory.items, 1, "daughter received Base.Apple in canonical inventory")
T.equal(daughter.inventory.items[1].type, "Base.Apple", "transferred item spec uses canonical .type field")
T.truthy(#logs >= 1 and string.find(logs[#logs], "[Provision][ItemShare]", 1, true) ~= nil, "emits [Provision][ItemShare] info log")

print("pnc_group_item_share_smoke: OK")
