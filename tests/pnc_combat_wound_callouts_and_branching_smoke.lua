local T = require "tests/support/test"
T.addPackagePaths({
    { "PsychopatzCore", "common" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "common_lua" },
})

isClient = function() return false end
isServer = function() return true end

local worldHours = 50.0
getGameTime = function()
    return {
        getWorldAgeHours = function() return worldHours end,
        getWorldAgeDaysSinceBegin = function() return worldHours / 24 end,
    }
end

SandboxVars = {
    ZombieLore = { Transmission = 1 },
    ProjectHoomans = { NPCZombieInfectionChance = 100, NPCInfectionMortalityHours = 48 },
}

local nowMs = 10000
local deliveredBarks = {}
local painBarks = {}
local dirtyMarks = {}
local emittedEvents = {}
local npcStore = {}
local liveBodies = {}

local playerObj = {
    _x = 12, _y = 10, _z = 0, _dead = false,
    getX = function(self) return self._x end,
    getY = function(self) return self._y end,
    getZ = function(self) return self._z end,
    isDead = function(self) return self._dead end,
    getOnlineID = function() return 77 end,
    getUsername = function() return "OwnerPlayer" end,
    getDescriptor = function() return { getForename = function() return "Alex" end } end,
}

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.RuntimeRole = { AllowsServerCode = function() return true end }

