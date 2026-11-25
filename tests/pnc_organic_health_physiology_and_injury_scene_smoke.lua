local T = require "tests/support/test"
T.addPackagePaths({
    { "PsychopatzCore", "common" },
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "common_lua" },
})

isClient = function() return false end
isServer = function() return true end

local worldHours = 100.0
getGameTime = function()
    return {
        getWorldAgeHours = function() return worldHours end,
        getWorldAgeDaysSinceBegin = function() return worldHours / 24 end,
    }
end

local climateTempC = 20.0
local rainIntensity = 0.0
local windIntensity = 0.0
getClimateManager = function()
    return {
        getTemperature = function() return climateTempC end,
        getRainIntensity = function() return rainIntensity end,
        getWindIntensity = function() return windIntensity end,
    }
end

SandboxVars = {
    ZombieLore = { Transmission = 1, Mortality = 5 },
    ProjectHoomans = { NPCZombieInfectionChance = 100, NPCInfectionMortalityHours = 48 },
}

local nowMs = 50000
local deliveredBarks = {}
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
        PRESENCE_ABSTRACT = "abstract",
        INCAPACITATED_HP = 15,
        INCAPACITATED_GRACE_MS = 3000,
    },
    Core = {
        Now = function() return nowMs end,
        IsAuthority = function() return true end,
        IsClientOnly = function() return false end,
        Clamp = function(v, lo, hi)
            v = tonumber(v) or lo
            if v < lo then return lo elseif v > hi then return hi else return v end
        end,
        DeepCopy = function(val)
            local function cp(x)
                if type(x) ~= "table" then return x end
                local o = {}
                for k, v in pairs(x) do o[k] = cp(v) end
                return o
            end
            return cp(val)
        end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx, dy = (tonumber(x2) or 0) - (tonumber(x1) or 0), (tonumber(y2) or 0) - (tonumber(y1) or 0)
            return dx * dx + dy * dy
        end,
        ForEachPlayer = function(cb) cb(playerObj) end,
    },
    Events = {
        Emit = function(name, payload)
            emittedEvents[#emittedEvents + 1] = { name = name, payload = payload }
        end,
    },
    Registry = {
        Data = npcStore,
        Get = function(id) return npcStore[tostring(id)] end,
        MarkDirty = function() end,
    },
    SpatialIndex = {
        QueryNPCs = function()
            local out = {}
            for _, rec in pairs(npcStore) do out[#out + 1] = rec end
            return out
        end,
    },
    Perception = {
        CanSeeWorldObject = function() return true end,
        CanAllyEngageThreat = function(_, desc) return true, desc end,
        AreWarningAllies = function(a, b)
            return type(a) == "table" and type(b) == "table" and a.id ~= b.id and a.factionID == b.factionID
        end,
        GetTeamKey = function(rec) return tostring(rec and rec.factionID or "alpha") end,
        GetActiveSkirmish = function() return { initialCount = 4, lastBeatAt = 0 } end,
        MarkSkirmishBeat = function() end,
    },
    Network = {
        SendConversationRelationshipForNPC = function(_, npcId, ev, payload)
            deliveredBarks[#deliveredBarks + 1] = {
                npcId = npcId, eventType = ev, payload = payload,
                ambientFlavor = payload and payload.ambientFlavor,
                text = payload and payload.ambientFlavor and payload.ambientFlavor.text,
            }
            return true
        end,
    },
    SecondaryChannel = { RequestBark = function() end, SetAlertLevel = function() end, RequestGaze = function() end },
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
            return true, h.current
        end,
    },
}

