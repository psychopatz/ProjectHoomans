-- Smoke test for emergent cross-faction stranger encounters:
-- wariness calculation (group size, personality, armed posture, Knox paranoia),
-- wary firearm standoff (CombatStance + AimPistol/AimRifle + 3-stance resolution),
-- re-encounter reunion & grounded WorldKnowledge road warnings, and bonded-loss
-- grief_loss suicide cause hook.

local T = require "tests/support/test"

T.addPackagePaths()

PNC = PNC or {}
PNC.Const = { PRESENCE_LIVE = "live" }
PNC.Semantics = PNC.Semantics or {}
PNC.Core = {
    Now = function() return 10000 end,
    IsAuthority = function() return true end,
}

local ConvoDSL = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL"
local Catalog = require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
T.load(T.path("ProjectHoomans", "shared", "PNC/Semantics/PNC_ActorReference.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Behaviors/PNC_Behavior_Suicide.lua"))
T.load(T.path("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticSpeechPerformance_Cues.lua"))

PNC.Semantics.DialogueBeats = PNC.Semantics.DialogueBeats or {}
local Beats = PNC.Semantics.DialogueBeats
local emitted = {}
Beats.RegisterHook = function() end
Beats.Emit = function(eventName, payload)
    emitted[#emitted + 1] = { eventName = eventName, payload = payload }
    return true, "thread_" .. tostring(#emitted)
end
T.load(T.path("ProjectHoomans", "server", "PNC/Semantics/Beats/PNC_SemanticBeats_StrangerEncounters.lua"))

local Ref = PNC.ActorReference
local Suicide = PNC.BehaviorSuicide

-- 1. ConvoDSL loads stranger_encounters.convo cleanly with zero errors
local diag = ConvoDSL.Reload("EN")
T.equal(#(diag.errors or {}), 0,
    "EN ConvoBlocks must load with zero errors: " .. table.concat(diag.errors or {}, "; "))
local encPool = Catalog.Get("semantic.social.stranger.encounter")
T.truthy(encPool and type(encPool.variants) == "table" and #encPool.variants >= 16,
    "semantic.social.stranger.encounter pool must contain standoff, reunion, rumor, and grief lines")

-- 2. Wariness calculation: personality + group size + armed posture + Knox paranoia
local guardedNpc = {
    id = "g1", name = "Cole Mercer", factionID = "fac_a", socialStyle = "guarded",
    traits = { "frayed_nerves" }, x = 10, y = 10, z = 0,
    equipment = { primary = { fullType = "Base.Pistol", isRanged = true, currentAmmoCount = 6 } },
}
local warmNpc = {
    id = "w1", name = "Clara Brooks", factionID = "fac_a", socialStyle = "warm",
    traits = { "friendly", "iron_nerves" }, personality = { trust = 0.85 },
    x = 10, y = 10, z = 0,
}
local stranger = {
    id = "s1", name = "Dante Ruiz", factionID = "fac_b", x = 13, y = 10, z = 0,
    equipment = { primary = { fullType = "Base.HuntingRifle", isRanged = true, currentAmmoCount = 4 } },
}

local waryOutnumbered = Beats.ComputeEncounterWariness(guardedNpc, stranger, {
    groupSizeA = 1, groupSizeB = 3, hasFirearmA = true,
})
local warmOutnumbering = Beats.ComputeEncounterWariness(warmNpc, stranger, {
    groupSizeA = 3, groupSizeB = 1, hasFirearmA = false,
})
T.truthy(waryOutnumbered >= 0.75, "guarded + outnumbered + armed must yield high wariness")
T.truthy(warmOutnumbering < 0.30, "warm + outnumbering must yield low wariness")

-- Knox fever on stranger spikes wariness
local sickStranger = {
    id = "s_sick", name = "Mila", factionID = "fac_b",
    health = { body = { infection = { active = true, progress = 0.60 } } },
}
local knoxWariness = Beats.ComputeEncounterWariness(warmNpc, sickStranger, { groupSizeA = 1, groupSizeB = 1 })
T.truthy(knoxWariness >= warmOutnumbering + 0.25, "visible Knox fever must spike stranger wariness")

-- 3. Wary firearm standoff: draws gun via CombatStance, plays AimPistol, ACCEPT exchanges names
local stanceMaintained = {}
local perfAnims = {}
local pairFam = {}
local function fKey(a, b) return tostring(a) .. "->" .. tostring(b) end

PNC.CombatStance = {
    Maintain = function(rec) stanceMaintained[rec.id] = (stanceMaintained[rec.id] or 0) + 1; return true end,
    IsArmed = function() return false end,
}
PNC.Semantics.SpeechPerformance.Perform = function(rec, spec)
    perfAnims[#perfAnims + 1] = { npcId = rec.id, anim = spec.anim }
    return true
end
PNC.Relationships = {
    GetFamiliarity = function(obs, key) return pairFam[fKey(obs, key)] or 0 end,
    ApplyConversationEffect = function(obs, key, spec)
        local k = fKey(obs, key)
        pairFam[k] = (pairFam[k] or 0) + (tonumber(spec.familiarityDelta) or 0)
        return true
    end,
}
PNC.Semantics.ConversationDirector = {
    EvaluateCandidate = function() return true end,
    SelectSuggestionForNPC = function() return { speechAct = "ACCEPT" } end,
    MarkSpoken = function() end,
}

Beats.ResetStrangerEncountersRuntime()
local okStandoff = Beats.TryCrossFactionEncounter({
    { teamKey = "fac_a", members = { guardedNpc } },
    { teamKey = "fac_b", members = { stranger } },
}, 50000, { cooldownScale = 1.0 }, false)

T.truthy(okStandoff and #emitted == 1, "wary armed stranger encounter must emit standoff")
T.equal(emitted[1].eventName, "ambient.stranger_standoff", "event must be ambient.stranger_standoff")
T.equal(emitted[1].payload.replyRole, "standoff_reply_comply", "ACCEPT must use standoff_reply_comply")
T.truthy((stanceMaintained["g1"] or 0) >= 1, "challenger must draw gun via CombatStance.Maintain")
T.equal(perfAnims[1].anim, "PNC_Anim_AimPistol", "handgun challenger must play PNC_Anim_AimPistol")
T.equal(Ref.KnowsName(guardedNpc, stranger), true, "peaceful standoff resolution must unlock mutual names")

-- 4. Re-encounter with grounded WorldKnowledge road warning (power out)
PNC.Semantics.BeatContext = {
    GetWorldUtilities = function() return { powerOn = false, waterOn = true } end,
}
local okReunion = Beats.TryCrossFactionEncounter({
    { teamKey = "fac_a", members = { guardedNpc } },
    { teamKey = "fac_b", members = { stranger } },
}, 400000, { cooldownScale = 1.0 }, false)
T.truthy(okReunion and #emitted == 2, "acquainted cross-faction pair must emit reunion/rumor")
T.equal(emitted[2].eventName, "ambient.stranger_reunion", "event must be ambient.stranger_reunion")
T.equal(emitted[2].payload.openRole, "rumor_warn_open", "grounded power outage must trigger rumor_warn_open")
T.truthy(string.find(emitted[2].payload.tokens["slot.rumor"], "power", 1, true), "rumor must reflect power outage")

-- 5. Bonded-loss grief_loss cause via OnBondedNPCDeath
local deceased = {
    id = "npc_sister", name = "Hannah", isFemale = true, familyId = "fam_42",
    x = 30, y = 30, z = 0, alive = false,
}
local brother = {
    id = "npc_brother", name = "Liam", isFemale = false, familyId = "fam_42",
    x = 32, y = 30, z = 0, alive = true, presenceState = "live",
    needs = { stress = 0.2 },
    equipment = { primary = { fullType = "Base.Pistol", isRanged = true, currentAmmoCount = 5 } },
}
PNC.Registry = {
    ForEach = function(fn) fn(brother) end,
    Get = function(id) return id == brother.id and brother or nil end,
}
local griefTriggered = Suicide.OnBondedNPCDeath(deceased, 500000, { force = true })
T.truthy(griefTriggered, "OnBondedNPCDeath must trigger grief_loss for bonded armed family member")
T.equal(brother.runtime.suicideState.causeId, "grief_loss", "suicide causeId must be grief_loss")
T.equal(brother.runtime.suicideState.tokens["lost.name"], "Hannah", "grief tokens must carry lost.name")
T.equal(brother.runtime.suicideState.tokens["lost.obj"], "her", "grief tokens must carry proper lost.obj pronoun")

-- 6. Actor-agnostic Stranger NPC -> Player armed standoff + 3-stance player resolution
local playerActor = {
    id = "player",
    isPlayer = true,
    key = "player:jordan",
    name = "Jordan",
    armed = true,
    x = 12, y = 10, z = 0,
}
local waryGuard = {
    id = "g_player", name = "Vance", factionID = "fac_roam", socialStyle = "guarded",
    traits = { "frayed_nerves" }, x = 10, y = 10, z = 0,
    equipment = { primary = { fullType = "Base.Pistol", isRanged = true, currentAmmoCount = 5 } },
}
local stanceCleared = false
PNC.CombatStance.Clear = function() stanceCleared = true; return true end

Beats.ResetStrangerEncountersRuntime()
local okPlayerStandoff = Beats.TryCrossFactionEncounter({
    { teamKey = "fac_roam", members = { waryGuard } },
    { teamKey = "player_party", members = { playerActor } },
}, 600000, { cooldownScale = 1.0 }, false)
T.truthy(okPlayerStandoff, "stranger standoff must work when target is a Player")
local pending = Beats.GetPendingStrangerEncounter("player:jordan", 600500)
T.truthy(pending and pending.kind == "standoff", "player must receive pending standoff frontier")
T.equal(#pending.frontier, 3, "pending standoff must expose 3-stance frontier")

local resOk, resAct = Beats.ResolveStrangerEncounterChoice("player:jordan", "accept", { now = 601000 })
T.truthy(resOk and resAct == "ACCEPT", "player ACCEPT choice must resolve standoff")
T.truthy(stanceCleared, "peaceful standoff resolution must lower challenger CombatStance")
T.falsy(Beats.GetPendingStrangerEncounter("player:jordan", 601000), "pending encounter must clear after resolution")

-- 7. Territory / camp challenge (unarmed camped defender vs passing stranger)
local campDefender = {
    id = "camp_1", name = "Owen", factionID = "fac_camp", activeJob = "AtCamp",
    socialStyle = "neutral", x = 40, y = 40, z = 0,
}
local passerby = {
    id = "pass_1", name = "Tessa", factionID = "fac_road", x = 43, y = 40, z = 0,
}
local okTerritory = Beats.TryCrossFactionEncounter({
    { teamKey = "fac_camp", members = { campDefender } },
    { teamKey = "fac_road", members = { passerby } },
}, 700000, { cooldownScale = 1.0 }, false)
T.truthy(okTerritory, "camped NPC must challenge unfamiliar passerby")
T.equal(emitted[#emitted].eventName, "ambient.stranger_territory", "must emit ambient.stranger_territory")

-- 8. Mercy / micro-aid request from visibly hungry stranger
local hungryStranger = {
    id = "aid_1", name = "Ben", factionID = "fac_solo", x = 60, y = 60, z = 0,
    needs = { hunger = 0.85 },
}
local kindColonist = {
    id = "aid_2", name = "Grace", factionID = "fac_col", socialStyle = "warm", x = 62, y = 60, z = 0,
}
local okAid = Beats.TryCrossFactionEncounter({
    { teamKey = "fac_solo", members = { hungryStranger } },
    { teamKey = "fac_col", members = { kindColonist } },
}, 800000, { cooldownScale = 1.0 }, false)
T.truthy(okAid, "hungry stranger must be able to request micro-aid")
T.equal(emitted[#emitted].eventName, "ambient.stranger_aid", "must emit ambient.stranger_aid")
T.equal(emitted[#emitted].payload.tokens["slot.need"], "some food", "must request food when hungry")

-- 9. Mourning witness empathy reaction
local passerEmpath = {
    id = "emp_1", name = "Maya", factionID = "fac_road2", socialStyle = "warm", x = 80, y = 80, z = 0,
}
local mourner = {
    id = "mourn_1", name = "Paul", factionID = "fac_col2", activeJob = "SuicideWitness", x = 82, y = 80, z = 0,
}
local okMournWitness = Beats.TryCrossFactionEncounter({
    { teamKey = "fac_road2", members = { passerEmpath } },
    { teamKey = "fac_col2", members = { mourner } },
}, 900000, { cooldownScale = 1.0 }, false)
T.truthy(okMournWitness, "passing stranger must react to mourning NPC")
T.equal(emitted[#emitted].eventName, "ambient.mourning_witness", "must emit ambient.mourning_witness")

T.finish("pnc_stranger_encounters_smoke")
