-- Smoke test for cause-agnostic PNC.BehaviorSuicide pipeline:
-- native BehaviorSystem ownership (victim + witness ticks), O(1) idle fast-path,
-- built-in knox_critical cause (>= 90%, loaded handgun/rifle, headshot no-reanim),
-- trait/stat probability, gender-aware pronouns, and custom event-driven causes
-- (e.g. family loss) via RegisterCause + TryTrigger.

local T = require "tests/support/test"

T.addPackagePaths()

PNC = PNC or {}
PNC.Const = { PRESENCE_LIVE = "live" }
PNC.Semantics = PNC.Semantics or {}
PNC.Core = {
    Now = function() return 10000 end,
    IsAuthority = function() return true end,
}

local Catalog = require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
local ConvoDSL = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL"
T.load(T.path("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticSpeechPerformance_Cues.lua"))
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/Behaviors/PNC_Behavior_Suicide.lua"))

local Suicide = PNC.BehaviorSuicide
local Cues = PNC.Semantics.SpeechPerformance

-- 1. Load EN ConvoBlocks (including knox_virus.convo) with zero errors
local diag = ConvoDSL.Reload("EN")
T.equal(#(diag.errors or {}), 0,
    "EN ConvoBlocks must load with zero errors: " .. table.concat(diag.errors or {}, "; "))

local pool = Catalog.Get("semantic.companion.need_request")
T.truthy(pool and type(pool.variants) == "table", "semantic.companion.need_request pool must exist")

local function whenMatches(cond, expected)
    if cond == nil then return false end
    if type(cond) == "string" then return cond == expected end
    if type(cond) == "table" then
        if cond.eq == expected or cond.value == expected then return true end
        if cond[expected] == true then return true end
        for _, v in ipairs(cond) do
            if v == expected then return true end
        end
    end
    return false
end

local function resolveCompiledLine(role, style, tokens)
    local fallback = nil
    for _, cand in ipairs(pool.variants or {}) do
        local conds = cand.when or {}
        if whenMatches(conds.combatReactionRole or conds.role, role) then
            local styleCond = conds.socialStyle or conds["actor.social_style"]
            local line = cand.fallback or cand.text
            if line then
                if styleCond and style and whenMatches(styleCond, style) then
                    return (string.gsub(line, "{([%w_%.]+)}", function(k) return tostring(tokens[k] or ("{" .. k .. "}")) end))
                elseif not styleCond then
                    fallback = line
                end
            end
        end
    end
    if fallback then
        return (string.gsub(fallback, "{([%w_%.]+)}", function(k) return tostring(tokens[k] or ("{" .. k .. "}")) end))
    end
    return nil
end

for _, role in ipairs({
    "suicide_resolve",
    "suicide_resolve_solo",
    "suicide_intervene",
    "suicide_insist",
    "suicide_comply",
    "suicide_mourn",
    "suicide_mourn_chime",
}) do
    local sample = resolveCompiledLine(role, "warm", {
        ["addressee.name"] = "Marcus",
        ["victim.name"] = "Elena",
        ["victim.subj"] = "she",
        ["victim.Subj"] = "She",
        ["victim.obj"] = "her",
        ["victim.poss"] = "her",
        ["slot.weapon"] = "pistol",
    })
    T.truthy(sample and sample ~= "", "missing ConvoDSL line for role=" .. role)
    T.falsy(string.find(sample, "{", 1, true), "unresolved token leaked in role=" .. role .. ": " .. tostring(sample))
    T.truthy(Cues.ResolveCue({ poolID = "semantic.companion.need_request", role = role }),
        "missing SpeechPerformance cue for role=" .. role)
end

-- 2. Gender-aware pronouns
local femaleTokens = Suicide.BuildPronounTokens({ name = "Elena", isFemale = true })
T.equal(femaleTokens["victim.subj"], "she", "female subject pronoun mismatch")
T.equal(femaleTokens["victim.Subj"], "She", "female capitalized subject pronoun mismatch")
T.equal(femaleTokens["victim.obj"], "her", "female object pronoun mismatch")
T.equal(femaleTokens["victim.poss"], "her", "female possessive pronoun mismatch")
T.equal(femaleTokens["victim.refl"], "herself", "female reflexive pronoun mismatch")