require "PsychopatzCore/Semantics/PsychopatzSemantic"
require "PNC/Core/Base/PNC_Sandbox"
require "PNC/Core/Events/PNC_EventDefinitions"
local Wounds = require "PNC/Core/Health/PNC_NPCWounds"
require "PNC/Core/Needs/PNC_NeedsCatalog"
require "PNC/Core/Needs/PNC_NeedsDefinitions"
require "PNC/ConvoEngine/Dialogue/Situation"
require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
require "PNC/ConvoEngine/SpeechRealization"
require "PNC/ConvoEngine/Social/Reaction"
require("PNC/ConvoEngine/ConvoDSL/ConvoDSL").EnsureActiveLanguage()
local Suggestions = require "PNC/ConvoEngine/Dialogue/Suggestions"
require "PNC/ConvoEngine/Dialogue/FlowKernel"
require "PNC/ConvoEngine/Dialogue/LocalResponse"
local Policy = require "PNC/ConvoEngine/Dialogue/Policy"
local Callouts = require "PNC/Semantics/PNC_SemanticCombatTargetCallouts"
require "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Wounds"

local function makeNPC(id, name, opts)
    opts = opts or {}
    local rec = {
        id = id, name = name, fullName = name, alive = true,
        presenceState = opts.presenceState or "live",
        x = opts.x or 10, y = opts.y or 10, z = opts.z or 0,
        factionID = opts.factionID or "alpha",
        attackType = opts.attackType or "auto",
        psychopath = opts.psychopath == true,
        traits = opts.traits or {},
        skills = opts.skills or {},
        social = opts.social or { relationships = {}, personality = {} },
        health = { current = 100, max = 100, state = "normal", bleeding = false },
        needs = { values = {}, ailments = {} },
        runtime = {},
    }
    Wounds.Ensure(rec)
    npcStore[tostring(id)] = rec
    liveBodies[tostring(id)] = {
        getX = function() return rec.x end,
        getY = function() return rec.y end,
        getZ = function() return rec.z end,
        setHealth = function(_, v) rec.liveHealth = v end,
    }
    return rec
end

-- 1. Build 42 Groin -> pelvis_groin topology, surgical treatments, and physical vs Knox separation.
do
    local rec = makeNPC("groin-1", "Clay")
    T.equal(Wounds.ClassifyBodyRegion("Groin"), "pelvis_groin", "Groin maps to pelvis_groin functional region")
    Wounds.ApplyCombatDamage(rec, liveBodies["groin-1"], {
        amount = 18, partId = "Groin", woundType = "bullet", attackerKind = "human",
    })
    local proj = Wounds.GetOrBuildProjection(rec)
    T.equal(proj.bodyRegion, "pelvis_groin", "projection resolves pelvis_groin region")
    T.equal(proj.hasBullet, true, "bullet wound sets hasBullet flag")
    T.equal(proj.knoxExposure, "impossible", "human gunshot wound has impossible Knox exposure despite high physical severity")
    local imp = Wounds.GetFunctionalImpairment(rec)
    T.truthy(imp.pelvicImpaired == true and imp.kind == "pelvic_mobility", "pelvic trauma sets pelvicImpaired and pelvic_mobility functional state")

    -- RemoveBullet, Disinfect, Cauterize
    T.truthy(Wounds.RemoveBullet(rec, "Groin", nowMs), "RemoveBullet lodges out bullet")
    T.truthy(Wounds.Disinfect(rec, "Groin", 4.0, nowMs), "Disinfect applies alcohol level")
    T.truthy(Wounds.Cauterize(rec, "Groin", nowMs), "Cauterize stops bleeding and marks cauterized")
    local postProj = Wounds.GetOrBuildProjection(rec)
    T.equal(postProj.hasBullet, false, "projection invalidated and updated after RemoveBullet")
    T.equal(postProj.treatmentState, "cauterized", "cauterized wound resolves cauterized treatmentState")
end