PNC = {
    Const = {
        MODULE = "PNC",
        ZOMBIE_TARGET_RADIUS = 16,
        ALLY_WARNING_RADIUS = 16,
        PRESENCE_LIVE = "live",
        INCAPACITATED_HP = 15,
        INCAPACITATED_GRACE_MS = 3000,
    },
    Core = {
        Now = function() return nowMs end,
        IsAuthority = function() return true end,
        IsClientOnly = function() return false end,
        Clamp = function(v, lo, hi)
            v = tonumber(v) or lo
            if v < lo then return lo end
            if v > hi then return hi end
            return v
        end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx, dy = (tonumber(x2) or 0) - (tonumber(x1) or 0), (tonumber(y2) or 0) - (tonumber(y1) or 0)
            return dx * dx + dy * dy
        end,
        ForEachPlayer = function(cb) cb(playerObj) end,
        DeepCopy = function(v)
            if type(v) ~= "table" then return v end
            local out = {}
            for k, item in pairs(v) do out[k] = item end
            return out
        end,
    },
    Registry = {
        Data = npcStore,
        Get = function(id) return npcStore[tostring(id)] end,
        GetLiveZombie = function(id) return liveBodies[tostring(id)] end,
        MarkDirty = function(rec, reason)
            dirtyMarks[#dirtyMarks + 1] = { id = rec and rec.id, reason = reason }
        end,
    },
    SpatialIndex = {
        QueryNPCs = function(rx, ry, radius)
            local rSq = (tonumber(radius) or 16) ^ 2
            local out = {}
            for _, rec in pairs(npcStore) do
                local dx, dy = (tonumber(rec.x) or 0) - rx, (tonumber(rec.y) or 0) - ry
                if (dx * dx + dy * dy) <= rSq then out[#out + 1] = rec end
            end
            return out
        end,
    },
    Network = {
        SendConversationRelationshipForNPC = function(_player, npcId, eventType, payload)
            if tostring(eventType) == "combat_injury_pain_reaction" then
                painBarks[#painBarks + 1] = { npcId = tostring(npcId), text = payload and payload.ambientFlavor and payload.ambientFlavor.text, ambientFlavor = payload and payload.ambientFlavor }
                return true
            end
            deliveredBarks[#deliveredBarks + 1] = {
                npcId = tostring(npcId),
                eventType = tostring(eventType),
                text = payload and payload.ambientFlavor and payload.ambientFlavor.text or nil,
                ambientFlavor = payload and payload.ambientFlavor or nil,
                offerIDs = payload and (payload.offerIDs or (payload.ambientFlavor and payload.ambientFlavor.offerIDs)) or nil,
                semanticEventFacts = payload and payload.semanticEventFacts or nil,
                lightweightBark = payload and payload.lightweightBark or nil,
                at = nowMs,
            }
            return true
        end,
    },
    Factions = {
        GetFactionID = function(rec) return rec and rec.factionID or nil end,
        AreAllied = function(f1, f2) return f1 ~= nil and f1 == f2 end,
    },
    Relationships = {
        Get = function(observerId, targetKey)
            local rec = npcStore[tostring(observerId)]
            local rels = rec and rec.social and rec.social.relationships or nil
            return type(rels) == "table" and rels[targetKey] or nil
        end,
    },
    SecondaryChannel = {
        RequestBark = function() end,
        SetAlertLevel = function() end,
        RequestGaze = function() end,
    },
    Health = {
        Ensure = function(rec)
            rec.health = type(rec.health) == "table" and rec.health or { current = 100, max = 100, state = "normal" }
            rec.health.max = tonumber(rec.health.max) or 100
            rec.health.current = tonumber(rec.health.current) or rec.health.max
            rec.health.state = rec.health.state or "normal"
            return rec.health
        end,
        ApplyDamage = function(rec, _body, dmg)
            local h = PNC.Health.Ensure(rec)
            local amt = tonumber(dmg and dmg.amount) or 0
            h.current = math.max(10, h.current - amt)
            if PNC.NPCWounds and PNC.NPCWounds.ApplyBodyDamage then
                PNC.NPCWounds.ApplyBodyDamage(rec, amt, dmg and dmg.partId)
            end
            return true, "applied"
        end,
    },
    Perception = {
        CanSeeWorldObject = function() return true end,
        GetTeamKey = function(rec) return rec and rec.factionID and ("faction:" .. rec.factionID) or "solo" end,
        AreWarningAllies = function(a, b)
            return a and b and a.factionID ~= nil and a.factionID == b.factionID, "same_faction"
        end,
    },
    Semantics = {},
    ConvoEngine = {},
}

T.load("PsychopatzCore", "common", "PsychopatzCore/Spatial/PsychopatzSpatialRelation.lua")
T.load("PsychopatzCore", "common", "PsychopatzCore/ConvoEngine/S11PolicyEvaluator.lua")
local Predicate = require "PsychopatzCore/Semantics/PsychopatzSemanticPredicate"
T.load("ProjectHoomans", "common_lua", "PNC/ConvoEngine/Registry.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Dialogue/ResponseCatalog.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/SpeechRealization.lua")
T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/Social/Reaction.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Sandbox.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Definitions.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_BodyState.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_WholeBody.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Infection.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Mutation.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Treatment.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Snapshot.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_ZombieAttack_Common.lua")

local Wounds = PNC.NPCWounds
local Callouts = T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticCombatTargetCallouts.lua")

local function assertCleanText(txt, label)
    T.truthy(type(txt) == "string" and txt ~= "", label .. " must produce text")
    T.falsy(string.find(txt, "{", 1, true), label .. " must not leave raw {tokens}: " .. tostring(txt))
    T.falsy(string.find(txt, "}", 1, true), label .. " must not leave raw }tokens}: " .. tostring(txt))
    T.falsy(string.find(txt, "\226\128\148", 1, true), label .. " must not contain em-dash")
    T.falsy(string.find(txt, "--", 1, true), label .. " must not contain double hyphen")
end

local function makeNPC(id, name, opts)
    opts = opts or {}
    local rec = {
        id = id,
        name = name,
        alive = true,
        presenceState = "live",
        x = opts.x or 10,
        y = opts.y or 10,
        z = opts.z or 0,
        factionID = opts.factionID or "survivors",
        attackType = opts.attackType or "auto",
        psychopath = opts.psychopath == true,
        traits = opts.traits or {},
        social = opts.social or { relationships = {}, personality = {} },
        runtime = {},
        health = { current = 100, max = 100, state = "normal" },
    }
    npcStore[id] = rec
    liveBodies[id] = { isDead = function() return false end, getX = function() return rec.x end, getY = function() return rec.y end, getZ = function() return rec.z end }
    return rec
end

-- 1. All base-game BodyPart wound tiers (worst -> least) + Sandbox saliva transmission toggle.
do
    local tierOrder = { "scratch", "laceration", "burn", "fracture", "deep_wound", "deep_wound_glass", "bullet", "bite" }
    local prevPri = 0
    for _, wt in ipairs(tierOrder) do
        local st = Wounds.GetWoundStats(wt)
        T.truthy(st, "WoundStats supports base-game type " .. wt)
        T.truthy(st.priority >= prevPri, wt .. " maintains worst-to-least priority order")
        prevPri = st.priority
    end
    T.equal(Wounds.NormalizeWoundType("glass"), "deep_wound_glass", "glass alias normalizes to deep_wound_glass")

    local adrienne = makeNPC("adri", "Adrienne")
    local sammie = makeNPC("sam", "Sammie", { x = 11, social = { relationships = { ["npc:adri"] = { state = "friend", approval = 80 } }, personality = { compassion = 0.85 } } })

    -- Scratch then laceration then bullet then bite preempting cooldown!
    nowMs = 20000
    local okScr = Wounds.ApplyCombatDamage(adrienne, liveBodies.adri, { amount = 4, partId = "ForeArm_L", woundType = "scratch", attackerKind = "zombie" })
    T.truthy(okScr, "scratch damage applies")
    T.equal(#painBarks, 1, "scratch emits immediate pain reaction Beat first")
    T.equal(painBarks[1].ambientFlavor.context.combatReactionRole, "scratch_minor", "scratch pain variant")
    assertCleanText(painBarks[1].text, "scratch pain beat")
    T.equal(deliveredBarks[1].eventType, "combat_wound_received_beat", "scratch emits wound_received_beat")
    assertCleanText(deliveredBarks[1].text, "scratch beat")
    T.contains(string.lower(deliveredBarks[1].text), "left forearm", "scratch names damaged body part")

    -- Higher tier (deep_wound_glass) 200ms later preempts scratch cooldown!
    nowMs = nowMs + 200
    deliveredBarks = {}
    local okGlass = Wounds.ApplyCombatDamage(adrienne, liveBodies.adri, { amount = 11, partId = "UpperLeg_R", woundType = "glass", attackerKind = "npc" })
    T.truthy(okGlass, "glass wound applies")
    T.equal(#deliveredBarks, 1, "higher-tier wound preempts scratch cooldown")
    T.equal(deliveredBarks[1].ambientFlavor.context.combatWoundType, "deep_wound_glass", "carries deep_wound_glass tier")
    assertCleanText(deliveredBarks[1].text, "deep_wound_glass beat")

    -- Burn, fracture, and bullet beats
    for _, spec in ipairs({
        { wt = "burn", part = "Hand_R" },
        { wt = "fracture", part = "LowerLeg_L" },
        { wt = "bullet", part = "Torso_Upper" },
    }) do
        nowMs = nowMs + 5000
        deliveredBarks = {}
        Wounds.ApplyCombatDamage(adrienne, liveBodies.adri, { amount = 10, partId = spec.part, woundType = spec.wt, attackerKind = "npc" })
        T.equal(#deliveredBarks, 1, spec.wt .. " emits beat")
        T.equal(deliveredBarks[1].ambientFlavor.context.combatWoundType, spec.wt, spec.wt .. " variant selected")
        assertCleanText(deliveredBarks[1].text, spec.wt .. " beat")
    end

    -- Lethal saliva bite (Transmission = 1) vs non-transmissible saliva bite (Transmission = 4)
    nowMs = nowMs + 200
    deliveredBarks = {}
    Callouts.ResetRuntime()
    SandboxVars.ZombieLore.Transmission = 1
    local biteTarget = makeNPC("bitten-1", "Raymond")
    local okBiteLethal = Wounds.ApplyCombatDamage(biteTarget, liveBodies["bitten-1"], { amount = 12, partId = "Neck", woundType = "bite", attackerKind = "zombie" })
    T.truthy(okBiteLethal, "lethal bite applies")
    T.truthy(Wounds.HasActiveInfection and (biteTarget.health.body.infection and biteTarget.health.body.infection.active == true), "saliva transmissible bite infects NPC")
    T.equal(deliveredBarks[1].ambientFlavor.context.combatWoundType, "bite_possible_exposure", "fresh bite uses bite_possible_exposure rather than premature bite_lethal")
    T.truthy(#(deliveredBarks[1].offerIDs or {}) >= 3, "bite callout exposes interactive player reply offers")
    assertCleanText(deliveredBarks[1].text, "bite_possible_exposure beat")

    -- Sandbox Transmission = 4 (None / not transmissible via saliva)
    nowMs = nowMs + 6000
    deliveredBarks = {}
    Callouts.ResetRuntime()
    SandboxVars.ZombieLore.Transmission = 4
    local safeBiteNpc = makeNPC("bitten-safe", "Francis")
    local okBiteSafe = Wounds.ApplyCombatDamage(safeBiteNpc, liveBodies["bitten-safe"], { amount = 12, partId = "ForeArm_R", woundType = "bite", attackerKind = "zombie" })
    T.truthy(okBiteSafe, "non-transmissible bite applies")
    T.falsy(safeBiteNpc.health.body.infection, "Transmission=4 does not trigger lethal zombie virus infection")
    T.equal(deliveredBarks[1].ambientFlavor.context.combatWoundType, "bite_non_transmissible", "uses bite_non_transmissible variant")
    assertCleanText(deliveredBarks[1].text, "bite_non_transmissible beat")
    nowMs = nowMs + 700
    T.equal(Callouts.PumpPendingReplies(nowMs), 1, "ally responds to non-transmissible bite")
    T.equal(deliveredBarks[2].ambientFlavor.speechEventID, "semantic.combat.wound.ally_reaction.bite_non_transmissible_relief",
        "ally reassures non-transmissible saliva rule while urging bleeding control")
    assertCleanText(deliveredBarks[2].text, "bite_non_transmissible ally reply")
end

-- 2. Fighting-while-injured callouts: with_wounds & patched_up across body regions and severities.
do
    npcStore, liveBodies, deliveredBarks = {}, {}, {}
    Callouts.ResetRuntime()
    SandboxVars.ZombieLore.Transmission = 1
    local partner = makeNPC("partner", "Sammie", { x = 11 })

    local matrix = {
        { part = "Head", wt = "laceration", patch = false, expect = "with_wounds_head_neck_critical" },
        { part = "Neck", wt = "laceration", patch = true, expect = "patched_up_head_neck_severe" },
        { part = "Torso_Upper", wt = "deep_wound", patch = false, expect = "with_wounds_torso_critical" },
        { part = "Torso_Lower", wt = "laceration", patch = true, expect = "patched_up_torso" },
        { part = "UpperArm_L", wt = "deep_wound", patch = false, expect = "with_wounds_upper_limb_severe" },
        { part = "Hand_R", wt = "laceration", patch = true, expect = "patched_up_upper_limb" },
        { part = "LowerLeg_L", wt = "fracture", patch = false, expect = "with_wounds_lower_limb_severe" },
        { part = "Foot_R", wt = "laceration", patch = true, expect = "patched_up_lower_limb" },
        { part = "ForeArm_L", wt = "scratch", patch = false, expect = "with_wounds_minor" },
        { part = "UpperLeg_L", wt = "scratch", patch = true, expect = "patched_up_minor" },
    }
    for i, c in ipairs(matrix) do
        local f = makeNPC("f-" .. tostring(i), "Adrienne")
        local partHp = c.expect:find("critical") and 30 or (c.expect:find("severe") and 50 or 85)
        f.health.body = { wounds = { [c.part] = { partId = c.part, type = c.wt, bandaged = c.patch, bleedingRate = c.patch and 0 or (c.wt == "scratch" and 0.015 or 0.055) } }, parts = { [c.part] = { current = partHp, max = 100 } } }
        if c.wt == "fracture" and c.patch then f.health.body.wounds[c.part].splinted = true end
        local prof = Callouts.ClassifyActorWoundProfile(f)
        T.truthy(prof, "classifies injury profile for " .. c.expect)
        local variant = Callouts.ResolveFightingInjuredVariant(prof)
        T.equal(variant, c.expect, "variant matches " .. c.expect)
        nowMs = nowMs + 10000
        deliveredBarks = {}
        local ok, usedVar = Callouts.OnFightingWhileInjured(f, { enemyType = "zombie" }, nowMs, { ignoreCooldown = true })
        T.truthy(ok, "OnFightingWhileInjured emits for " .. c.expect)
        T.equal(usedVar, c.expect, "emitted variant equals " .. c.expect)
        assertCleanText(deliveredBarks[1].text, "fighting injured " .. c.expect)
    end
end

-- 3. Dynamic participant counts (solo/duo/squad) + Psychopath / Close Bond reactions to lethal bite.
do
    npcStore, liveBodies, deliveredBarks = {}, {}, {}
    Callouts.ResetRuntime()
    SandboxVars.ZombieLore.Transmission = 1

    -- 3a. Solo injured NPC far from allies -> speaks directly to nearby player, 0 NPC replies; silent if player far.
    local solo = makeNPC("solo-npc", "Faustino", { x = 500, y = 500, factionID = "solo_fac" })
    solo.health.body = { wounds = { Torso_Upper = { partId = "Torso_Upper", type = "laceration", bandaged = false, bleedingRate = 0.055 } }, parts = {} }
    playerObj._x, playerObj._y = 503, 500
    nowMs = 150000
    local okSolo = Callouts.OnFightingWhileInjured(solo, nil, nowMs)
    T.truthy(okSolo, "solo injured fighter speaks to nearby player")
    T.equal(deliveredBarks[1].ambientFlavor.context.participantBand, "solo", "records solo participant band")
    T.contains(deliveredBarks[1].text, "Alex", "solo callout addresses player")
    T.equal(Callouts.PendingReplyCount, 0, "solo queues zero NPC replies")

    playerObj._x, playerObj._y = 12, 10
    nowMs = nowMs + 15000
    local okFar = Callouts.OnFightingWhileInjured(solo, nil, nowMs)
    T.falsy(okFar, "solo NPC without allies or player nearby stays silent")

    -- 3b. Squad lethal bite with Close Friend + Psychopath!
    deliveredBarks = {}
    Callouts.ResetRuntime()
    local victim = makeNPC("vic", "Clay", { x = 10, y = 10, factionID = "alpha" })
    local friendAlly = makeNPC("friend-1", "Sammie", {
        x = 11, y = 10, factionID = "alpha",
        social = {
            relationships = { ["npc:vic"] = { state = "friend", approval = 85 } },
            personality = { compassion = 0.90, loyalty = 0.85 },
        },
    })
    local psychoAlly = makeNPC("psycho-1", "Vane", {
        x = 12, y = 10, factionID = "alpha",
        psychopath = true,
        social = {
            relationships = { ["npc:vic"] = { state = "neutral", approval = -10 } },
            personality = { compassion = 0.05, aggression = 0.95 },
        },
    })
    playerObj._x, playerObj._y = 11, 11
    nowMs = 200000
    local okSquadBite = Wounds.ApplyCombatDamage(victim, liveBodies.vic, { amount = 12, partId = "UpperArm_R", woundType = "bite", attackerKind = "zombie" })
    T.truthy(okSquadBite, "squad victim bite applies")
    T.equal(deliveredBarks[1].ambientFlavor.context.participantBand, "squad", "squad participant band detected")
    T.equal(deliveredBarks[1].ambientFlavor.context.participantCount, 3, "participantCount includes all 3 squad members")
    T.equal(Callouts.PendingReplyCount, 2, "squad queues 2 staggered reactions (psycho threat + close friend)")

    nowMs = nowMs + 700
    T.equal(Callouts.PumpPendingReplies(nowMs), 1, "first squad reactor fires")
    nowMs = nowMs + 700
    T.equal(Callouts.PumpPendingReplies(nowMs), 1, "second squad reactor fires")
    local sawPsycho, sawFriend = false, false
    for _, b in ipairs(deliveredBarks) do
        assertCleanText(b.text, "squad bite bark")
        if b.npcId == "psycho-1" and b.ambientFlavor.speechEventID == "semantic.combat.wound.ally_reaction.psychopath_bite_execution_threat" then
            sawPsycho = true
        elseif b.npcId == "friend-1" and b.ambientFlavor.speechEventID == "semantic.combat.wound.ally_reaction.close_bond_bite_lethal" then
            sawFriend = true
        end
    end
    T.truthy(sawPsycho, "psychopath squadmate delivers cold bite execution threat")
    T.truthy(sawFriend, "close friend squadmate delivers emotional refusal to abandon bitten ally")
    T.truthy(victim.runtime.biteConflictFacts and victim.runtime.biteConflictFacts.challengerStance == "hostile_suspect",
        "exposes pure semantic biteConflictFacts without embedded action command")
    T.equal(victim.runtime.biteConflictFacts.recommendedAction, nil,
        "dialogue callouts do not embed recommendedAction commands")
    local conflictPolicy = Wounds.EvaluateBiteConflictPolicy(psychoAlly, victim)
    T.equal(conflictPolicy.stance, "threaten",
        "EvaluateBiteConflictPolicy resolves threaten stance while exposure is possible")
end

-- 4. Interactive ConvoEngine flow + player branching + multi-NPC policy scoring on combat.injury.triage_exchange.
do
    local Registry = PNC.ConvoEngine.Registry
    local FlowRegistry = require "PNC/ConvoEngine/Dialogue/FlowRegistry"
    local CompiledFlows = require "PNC/ConvoEngine/Flows/Dialogue/CombatWoundCallouts"
    local triagePlan = Registry.ConvoPlan("combat.injury.triage_exchange")
    T.truthy(triagePlan, "combat.injury.triage_exchange ConvoPlan compiled")
    T.equal(triagePlan.roles.witness.cardinality, "BOUNDED_MANY", "supports dynamic BOUNDED_MANY witnesses")
    local flow = CompiledFlows and CompiledFlows[1] or nil
    T.truthy(flow and flow.id == "combat.injury.triage_exchange", "triage_exchange flow exported")
    local okVal, valRes = FlowRegistry.Validate(flow)
    T.truthy(okVal, "combat.injury.triage_exchange passes FlowRegistry.Validate: " .. tostring(valRes))

    -- Check constrained player offers toggle properly based on salivaTransmissible and isBitten.
    local biteNode = flow.nodes.bite_transmission_check
    local predCtxSalivaOn = { worldKnowledge = { salivaTransmissible = true }, scene = { hasThirdPartyWitness = true }, npcState = { isBitten = true } }
    local predCtxSalivaOff = { worldKnowledge = { salivaTransmissible = false }, scene = { hasThirdPartyWitness = true }, npcState = { isBitten = true } }
    local matchedOff, matchedOn = {}, {}
    for _, off in ipairs(biteNode.branchOffers) do
        local c = off.constraints
        if c == nil or Predicate.Evaluate(c, predCtxSalivaOn).allowed then matchedOn[off.id] = true end
        if c == nil or Predicate.Evaluate(c, predCtxSalivaOff).allowed then matchedOff[off.id] = true end
    end
    T.truthy(matchedOn["combat.injury.bite_lethal_dread"] and not matchedOn["combat.injury.bite_not_transmissible"],
        "lethal bite player reply offer active only when salivaTransmissible=true")
    T.truthy(matchedOff["combat.injury.bite_not_transmissible"] and not matchedOff["combat.injury.bite_lethal_dread"],
        "non-transmissible relief reply offer active only when salivaTransmissible=false")

    -- Check ChoicePolicy scores psychopath THREATEN vs friend MEDIATE appropriately.
    local ChoicePolicy = require "PNC/ConvoEngine/Social/ChoicePolicy"
    local candidates = {
        { id = "gen.threaten", strategy = "THREATEN", stance = "NEGATIVE", eligibility = { allowed = true } },
        { id = "gen.mediate", strategy = "MEDIATE", stance = "POSITIVE", eligibility = { allowed = true } },
    }
    local psychoPick = ChoicePolicy.Select(candidates, {
        motive = "DISPUTE",
        responderProjection = {
            actor = { capabilities = { speech = true }, disposition = { aggression = 90, confidence = 80, compassion = 5, forgiveness = 10 } },
            relationship = { approval = -30, respect = -20 },
        },
    })
    T.equal(psychoPick.selected.strategy, "THREATEN", "psychopath/low-rel chooses THREATEN interjection over MEDIATE")
    local friendPick = ChoicePolicy.Select(candidates, {
        motive = "MEDIATE",
        responderProjection = {
            actor = { capabilities = { speech = true }, disposition = { aggression = 20, confidence = 65, compassion = 90, forgiveness = 85 } },
            relationship = { approval = 75, respect = 60 },
        },
    })
    T.equal(friendPick.selected.strategy, "MEDIATE", "compassionate ally chooses MEDIATE over THREATEN")
end

-- 5. Stitch/Splint patched tracking, zombie wound beat emission, and multi-NPC TurnPolicy + Conversation execution.
do
    npcStore, liveBodies, deliveredBarks = {}, {}, {}
    Callouts.ResetRuntime()
    SandboxVars.ZombieLore.Transmission = 1

    -- 5a. Stitch & Splint produce patched_up state and remove glass.
    local patient = makeNPC("patient-1", "Francis", { x = 20, y = 20, factionID = "alpha" })
    patient.presenceState = "live"
    local mate = makeNPC("mate-5", "Adrienne", { x = 21, y = 20, factionID = "alpha" })
    playerObj._x, playerObj._y = 20, 22
    nowMs = 250000
    Wounds.ApplyCombatDamage(patient, liveBodies["patient-1"], { amount = 10, partId = "ForeArm_L", woundType = "glass", attackerKind = "human" })
    Wounds.ApplyCombatDamage(patient, liveBodies["patient-1"], { amount = 8, partId = "LowerLeg_L", woundType = "fracture", attackerKind = "human" })
    local okStitch = Wounds.Stitch(patient, "ForeArm_L", nowMs)
    local okSplint = Wounds.Splint(patient, "LowerLeg_L", nowMs)
    T.truthy(okStitch and okSplint, "Stitch and Splint succeed on deep_wound_glass and fracture")
    local summary = Wounds.BuildStatusSummary(patient)
    T.equal(summary.openWoundCount, 0, "stitched + splinted leaves zero open wounds")
    T.equal(summary.patchedWoundCount, 2, "stitched + splinted tracks 2 patched wounds")
    T.equal(summary.patchState, "patched_up", "status summary reports patched_up after stitch + splint")
    T.falsy(patient.health.body.wounds.ForeArm_L.haveGlass, "Stitch removes glass flag by default")
    local patProf = Callouts.ClassifyActorWoundProfile(patient)
    T.equal(patProf.patchState, "patched_up", "ClassifyActorWoundProfile detects stitched+splinted as patched_up")

    -- 5b. Internal.ApplyZombieWoundDamage emits zombie laceration wound beat when surviving.
    deliveredBarks = {}
    local zVic = makeNPC("zvic-1", "Raymond", { x = 20, y = 20, factionID = "alpha" })
    zVic.presenceState = "live"
    nowMs = 260000
    local zPart = Wounds.Parts.Head
    local zWound, zErr = Wounds.Internal.ApplyZombieWoundDamage(zVic, liveBodies["zvic-1"], {
        getX = function() return 20 end, getY = function() return 20 end, getZ = function() return 0 end,
    }, "zombie-55", zPart, "laceration", 8, { outcome = "rejected" })
    T.truthy(zWound and not zErr, "Internal.ApplyZombieWoundDamage applies surviving zombie laceration")
    T.truthy(#deliveredBarks >= 1, "surviving zombie wound emits wound beat callout")
    T.equal(deliveredBarks[1].ambientFlavor.speechEventID, "semantic.combat.wound.received_beat.laceration",
        "zombie wound beat matches laceration tier")

    -- 5c. Multi-NPC TurnPolicy + Conversation controller handles combat.injury.triage_exchange witness interjection.
    local FlowRegistry = require "PNC/ConvoEngine/Dialogue/FlowRegistry"
    local CompiledFlows = require "PNC/ConvoEngine/Flows/Dialogue/CombatWoundCallouts"
    local TurnPolicy = require "PNC/ConvoEngine/Social/TurnPolicy"
    local Conversation = require "PNC/ConvoEngine/Social/Conversation"
    local Scene = require "PNC/ConvoEngine/Interaction/Scene"
    local Providers = require "PNC/ConvoEngine/Interaction/Providers"
    local flow = CompiledFlows[1]
    local biteNode = flow.nodes.bite_transmission_check
    local controller = Conversation.New()
    T.truthy(controller and Scene and Providers and FlowRegistry, "Scene/Conversation/TurnPolicy stack loads cleanly")

    local psychoChoice = require("PNC/ConvoEngine/Social/ChoicePolicy").Select({
        { id = "bite.threaten", strategy = "THREATEN", stance = "NEGATIVE", eligibility = { allowed = true } },
        { id = "bite.ask", strategy = "ASK_FOLLOWUP", stance = "NEUTRAL", eligibility = { allowed = true } },
    }, {
        motive = "DISPUTE",
        responderProjection = {
            actor = { capabilities = { speech = true }, disposition = { aggression = 95, compassion = 5 } },
            relationship = { approval = -30 },
        },
    })
    local friendChoice = require("PNC/ConvoEngine/Social/ChoicePolicy").Select({
        { id = "bite.mediate", strategy = "MEDIATE", stance = "POSITIVE", eligibility = { allowed = true } },
        { id = "bite.corroborate", strategy = "CORROBORATE", stance = "POSITIVE", eligibility = { allowed = true } },
    }, {
        motive = "MEDIATE",
        responderProjection = {
            actor = { capabilities = { speech = true }, disposition = { aggression = 15, compassion = 90 } },
            relationship = { approval = 80 },
        },
    })
    local turn = TurnPolicy.Select({
        participants = {
            { id = "bitten_npc", kind = "npc" },
            { id = "player_1", kind = "player", isPlayer = true },
            { id = "psycho_ally", kind = "npc" },
            { id = "friend_ally", kind = "npc" },
        },
        currentSpeakerID = "bitten_npc",
        currentRecipientID = "player_1",
        allowInterjectionOverPlayerWait = true,
        choicesByActor = {
            psycho_ally = psychoChoice,
            friend_ally = friendChoice,
        },
        interjections = {
            psycho_ally = { allowed = true, priority = 0.55, motive = "DISPUTE", role = "witness", outcome = "bite_execution_threat" },
            friend_ally = { allowed = true, priority = 0.15, motive = "MEDIATE", role = "mediator", outcome = "mediator_deescalates" },
        },
    })
    T.equal(turn.mode, "emit", "multi-NPC turn arbitration fires witness interjection on triage exchange")
    T.equal(turn.actorID, "psycho_ally", "higher-priority hostile interjection surfaces first")
    T.truthy(biteNode and controller:History("combat.injury.triage_exchange") ~= nil,
        "Conversation controller history initializes cleanly for triage_exchange")
end

T.finish("pnc_combat_wound_callouts_and_branching_smoke")