local maleTokens = Suicide.BuildPronounTokens({ name = "Marcus", isFemale = false })
T.equal(maleTokens["victim.subj"], "he", "male subject pronoun mismatch")
T.equal(maleTokens["victim.Subj"], "He", "male capitalized subject pronoun mismatch")
T.equal(maleTokens["victim.obj"], "him", "male object pronoun mismatch")
T.equal(maleTokens["victim.poss"], "his", "male possessive pronoun mismatch")
T.equal(maleTokens["victim.refl"], "himself", "male reflexive pronoun mismatch")

-- 3. Firearm & ammo gating
T.falsy(Suicide.FindFirearm({ id = "n1", equipment = { primaryFullType = "Base.Hammer" } }),
    "melee weapon must not qualify")
T.falsy(Suicide.FindFirearm({
    id = "n_shells",
    inventory = { items = { s1 = { type = "Base.ShotgunShells", count = 12 } } },
}), "Base.ShotgunShells ComboItem must never be misclassified as a firearm")
T.falsy(Suicide.FindFirearm({
    id = "n_clip",
    inventory = { items = { c1 = { type = "Base.9mmClip", count = 1 } } },
}), "magazine/clip must never be misclassified as a firearm")
T.falsy(Suicide.FindFirearm({
    id = "n2",
    equipment = { primary = { fullType = "Base.Pistol", isRanged = true, currentAmmoCount = 0 } },
}), "empty firearm must not qualify")
local loadedPistol = Suicide.FindFirearm({
    id = "n3",
    equipment = { primary = { fullType = "Base.Pistol", isRanged = true, currentAmmoCount = 3 } },
})
T.truthy(loadedPistol and loadedPistol.kind == "handgun", "loaded pistol must classify as handgun")
local loadedRifle = Suicide.FindFirearm({
    id = "n4",
    equipment = { primary = { fullType = "Base.HuntingRifle", isRanged = true, currentAmmoCount = 2 } },
})
T.truthy(loadedRifle and loadedRifle.kind == "rifle", "loaded hunting rifle must classify as rifle")

-- Autonomous NPC (unlimited reserve) whose IsoZombie HandWeapon reports 0 ammo before first shot
PNC.Firearms = {
    HasUnlimitedReserve = function(rec) return rec.recruited ~= true end,
}
local strangerZeroAmmoGun = Suicide.FindFirearm({
    id = "stranger_1",
    recruited = false,
    equipment = { primary = { fullType = "Base.Pistol", isRanged = true, currentAmmoCount = 0 } },
})
T.truthy(strangerZeroAmmoGun and strangerZeroAmmoGun.kind == "handgun",
    "autonomous NPC with unlimited reserve must qualify even when live HandWeapon ammo is 0")

-- Canonical persistent inventory map (record.inventory.items)
local mapInvGun = Suicide.FindFirearm({
    id = "inv_map_1",
    recruited = true,
    inventory = {
        items = {
            item_1 = { type = "Base.Revolver_Short", ammoCount = 4 },
        },
    },
})
T.truthy(mapInvGun and mapInvGun.kind == "handgun" and mapInvGun.weaponLabel == "revolver",
    "record.inventory.items map must be scanned for firearms")
PNC.Firearms = nil

-- 4. Trait & stat probability scaling
local braveChance = Suicide.ComputeChance({
    traits = { "iron_nerves", "protective" },
    personality = { courage = 0.85, altruism = 0.85 },
    needs = { stress = 0.80, pain = 0.80 },
}, { baseChance = 0.25, urgency = 0.5, hasWitness = true })

local timidChance = Suicide.ComputeChance({
    traits = { "cowardly", "hardy" },
    personality = { courage = 0.20, altruism = 0.20 },
    needs = { stress = 0.10, pain = 0.10 },
}, { baseChance = 0.25, urgency = 0.0, hasWitness = false })