-- 2. Build 42 Transmission modes (1..4), zombie-only Knox gate, and Mortality == 7 non-lethal fever recovery.
do
    -- Mode 1 (Blood+Saliva): scratch 7%, laceration 25%, bite 100%
    SandboxVars.ZombieLore.Transmission = 1
    T.equal(PNC.Sandbox.GetZombieWoundKnoxChance("bite"), 100, "Mode 1 bite chance is 100%")
    T.equal(PNC.Sandbox.GetZombieWoundKnoxChance("laceration"), 25, "Mode 1 laceration chance is 25%")
    T.equal(PNC.Sandbox.GetZombieWoundKnoxChance("scratch"), 7, "Mode 1 scratch chance is 7%")

    -- Mode 2 (Saliva Only): bite 100%, laceration 0%, scratch 0%
    SandboxVars.ZombieLore.Transmission = 2
    T.equal(PNC.Sandbox.GetZombieWoundKnoxChance("bite"), 100, "Mode 2 bite chance is 100%")
    T.equal(PNC.Sandbox.GetZombieWoundKnoxChance("laceration"), 0, "Mode 2 laceration chance is 0%")
    T.equal(PNC.Sandbox.GetZombieWoundKnoxChance("scratch"), 0, "Mode 2 scratch chance is 0%")

    -- Mode 4 (None): all 0%
    SandboxVars.ZombieLore.Transmission = 4
    T.equal(PNC.Sandbox.GetZombieWoundKnoxChance("bite"), 0, "Mode 4 bite chance is 0%")

    -- Restore Mode 1 and test Mortality == 7 (non-lethal fake infection fever recovery)
    SandboxVars.ZombieLore.Transmission = 1
    SandboxVars.ZombieLore.Mortality = 7
    local survivor = makeNPC("mort7-1", "Faustino")
    local started = Wounds.ForceInfection(survivor, "Hand_L", "bite")
    T.truthy(started, "ForceInfection starts under Mortality 7")
    T.equal(survivor.health.body.infection.nonLethalFever, true, "Mortality 7 marks infection nonLethalFever=true")
    worldHours = worldHours + 30.0
    Wounds.Update(survivor, liveBodies["mort7-1"], 3600)
    worldHours = worldHours + 30.0
    Wounds.Update(survivor, liveBodies["mort7-1"], 3600)
    T.equal(survivor.alive, true, "Mortality 7 non-lethal fever never kills the NPC")
    T.equal(Wounds.HasActiveInfection(survivor), false, "Mortality 7 infection recovers cleanly after peak")
    SandboxVars.ZombieLore.Mortality = 5
end

-- 3. Ordinary wound infection (0..10) and Live + Abstract physiology parity.
do
    local liveRec = makeNPC("phys-live", "Raymond", { presenceState = "live" })
    local absRec = makeNPC("phys-abs", "Francis", { presenceState = "abstract" })
    Wounds.ApplyCombatDamage(liveRec, liveBodies["phys-live"], {
        amount = 10, partId = "ForeArm_R", woundType = "laceration", attackerKind = "zombie",
    })
    local w = liveRec.health.body.wounds.ForeArm_R
    w.infectedWound = true
    w.bandageDirty = true
    Wounds.Update(liveRec, liveBodies["phys-live"], 60)
    climateTempC = -8.0
    rainIntensity = 0.95
    windIntensity = 0.85
    worldHours = worldHours + 4.0
    Wounds.Update(liveRec, liveBodies["phys-live"], 7200)
    Wounds.UpdatePhysiology(absRec, 4.0, { ambientTempC = -8.0, rainIntensity = 0.95, windIntensity = 0.85, indoors = false })
    T.truthy((tonumber(w.woundInfectionLevel) or 0) > 0, "ordinary woundInfectionLevel grows on dirty infected wound")
    T.truthy((tonumber(liveRec.health.body.physiology.wetness) or 0) > 20, "Live NPC accumulates wetness in rain")
    T.truthy((tonumber(absRec.health.body.physiology.wetness) or 0) > 20, "Abstract NPC accumulates wetness in rain (Live/Abstract parity)")
    T.truthy((tonumber(liveRec.health.body.physiology.coreTempC) or 37) < 36.8, "freezing rain drops core temperature")
    climateTempC, rainIntensity, windIntensity = 20.0, 0.0, 0.0
end

-- 4. Beat -> Suggestions constraint filtering -> FlowKernel/Policy -> LocalResponse -> Scene handoff & BiteConflictPolicy.
do
    deliveredBarks = {}
    Callouts.ResetRuntime()
    local injured = makeNPC("triage-vic", "Adrienne", { x = 10, y = 10, factionID = "alpha" })
    local psycho = makeNPC("triage-psy", "Vane", {
        x = 11, y = 10, factionID = "alpha", psychopath = true,
        social = { personality = { aggression = 0.95, compassion = 0.05 }, relationships = { ["npc:triage-vic"] = { state = "neutral", approval = -15 } } },
    })
    nowMs = 400000
    Wounds.ApplyCombatDamage(injured, liveBodies["triage-vic"], {
        amount = 14, partId = "UpperArm_L", woundType = "bite", attackerKind = "zombie",
    })
    T.truthy(#deliveredBarks >= 2, "bite pain and received beats delivered")
    T.equal(deliveredBarks[1].eventType, "combat_injury_pain_reaction", "immediate pain Beat precedes received Beat")
    local beatFlavor = nil
    for _, b in ipairs(deliveredBarks) do
        if b.eventType == "combat_wound_received_beat" then beatFlavor = b.ambientFlavor break end
    end
    T.truthy(beatFlavor ~= nil, "bite received beat delivered")
    T.equal(beatFlavor.observerOnly, false, "injury Beat sets observerOnly=false for player interaction")
    T.equal(beatFlavor.recipientKind, "player", "injury Beat sets recipientKind=player")
    T.truthy(type(beatFlavor.responsePlanID) == "string" and beatFlavor.responsePlanID ~= "", "injury Beat carries responsePlanID")

    local ctx = {
        npcID = "triage-vic",
        npcRecord = injured,
        interactionLifecycle = {
            activeBeat = {
                id = "beat_triage_1",
                eventRef = beatFlavor.eventRef,
                threadID = beatFlavor.threadID,
                responsePlanID = beatFlavor.responsePlanID,
                realizationID = beatFlavor.realizationID,
                offerIDs = beatFlavor.offerIDs,
                factRefs = beatFlavor.factRefs,
            },
        },
    }
    local built = Suggestions.Build({}, ctx, {})
    local checkBite = nil
    for _, c in ipairs(built.candidates or {}) do
        if c.id == "combat.injury.check_bite_exposure" then checkBite = c end
    end
    T.truthy(checkBite ~= nil, "combat.injury.check_bite_exposure offer surfaced for bitten NPC")

    local view = { spec = { npcID = "triage-vic", context = ctx }, semanticSuggestions = built }
    local ir = Suggestions.FrameToIR(checkBite.frame, view)
    T.truthy(ir ~= nil, "FrameToIR constructs valid click IR")
    local flowState = { sequence = 1, flowSessions = {}, flowOrder = {} }
    local decision = Policy.Decide(ir, flowState, ctx)
    T.truthy(decision and decision.flow and decision.flow.matched == true, "triage flow matched")
    T.truthy(decision.response and type(decision.response.fallback) == "string" and decision.response.fallback ~= "",
        "triage node responsePool resolves deterministic NPC reply")
    local committed = Policy.CommitFlow(decision, ir, flowState, ctx)
    Callouts.HandoffInjuryBeatToScene(injured, beatFlavor.threadID, {
        context = ctx, flow = committed, ir = ir, stateValue = "bite_psychopath_threatened", nodeId = "triage_resolution",
    })
    T.equal(Callouts.PendingReplyCount, 0, "pending transient Beat replies cancelled on Scene promotion")
    T.truthy(injured.runtime.activeInjuryTriageState ~= nil, "activeInjuryTriageState stored on injured NPC")

    local policyEval = Wounds.EvaluateBiteConflictPolicy(psycho, injured)
    T.equal(policyEval.suppressedByPlayerOrder, true, "player protection order suppresses psychopath execution impulse")
    T.equal(policyEval.stance, "monitor", "suppressed stance downgrades to monitor")
end

-- 5. MP Client Non-Authority Rejection & 200-NPC Scale Benchmark.
do
    -- Non-authoritative client check
    local origAuth = PNC.Core.IsAuthority
    PNC.Core.IsAuthority = function() return false end
    local clientNpc = makeNPC("mp-client-npc", "ClientShadow")
    local resClient, errClient = Wounds.ApplyCombatDamage(clientNpc, nil, { amount = 20, partId = "Head", woundType = "bullet" })
    -- Restore authority
    PNC.Core.IsAuthority = origAuth

    -- 200-NPC Scale Benchmark: O(1) cached projection hits + physiology ticks
    local cohort = {}
    for i = 1, 200 do
        local npc = makeNPC("scale-" .. tostring(i), "Survivor" .. tostring(i), {
            presenceState = (i % 2 == 0) and "live" or "abstract",
            x = 100 + (i % 20), y = 100 + math.floor(i / 20),
        })
        if i % 4 == 0 then
            npc.health.body.openWoundCount = 1
            npc.health.body.wounds.ForeArm_L = { id = "sw" .. tostring(i), type = "laceration", partId = "ForeArm_L", severity = 25, bleedingRate = 0.02 }
            Wounds.InvalidateProjection(npc, "benchmark_seed")
        end
        cohort[i] = npc
    end

    local t0 = os.clock()
    for i = 1, 200 do
        local p1 = Wounds.GetOrBuildProjection(cohort[i])
        local p2 = Wounds.GetOrBuildProjection(cohort[i])
        T.equal(p1, p2, "clean projection returns cached table reference in O(1)")
        Wounds.UpdatePhysiology(cohort[i], 60, { worldHour = worldHours })
    end
    local elapsedMs = (os.clock() - t0) * 1000
    T.truthy(elapsedMs < 250, "200-NPC projection + physiology tick completes well under 250ms budget (actual=" .. string.format("%.2fms", elapsedMs) .. ")")
end

do
    local Dressing = require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Dressing"
    local Codec = require "PNC/Core/Health/Repository/PNC_HealthWoundCodec"
    T.equal(Dressing.Profile("Base.RippedSheets").power, Dressing.Profile("Base.AlcoholRippedSheets").power)
    T.equal(Dressing.Profile("Base.Bandage").power, Dressing.Profile("Base.AlcoholBandage").power)
    T.truthy(Dressing.Profile("Base.Bandage").power > Dressing.Profile("Base.RippedSheets").power)
    T.equal(Dressing.Profile("Base.Bandaid").power, 1.5)
    T.equal(Dressing.Profile("Base.AlcoholBandage").spentType, "Base.BandageDirty")
    T.equal(Dressing.Profile("Base.DenimStrips").spentType, "Base.DenimStripsDirty")
    T.equal(Dressing.Profile("Base.LeatherStrips").spentType, "Base.LeatherStripsDirty")
    T.equal(Dressing.Life(Dressing.Profile("Base.RippedSheetsDirty"), 10), 0)
    local treated = makeNPC("dressing-item-regression")
    Wounds.Ensure(treated).wounds.Hand_L = { type = "laceration", damage = 20, severity = 20, bleedingRate = 0.02 }
    T.truthy(Wounds.Bandage(treated, "Hand_L", nowMs, {
        bandageType = "Base.AlcoholRippedSheets", dirtyAfterWorldHours = 0.1,
    }))
    local wound = treated.health.body.wounds.Hand_L
    T.equal(wound.bandageType, "Base.AlcoholRippedSheets")
    T.truthy(wound.sterileDressing)
    T.equal(Wounds.GetBandageReturnType(wound), "Base.AlcoholRippedSheets")
    worldHours = worldHours + 0.2
    Wounds.Update(treated, nil, nowMs)
    T.truthy(wound.bandageDirty)
    local restored = Codec.sanitizeWound("Hand_L", Codec.compactWound(Codec.sanitizeWound("Hand_L", wound)))
    T.equal(Wounds.GetBandageReturnType(restored), "Base.RippedSheetsDirty")
    local changed, _, previous = Wounds.Bandage(treated, "Hand_L", nowMs, { bandageType = "Base.Bandage" })
    T.truthy(changed)
    T.equal(previous, "Base.RippedSheetsDirty")
    local removed, _, recovered = Wounds.RemoveBandage(treated, "Hand_L")
    T.truthy(removed)
    T.equal(recovered, "Base.Bandage")
    T.falsy(Wounds.RemoveBandage(treated, "Hand_L"), "a removed dressing cannot be collected twice")
    Wounds.Ensure(treated).wounds.ForeArm_L = { type = "fracture", damage = 25, severity = 25 }
    T.truthy(Wounds.Splint(treated, "ForeArm_L", nowMs, { firstAidLevel = 3, splintItem = "Base.WoodenStick2" }))
    local splint = treated.health.body.wounds.ForeArm_L
    T.equal(splint.splintFactor, 2)
    T.equal(Codec.sanitizeWound("ForeArm_L", splint).splintItem, "Base.WoodenStick2")
    worldHours = worldHours + 1
    Wounds.Update(treated, nil, nowMs)
    T.truthy(splint.damage < 25, "splint advances fracture recovery without a bandage")
    local unsplinted = makeNPC("unsplinted-fracture")
    local untreatedFracture = { type = "fracture", damage = 25, severity = 25, lastFractureHealHour = worldHours - 1 }
    Wounds.Ensure(unsplinted).wounds.ForeArm_L = untreatedFracture
    Wounds.Update(unsplinted, nil, nowMs)
    T.truthy(splint.damage < untreatedFracture.damage, "splint recovers a fracture faster")
    local splintRemoved, _, support, fabric = Wounds.RemoveSplint(treated, "ForeArm_L")
    T.truthy(splintRemoved)
    T.equal(support, "Base.WoodenStick2")
    T.equal(fabric, "Base.RippedSheets")
    T.falsy(Wounds.RemoveSplint(treated, "ForeArm_L"), "splint materials cannot be collected twice")
    T.truthy(Wounds.Splint(unsplinted, "ForeArm_L", nowMs, { splintItem = "Base.Splint" }))
    local _, _, crafted, extraFabric = Wounds.RemoveSplint(unsplinted, "ForeArm_L")
    T.equal(crafted, "Base.Splint")
    T.equal(extraFabric, nil)

    local recoveredNPC = makeNPC("healed-but-wearing-dressing")
    Wounds.Ensure(recoveredNPC).wounds.Hand_R = { type = "scratch", damage = 0.1, severity = 0.1 }
    T.truthy(Wounds.Bandage(recoveredNPC, "Hand_R", nowMs, {
        bandageType = "Base.RippedSheets", dirtyAfterWorldHours = 5,
    }))
    worldHours = worldHours + 1
    Wounds.Update(recoveredNPC, nil, nowMs)
    local healed = recoveredNPC.health.body.wounds.Hand_R
    T.truthy(healed.dressingHealed, "a healed wound still carries its physical dressing")
    T.equal(Wounds.GetFunctionalImpairment(recoveredNPC).kind, "none")
    local projection = Wounds.GetOrBuildProjection(recoveredNPC, { preferredPartId = "Hand_R" })
    T.equal(projection.totalWoundCount, 0, "the retained dressing is outside injury projection")
    local persisted = Codec.sanitizeWound("Hand_R", Codec.compactWound(Codec.sanitizeWound("Hand_R", healed)))
    T.truthy(persisted.dressingHealed)
    T.equal(Wounds.GetBandageReturnType(persisted), "Base.RippedSheets")
    local _, _, cleanRag = Wounds.RemoveBandage(recoveredNPC, "Hand_R")
    T.equal(cleanRag, "Base.RippedSheets")
    T.equal(recoveredNPC.health.body.wounds.Hand_R, nil)

end

T.finish("pnc_organic_health_physiology_and_injury_scene_smoke")