T.truthy(braveChance > timidChance + 0.30, "brave/altruistic/stressed NPC should have much higher chance")

-- 5. Full native BehaviorSystem ownership flow for knox_critical (>= 90%)
local delivered = {}
local animRequests = {}
local clearedInfections = {}
local killedRecords = {}
local soundsPlayed = {}
local bloodSplats = 0

local fakePistol = {
    fullType = "Base.Pistol",
    isRanged = function() return true end,
    getFullType = function() return "Base.Pistol" end,
    getCurrentAmmoCount = function(self) return self._ammo end,
    setCurrentAmmoCount = function(self, n) self._ammo = n end,
    isRoundChambered = function() return false end,
    getSwingSound = function() return "M9Shoot" end,
    getSoundRadius = function() return 50 end,
    getSoundVolume = function() return 80 end,
    _ammo = 4,
}

local victimBody = {
    isFemale = function() return true end,
    getPrimaryHandItem = function() return fakePistol end,
    playSound = function(_, snd) soundsPlayed[#soundsPlayed + 1] = snd end,
    addWorldSoundUnlessInvisible = function() end,
    splatBloodFloorBig = function() bloodSplats = bloodSplats + 1 end,
}

local victim = {
    id = "npc_elena",
    name = "Elena",
    isFemale = true,
    alive = true,
    presenceState = "live",
    x = 10, y = 10, z = 0,
    groupId = "grp_1",
    zombie = victimBody,
    traits = { "iron_nerves", "protective" },
    health = {
        state = "normal",
        body = {
            infection = { active = true, progress = 0.93, stage = "terminal" },
        },
    },
}

local witness1 = {
    id = "npc_marcus",
    name = "Marcus",
    isFemale = false,
    alive = true,
    presenceState = "live",
    x = 12, y = 10, z = 0,
    groupId = "grp_1",
    needs = { stress = 0.1 },
    socialStyle = "warm",
}

local witness2 = {
    id = "npc_sara",
    name = "Sara",
    isFemale = true,
    alive = true,
    presenceState = "live",
    x = 13, y = 11, z = 0,
    groupId = "grp_1",
    needs = { stress = 0.1 },
    socialStyle = "warm",
}

local registryList = { victim, witness1, witness2 }
PNC.Registry = {
    ForEach = function(fn)
        for _, r in ipairs(registryList) do fn(r) end
    end,
    Get = function(id)
        for _, r in ipairs(registryList) do
            if tostring(r.id) == tostring(id) then return r end
        end
        return nil
    end,
}

PNC.Semantics.SpeechTransport = {
    ResolveLine = function(speaker, req)
        local line = resolveCompiledLine(req.role, speaker.socialStyle or "warm", req.tokens or {})
        return line, { realizationID = "test." .. tostring(req.role), poolID = req.poolID }
    end,
    Deliver = function(speaker, now, payload)
        delivered[#delivered + 1] = {
            speakerId = speaker.id,
            role = payload.context and payload.context.beatRole,
            text = payload.text,
            now = now,
        }
        return 1
    end,
}

PNC.AnimationScenes = {
    Request = function(rec, body, sceneId, opts)
        animRequests[#animRequests + 1] = { npcId = rec.id, sceneId = sceneId, props = opts and opts.props }
        return true
    end,
}

PNC.NPCWounds = {
    ClearInfection = function(rec, reason)
        clearedInfections[#clearedInfections + 1] = { npcId = rec.id, reason = reason }
        rec.health.body.infection = nil
        return true
    end,
}

PNC.Health = {
    Kill = function(rec, body, reason)
        rec.alive = false
        rec.deathReason = reason
        killedRecords[#killedRecords + 1] = { npcId = rec.id, reason = reason }
        return true
    end,
}

-- t = 10000: Native per-NPC BehaviorSystem tick triggers knox_critical
T.truthy(Suicide.Tick(victim, victimBody, 10000, { forceEval = true, rollFn = function() return 0.01 end }),
    "Suicide.Tick must claim behavior ownership when triggered")
T.equal(delivered[1].role, "suicide_resolve", "Phase 1 must emit suicide_resolve")
T.truthy(witness1.runtime and witness1.runtime.suicideWitness ~= nil, "primary witness must be bound")
T.truthy(witness2.runtime and witness2.runtime.suicideWitness ~= nil, "secondary witness must be bound")

-- Witnesses hold behavior ownership while watching
T.truthy(Suicide.Tick(witness1, nil, 11000), "witness must hold ownership during sequence")
T.equal(witness1.activeJob, "SuicideWitness", "witness activeJob must be SuicideWitness")

-- Phase 2 -> 3 -> 4 -> 5 -> 6 via victim's native behavior tick
Suicide.Tick(victim, victimBody, 12300)
T.equal(delivered[2].role, "suicide_intervene", "Phase 2 must emit suicide_intervene")
T.equal(delivered[2].speakerId, "npc_marcus", "primary witness intervenes")

Suicide.Tick(victim, victimBody, 14600)
T.equal(delivered[3].role, "suicide_insist", "Phase 3 must emit suicide_insist")

Suicide.Tick(victim, victimBody, 16700)
T.equal(delivered[4].role, "suicide_comply", "Phase 4 must emit suicide_comply")

Suicide.Tick(victim, victimBody, 18600)
T.equal(#animRequests, 1, "Phase 5 must request suicide animation scene")
T.truthy(string.find(animRequests[1].sceneId, "^suicide%.handgun"), "must play handgun suicide scene")

Suicide.Tick(victim, victimBody, 19500)
T.equal(#soundsPlayed, 1, "must play gunshot sound")
T.equal(bloodSplats, 1, "must splat blood")
T.equal(fakePistol._ammo, 3, "must consume 1 round")
T.equal(#clearedInfections, 1, "knox_critical onBeforeKill must clear infection")
T.equal(victim.alive, false, "victim must be dead")
T.equal(killedRecords[1].reason, "knox_suicide", "deathReason must be knox_suicide")

-- Even after victim is dead & retired, witnesses mourn on their OWN native BehaviorSystem ticks!
Suicide.Tick(witness1, nil, 21400)
T.equal(delivered[5].role, "suicide_mourn", "primary witness must mourn on its own tick")
T.truthy(string.find(delivered[5].text, "Elena", 1, true), "mourn line must name victim")
T.truthy(string.find(string.lower(delivered[5].text), "she", 1, true), "mourn line must use female pronoun 'she'")
T.falsy(witness1.runtime.suicideWitness, "primary witness ownership must release after mourning")
T.truthy(witness1.needs.stress > 0.25, "witness stress should increase from grief")

Suicide.Tick(witness2, nil, 23100)
T.equal(delivered[6].role, "suicide_mourn_chime", "secondary witness must chime mourn on its own tick")
T.falsy(witness2.runtime.suicideWitness, "secondary witness ownership must release after mourning")

-- 6. Agnostic extensibility: custom event-driven cause (e.g., family member loss) without Knox infection
T.truthy(Suicide.RegisterCause("family_loss_test", {
    priority = 80,
    baseChance = 0.40,
    deathReason = "grief_suicide",
}), "custom cause must register cleanly")

local grievingNpc = {
    id = "npc_grief",
    name = "David",
    isFemale = false,
    alive = true,
    presenceState = "live",
    x = 50, y = 50, z = 0,
    equipment = { primary = { fullType = "Base.HuntingRifle", isRanged = true, currentAmmoCount = 2 } },
    health = { state = "normal", body = {} }, -- NOT infected with Knox!
}

local okTrigger = Suicide.TryTrigger(grievingNpc, nil, "family_loss_test", {
    now = 30000,
    urgency = 0.9,
    force = true,
})
T.truthy(okTrigger, "event-driven TryTrigger must work for non-Knox custom causes")
T.equal(grievingNpc.runtime.suicideState.causeId, "family_loss_test", "state must record custom causeId")
T.equal(grievingNpc.runtime.suicideState.sceneId, "suicide.rifle", "rifle must pick suicide.rifle scene")

-- Execute & kill through custom cause without touching Knox wounds
Suicide.Tick(grievingNpc, nil, 32500) -- execute
Suicide.Tick(grievingNpc, nil, 34000) -- shot_kill
T.equal(grievingNpc.alive, false, "custom cause must execute kill")
T.equal(grievingNpc.deathReason, "grief_suicide", "custom cause deathReason must be preserved")
T.equal(#clearedInfections, 1, "non-Knox cause must not invoke Knox ClearInfection hook")

Suicide.UnregisterCause("family_loss_test")

-- 7. Dedicated SuicideAudit channel: zero logs when disabled, structured logs when enabled
local auditLogs = {}
PNC.PerformanceScalingDiagnostics = {
    SuicideAuditEnabled = false,
    LogSuicideAudit = function(ev, fields)
        auditLogs[#auditLogs + 1] = { event = ev, fields = fields }
        return true
    end,
}
local auditNpc = {
    id = "npc_audit",
    name = "Alex",
    alive = true,
    presenceState = "live",
    equipment = { primaryFullType = "Base.Hammer" },
}
Suicide.TryTrigger(auditNpc, nil, "knox_critical", { now = 40000 })
T.equal(#auditLogs, 0, "SuicideAudit must emit zero logs when disabled")

PNC.PerformanceScalingDiagnostics.SuicideAuditEnabled = true
Suicide.TryTrigger(auditNpc, nil, "knox_critical", { now = 40100 })
T.equal(#auditLogs, 1, "SuicideAudit must log eval_skip when enabled")
T.equal(auditLogs[1].event, "eval_skip", "audit event name must be eval_skip")

-- 8. CompanionAmmoRealismEnabled: respects GetMagazineState and consumes bullet via PrepareShot
local companionPreparedShots = 0
PNC.Firearms = {
    HasUnlimitedReserve = function() return false end,
    UsesInventoryAmmo = function() return true end,
    GetMagazineState = function(rec)
        return {
            ammoNotRequired = false,
            unlimitedReserve = false,
            count = rec._magCount or 0,
            looseAmmo = rec._looseAmmo or 0,
            ammoType = "Base.Bullets9mm",
            itemID = "gun_1",
        }
    end,
    PrepareShot = function(rec)
        if (rec._magCount or 0) > 0 then
            rec._magCount = rec._magCount - 1
            companionPreparedShots = companionPreparedShots + 1
            return true, "round_consumed", { count = rec._magCount }
        end
        return false, "out_of_ammo"
    end,
}

local dryCompanion = {
    id = "comp_dry",
    recruited = true,
    alive = true,
    presenceState = "live",
    _magCount = 0,
    _looseAmmo = 0,
    equipment = { primary = { fullType = "Base.Pistol", isRanged = true } },
}
T.falsy(Suicide.FindFirearm(dryCompanion),
    "companion with ammo realism ON and 0 mag + 0 loose ammo must be rejected")

local loadedCompanion = {
    id = "comp_loaded",
    name = "Sam",
    recruited = true,
    alive = true,
    presenceState = "live",
    x = 80, y = 80, z = 0,
    _magCount = 2,
    _looseAmmo = 0,
    equipment = { primary = { fullType = "Base.Pistol", isRanged = true } },
    health = { state = "normal", body = { infection = { active = true, progress = 0.95 } } },
}
T.truthy(Suicide.TryTrigger(loadedCompanion, nil, "knox_critical", { now = 50000, force = true }),
    "companion with ammo realism ON and loaded mag must trigger")
Suicide.Tick(loadedCompanion, nil, 52500) -- execute
Suicide.Tick(loadedCompanion, nil, 53500) -- shot_kill
T.equal(companionPreparedShots, 1, "suicide shot must consume 1 bullet via PNC.Firearms.PrepareShot")
T.equal(loadedCompanion._magCount, 1, "companion magazine must decrement by 1 round")
PNC.Firearms = nil

-- 9. FirearmEffects.Emit + Build 42 gun ragdoll settle before final IsoDeadBody kill
local fxEmits = 0
PNC.FirearmEffects = {
    Emit = function(rec, shooter, target, weaponItem)
        fxEmits = fxEmits + 1
        return true, { shotId = "test_shot" }
    end,
}
local ragdollActive = false
local hitCalled = false
local ragdollWeapon = { fullType = "Base.Pistol", isRanged = function() return true end }
local ragdollBody = {
    getPrimaryHandItem = function() return ragdollWeapon end,
    setBumpType = function() end,
    setUseless = function() end,
    setHitReaction = function() end,
    setHitForce = function() end,
    setHitFromBehind = function() end,
    setHealth = function() end,
    splatBloodFloorBig = function() end,
    Hit = function()
        hitCalled = true
        ragdollActive = true
    end,
    isRagdollSimulationActive = function() return ragdollActive end,
    isDead = function() return false end,
}
local ragdollNpc = {
    id = "npc_ragdoll",
    name = "Rick",
    alive = true,
    presenceState = "live",
    x = 90, y = 90, z = 0,
    zombie = ragdollBody,
    health = { state = "normal", body = { infection = { active = true, progress = 0.95 } } },
}
T.truthy(Suicide.TryTrigger(ragdollNpc, ragdollBody, "knox_critical", { now = 60000, force = true }),
    "ragdoll test NPC must trigger")
Suicide.Tick(ragdollNpc, ragdollBody, 62500) -- execute
Suicide.Tick(ragdollNpc, ragdollBody, 63500) -- shot_kill -> emits FX + starts ragdoll
T.equal(fxEmits, 1, "must emit full gunshot FX via PNC.FirearmEffects.Emit")
T.truthy(hitCalled, "must invoke live body Hit for Build 42 gun ragdoll")
T.equal(ragdollNpc.runtime.suicideState.phase, "ragdoll_settle", "must enter ragdoll_settle phase")
T.equal(ragdollNpc.alive, true, "must wait for ragdoll settle before retiring to static corpse")

-- Ragdoll settles at +600ms -> finalizes kill cleanly
ragdollActive = false
Suicide.Tick(ragdollNpc, ragdollBody, 64100)
T.equal(ragdollNpc.alive, false, "must finalize kill once ragdoll settles")
T.falsy(ragdollNpc.runtime.suicideState, "suicideState must clear after finalizeKill")
PNC.FirearmEffects = nil

-- 10. CombatStance unholster + MP non-authority rejection
local stanceCalls = 0
local equipApplyCalls = 0
PNC.CombatStance = {
    Maintain = function() stanceCalls = stanceCalls + 1; return true end,
    Clear = function() return true end,
}
PNC.Equipment = {
    Apply = function() equipApplyCalls = equipApplyCalls + 1; return true end,
}
local drawNpc = {
    id = "npc_draw",
    name = "Morgan",
    alive = true,
    presenceState = "live",
    x = 95, y = 95, z = 0,
    zombie = ragdollBody,
    equipment = { primary = { fullType = "Base.Pistol", isRanged = true, currentAmmoCount = 3 } },
}
T.truthy(Suicide.TryTrigger(drawNpc, ragdollBody, "knox_critical", { now = 70000, force = true }),
    "TryTrigger must succeed on authority")
T.truthy(stanceCalls >= 1 and equipApplyCalls >= 1,
    "TryTrigger must draw weapon via PNC.CombatStance.Maintain + PNC.Equipment.Apply")

-- Non-authority client must never mutate suicide state
PNC.Core.IsAuthority = function() return false end
local mpOk, mpReason = Suicide.TryTrigger(drawNpc, ragdollBody, "knox_critical", { now = 71000, force = true })
T.falsy(mpOk, "non-authority client must not trigger suicide")
T.equal(mpReason, "not_authority", "non-authority reason mismatch")
PNC.Core.IsAuthority = function() return true end
PNC.CombatStance = nil
PNC.Equipment = nil

T.finish("pnc_knox_critical_suicide_smoke")
