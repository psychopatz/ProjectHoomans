local SHARED = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
local SERVER = "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/Director/"

local function equal(actual, expected, label)
    if actual ~= expected then error((label or "equal") .. ": expected="
        .. tostring(expected) .. " actual=" .. tostring(actual)) end
end
local function truthy(value, label) equal(value == true, true, label) end
local function greater(left, right, label)
    if not (left > right) then error((label or "greater") .. ": "
        .. tostring(left) .. " <= " .. tostring(right)) end
end
local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
end

local worldHour, modData = 200, {}
function isClient() return false end
function isServer() return true end
function getCell() return nil end
function getGameTime() return { getWorldAgeHours = function() return worldHour end } end
Events = { OnInitGlobalModData = { Add = function() end },
    OnSave = { Add = function() end } }
ModData = { getOrCreate = function(key)
    modData[key] = modData[key] or {}; return modData[key]
end }

local factions, playerNearby = {}, false
PNC = {
    Core = { IsAuthority = function() return true end, DeepCopy = copy,
        LogWarn = function() end, Clamp = function(v, a, b)
            return math.max(a, math.min(b, v)) end, Now = function() return 0 end },
    Const = { PRESENCE_LIVE = "live", PRESENCE_CORPSE = "corpse" },
    Registry = { Data = {}, Dirty = {} },
    SpatialIndex = { QueryPlayers = function()
        return playerNearby and { { getX = function() return 0 end,
            getY = function() return 0 end } } or {}
    end, UpdateNPC = function() end },
}
function PNC.Registry.Get(id) return PNC.Registry.Data[id] end
function PNC.Registry.GetLiveZombie() return nil end
function PNC.Registry.MarkDirty(record, reason) PNC.Registry.Dirty[record.id] = reason end
PNC.Factions = {
    Get = function(id) return factions[id] end,
    GetRelation = function(a, b)
        local faction = factions[a]
        return faction and faction.relations and faction.relations[b] or nil
    end,
    IsMobileGroup = function(value) return value and value.mobile ~= nil end,
    OnNPCDeath = function() return true end,
}
PNC.GroupNeeds = {
    Ensure = function(factionOrID)
        local faction = type(factionOrID) == "table" and factionOrID or factions[factionOrID]
        return faction and faction.needs or { hunger = 100, hydration = 100, fatigue = 100 }
    end,
    Restore = function(factionOrID, needType, amount)
        local faction = type(factionOrID) == "table" and factionOrID or factions[factionOrID]
        faction.needs[needType] = math.min(100, faction.needs[needType] + amount)
        return faction.needs[needType]
    end,
}
PNC.NPCWounds = { ApplyCombatDamage = function(record, _, event)
    record.health.current = math.max(1, record.health.current - event.amount)
    record.wounds = record.wounds or {}
    record.wounds[#record.wounds + 1] = { type = event.woundType, damage = event.amount }
    PNC.Registry.MarkDirty(record, "wounds")
    return true, { outcome = "wounded", woundType = event.woundType,
        damage = event.amount }
end }
PNC.Health = { Kill = function(record)
    record.alive = false; record.health.current = 0; record.health.state = "dead"
    PNC.Registry.MarkDirty(record, "health")
    return true
end }

dofile(SHARED .. "Director/PNC_DirectorConfig.lua")
dofile(SHARED .. "Director/PNC_AbstractWorldTypes.lua")
dofile(SHARED .. "Scheduling/PNC_Scheduler.lua")
dofile(SERVER .. "PNC_AbstractWorldStore.lua")
dofile(SERVER .. "PNC_AbstractLocationManager.lua")
dofile(SERVER .. "PNC_AbstractGroupManager.lua")
dofile(SERVER .. "PNC_AbstractCombatProfile.lua")
dofile(SERVER .. "PNC_AbstractResourceNeeds.lua")
dofile(SERVER .. "PNC_AbstractBehaviorProfile.lua")
dofile(SERVER .. "PNC_AbstractScavengeResolver.lua")
dofile(SERVER .. "PNC_AbstractActionResolver.lua")
dofile(SERVER .. "PNC_AbstractEncounterEvaluator.lua")
dofile(SERVER .. "PNC_AbstractCasualtyResolver.lua")
dofile(SERVER .. "PNC_AbstractRetreatResolver.lua")
dofile(SERVER .. "PNC_AbstractCombatResolver.lua")
dofile(SERVER .. "PNC_AbstractEncounterResolver.lua")
dofile(SERVER .. "PNC_AbstractEncounterDetector.lua")
dofile(SERVER .. "PNC_AbstractTraversal.lua")

PNC.AbstractWorldStore.Load()

local function faction(id, archetype, needs)
    local value = { id = id, archetypeID = archetype, needs = needs,
        memberIDs = {}, relations = {}, mobile = { active = true } }
    factions[id] = value
    return value
end
local function npc(id, factionValue, role, weapon, health)
    local record = { id = id, alive = true, presenceState = "abstract",
        health = { current = health or 100, max = 100, state = "normal" },
        runtime = {}, equipment = { primaryFullType = weapon or "" },
        affiliation = { factionID = factionValue.id, role = role or "civilian" } }
    PNC.Registry.Data[id] = record
    factionValue.memberIDs[id] = true
    return record
end
local function group(id, factionValue, groupType, location, resources, memberIds)
    return assert(PNC.AbstractGroups.Create({ id = id, factionId = factionValue.id,
        groupType = groupType, memberIds = memberIds or {}, mission = "SCAVENGE",
        state = "IDLE", location = PNC.AbstractLocations.Ref(location),
        resources = resources or {}, morale = 0.65 }))
end

local origin = assert(PNC.AbstractLocations.Register({ id = "aloc_origin",
    type = "BUILDING", x = 0, y = 0, z = 0, tags = { SAFE = true },
    resourcePotential = {} }))
local foodSite = assert(PNC.AbstractLocations.Register({ id = "aloc_food",
    type = "BUILDING", x = 100, y = 0, z = 0, tags = { FOOD = true },
    resourcePotential = { food = 90, water = 5, ammo = 4 }, scavengedLevel = 10 }))
local waterSite = assert(PNC.AbstractLocations.Register({ id = "aloc_water",
    type = "BUILDING", x = 0, y = 100, z = 0, tags = { WATER = true },
    resourcePotential = { food = 5, water = 90 }, scavengedLevel = 10 }))
local safeSite = assert(PNC.AbstractLocations.Register({ id = "aloc_safe",
    type = "BUILDING", x = -120, y = 0, z = 0, tags = { SAFE = true },
    resourcePotential = { food = 20, water = 20 } }))

local scavFaction = faction("faction_scav", "refugee",
    { hunger = 8, hydration = 90, fatigue = 80 })
local scavenger = npc("npc_scav", scavFaction, "scavenger", "Base.Axe")
local scavGroup = group("agroup_scav", scavFaction, "SCAVENGER", origin,
    { food = 0, water = 30, ammo = 0, medical = 0 }, { scavenger.id })
local chosen = assert(PNC.AbstractTraversal.ChooseDestination(scavGroup))
equal(chosen.id, foodSite.id, "food shortage weights destination")
assert(PNC.AbstractTraversal.Begin(scavGroup, foodSite, worldHour))
worldHour = scavGroup.stateEndsAt
assert(PNC.AbstractTraversal.Arrive(scavGroup, worldHour))
equal(scavGroup.state, "PERFORMING_ACTION", "arrival begins action")
local actionCopy = copy(scavGroup.action)
local deterministicA = PNC.AbstractScavengeResolver.Calculate(scavGroup, foodSite, actionCopy)
local deterministicB = PNC.AbstractScavengeResolver.Calculate(scavGroup, foodSite, actionCopy)
equal(deterministicA.yields.food, deterministicB.yields.food,
    "same action seed reproduces yield")
local lowDepletion = deterministicA.yields.food
local savedLevel = foodSite.scavengedLevel
foodSite.scavengedLevel = 92
local depleted = PNC.AbstractScavengeResolver.Calculate(scavGroup, foodSite, actionCopy)
greater(lowDepletion, depleted.yields.food, "depletion lowers yield")
foodSite.scavengedLevel = savedLevel
local foodBefore = scavGroup.resources.food
worldHour = scavGroup.action.endsAt
local scavenged = assert(PNC.AbstractActions.Complete(scavGroup, worldHour))
greater(scavGroup.resources.food, foodBefore, "scavenge adds food")
greater(foodSite.scavengedLevel, savedLevel, "scavenge depletes location")
equal(scavGroup.state, "ACTION_COMPLETE", "action lifecycle completes explicitly")
truthy(scavenged.components.food.need > scavenged.components.water.need,
    "yield diagnostics expose need weights")

local waterFaction = faction("faction_water", "refugee",
    { hunger = 95, hydration = 5, fatigue = 80 })
local waterGroup = group("agroup_water", waterFaction, "SCAVENGER", origin,
    { food = 30, water = 0 }, {})
equal(assert(PNC.AbstractTraversal.ChooseDestination(waterGroup)).id, waterSite.id,
    "water shortage weights destination")

local looterFaction = faction("faction_looter", "looter",
    { hunger = 90, hydration = 90, fatigue = 90 })
local refugeeFaction = faction("faction_refugee", "refugee",
    { hunger = 70, hydration = 70, fatigue = 70 })
local looterIds = {}
for index = 1, 5 do
    local record = npc("npc_looter_" .. index, looterFaction,
        index == 1 and "leader" or "raider", "Base.AssaultRifle")
    looterIds[#looterIds + 1] = record.id
end
local refugeeIds = {}
for index = 1, 8 do
    local role = index <= 2 and "guard" or "civilian"
    local weapon = index <= 2 and "Base.Pistol" or ""
    local record = npc("npc_refugee_" .. index, refugeeFaction, role, weapon)
    refugeeIds[#refugeeIds + 1] = record.id
end
local looters = group("agroup_looters", looterFaction, "LOOTER", origin,
    { food = 50, water = 50, ammo = 100, medical = 10 }, looterIds)
local refugees = group("agroup_refugees", refugeeFaction, "REFUGEE", origin,
    { food = 45, water = 30, ammo = 10, medical = 4 }, refugeeIds)
local looterProfile = assert(PNC.AbstractCombatProfile.Get(looters, true))
local refugeeProfile = assert(PNC.AbstractCombatProfile.Get(refugees, true))
greater(looterProfile.overallPower, refugeeProfile.overallPower,
    "combatants and arms outweigh raw population")
local context = assert(PNC.AbstractEncounterEvaluator.BuildContext({ id = "encounter_test",
    seed = 12345, abstractResolutionAllowed = true }, looters, refugees, origin))
local intents = PNC.AbstractEncounterEvaluator.Evaluate(context, looters, refugees)
truthy(intents[looters.id].scores.EXTORT > intents[looters.id].scores.FLEE,
    "looters favor hostile acquisition against weak target")
truthy(intents[refugees.id].scores.FLEE > intents[refugees.id].scores.ATTACK,
    "refugees favor flight from armed looters")

local armedFaction = faction("faction_armed_refugee", "refugee",
    { hunger = 90, hydration = 90, fatigue = 90 })
local armedIds = {}
for index = 1, 9 do
    local record = npc("npc_armed_refugee_" .. index, armedFaction,
        "guard", "Base.AssaultRifle")
    armedIds[#armedIds + 1] = record.id
end
local armedRefugees = group("agroup_armed_refugees", armedFaction,
    "REFUGEE", origin, { food = 80, water = 80, ammo = 180,
        medical = 20 }, armedIds)
local outmatchedContext = assert(PNC.AbstractEncounterEvaluator.BuildContext({
    id = "encounter_outmatched", seed = 7331, abstractResolutionAllowed = true },
    looters, armedRefugees, origin))
local outmatchedIntent = PNC.AbstractEncounterEvaluator.Evaluate(
    outmatchedContext, looters, armedRefugees)[looters.id]
truthy(outmatchedIntent.scores.AVOID > outmatchedIntent.scores.ATTACK,
    "looters avoid overwhelmingly armed refugees")

looterFaction.relations[refugeeFaction.id] = { state = "friendly", standing = 60,
    allied = true }
local friendlyContext = assert(PNC.AbstractEncounterEvaluator.BuildContext({
    id = "encounter_friendly", seed = 44, abstractResolutionAllowed = true },
    looters, refugees, origin))
local friendlyIntent = PNC.AbstractEncounterEvaluator.Evaluate(
    friendlyContext, looters, refugees)[looters.id]
truthy(friendlyIntent.scores.IGNORE > friendlyIntent.scores.ATTACK,
    "friendly relationship suppresses attack")
looterFaction.relations[refugeeFaction.id] = nil

local suppliedContext = PNC.AbstractBehaviorProfile.GetContext(looters, looterProfile)
looterFaction.needs.hunger, looterFaction.needs.hydration = 0, 0
looters.resources.food, looters.resources.water = 0, 0
local desperateContext = PNC.AbstractBehaviorProfile.GetContext(looters, looterProfile)
greater(desperateContext.desperation, suppliedContext.desperation,
    "critical needs increase desperation")
local suppliedScore = PNC.AbstractEncounterEvaluator.Score(looters,
    suppliedContext, context.initiatorThreat, context.relationship, 91)
local desperateScore = PNC.AbstractEncounterEvaluator.Score(looters,
    desperateContext, context.initiatorThreat, context.relationship, 91)
greater(desperateScore.scores.EXTORT, suppliedScore.scores.EXTORT,
    "desperation increases extortion utility")

-- End-to-end extortion: queue, evaluate, bounded transfer, no combat on compliance.
looters.resources.food, looters.resources.water = 50, 50
looterFaction.needs.hunger, looterFaction.needs.hydration = 90, 90
local extortReport = assert(PNC.AbstractEncounters.Create(origin, looters, refugees,
    worldHour + 3))
PNC.AbstractEncounterResolver.ProcessBatch(worldHour, 1)
truthy(extortReport.intentScores ~= nil, "encounter stores intent diagnostics")
truthy(extortReport.outcome == "EXTORT_COMPLIED"
    or extortReport.outcome == "ROB_COMPLIED", "strong looters can coerce compliance")
truthy(extortReport.combatResult == nil, "compliance avoids combat")
for _, value in pairs(refugees.resources) do truthy(value >= 0,
    "resource transfer never goes negative") end
local refusalTarget = { id = refugees.id }
local refusalActor = { id = looters.id }
local calmRefusal = PNC.AbstractEncounterResolver.EvaluateHostileResponse(
    refusalActor, refusalTarget,
    { components = { aggression = 0.1, desperation = 0, advantage = 0 } },
    { components = { caution = 0, relativeStrength = 1, morale = 1 } },
    "EXTORT", 12)
equal(calmRefusal, "REFUSE", "failed extortion does not always escalate")
local violentRefusal = PNC.AbstractEncounterResolver.EvaluateHostileResponse(
    refusalActor, refusalTarget,
    { components = { aggression = 1, desperation = 1, advantage = 1 } },
    { components = { caution = 0, relativeStrength = 1, morale = 1 } },
    "EXTORT", 12)
equal(violentRefusal, "RESIST_ATTACK",
    "failed extortion escalates only with justified hostile utility")

-- Ammo affects cached capability and is expended by combat.
local highRanged = assert(PNC.AbstractCombatProfile.Get(looters, true)).rangedPower
looters.resources.ammo = 1
local lowRanged = assert(PNC.AbstractCombatProfile.Get(looters, false)).rangedPower
greater(highRanged, lowRanged, "critical ammo lowers ranged contribution")
looters.resources.ammo = 80
local combatContext = assert(PNC.AbstractEncounterEvaluator.BuildContext({
    id = "encounter_combat", seed = 9981, abstractResolutionAllowed = true },
    looters, refugees, origin))
local ammoBefore = looters.resources.ammo
local combatResult = PNC.AbstractCombatResolver.Resolve(
    combatContext, looters, refugees, origin)
truthy(combatResult.rounds <= PNC.DirectorConfig.CombatResolution.MAX_ABSTRACT_COMBAT_ROUNDS,
    "combat rounds are hard bounded")
truthy(looters.resources.ammo < ammoBefore, "abstract combat consumes ammo")
local retreatCheck = PNC.AbstractRetreatResolver.Decide(refugees, 0.15, 0.25,
    0.6, 0.8, 1, PNC.AbstractBehaviorProfile.GetContext(refugees), 81)
truthy(retreatCheck.attempted, "outmatched low-morale refugees attempt retreat")

-- Forced aggregate casualties exercise canonical persistent injury/death adapters.
local casualtyTarget = refugees.memberIds[1]
local deathTarget = refugees.memberIds[2]
local applied = PNC.AbstractCasualtyResolver.Apply(refugees,
    { SERIOUS = 1, DEAD = 1 }, 551, looters.id)
equal(#applied.injuries, 1, "actual NPC receives persistent injury")
equal(#applied.deaths, 1, "actual NPC receives persistent death")
truthy(PNC.Registry.Data[applied.injuries[1].npcId].wounds ~= nil,
    "canonical wound representation used")
equal(PNC.Registry.Data[applied.deaths[1]].alive, false,
    "canonical record marked dead")
truthy(refugees.combatProfileDirty, "casualties invalidate combat profile")
truthy(casualtyTarget ~= deathTarget, "distinct members selected")

-- Observation safety is checked at detection and never queues mutations.
local observedFactionA = faction("faction_observed_a", "looter",
    { hunger = 20, hydration = 20, fatigue = 80 })
local observedFactionB = faction("faction_observed_b", "refugee",
    { hunger = 20, hydration = 20, fatigue = 80 })
local observedA = group("agroup_observed_a", observedFactionA, "LOOTER", origin,
    { food = 10, water = 10 }, {})
local observedB = group("agroup_observed_b", observedFactionB, "REFUGEE", origin,
    { food = 10, water = 10 }, {})
playerNearby = true
local beforeObserved = copy(observedB.resources)
local observedReport = assert(PNC.AbstractEncounters.Create(origin,
    observedA, observedB, worldHour + 6))
equal(observedReport.outcome, "MATERIALIZATION_REQUIRED",
    "player observation blocks abstract resolution")
equal(observedB.resources.food, beforeObserved.food,
    "observation blocks resource mutation")
playerNearby = false

-- Pair cooldown and participant lock prevent repeat/reentrant resolution.
local firstDetect = PNC.AbstractEncounters.DetectAt(origin, observedA, worldHour + 9)
local secondDetect = PNC.AbstractEncounters.DetectAt(origin, observedA, worldHour + 9.1)
truthy(#firstDetect >= 1, "first occupancy collision detected")
equal(#secondDetect, 0, "same occupancy collision deduplicated")
observedA.activeEncounterId = "encounter_lock"
local pending = firstDetect[1]
local resolved, lockedReason = PNC.AbstractEncounterResolver.Resolve(pending)
equal(resolved, nil, "active participant cannot resolve twice")
equal(lockedReason, "participant_locked", "reentrancy lock reason")
observedA.activeEncounterId = nil

local queueBefore = #PNC.AbstractEncounterResolver.Queue
truthy(queueBefore > 0, "collisions accumulate in bounded encounter queue")
PNC.AbstractEncounterResolver.ProcessBatch(worldHour, 1)
equal(#PNC.AbstractEncounterResolver.Queue, queueBefore - 1,
    "encounter processing respects one-item budget")
local queueGuard = 0
while #PNC.AbstractEncounterResolver.Queue > 0 and queueGuard < 100 do
    PNC.AbstractEncounterResolver.ProcessBatch(worldHour, 1)
    queueGuard = queueGuard + 1
end
equal(#PNC.AbstractEncounterResolver.Queue, 0,
    "budgeted encounter queue eventually drains")

local actionBudgetGroups = {}
for index = 1, 3 do
    local actionFaction = faction("faction_action_" .. index, "refugee",
        { hunger = 50, hydration = 50, fatigue = 80 })
    local actionMember = npc("npc_action_" .. index, actionFaction,
        "scavenger", "Base.Axe")
    local actionGroup = group("agroup_action_" .. index, actionFaction,
        "SCAVENGER", safeSite, { food = 0, water = 0 }, { actionMember.id })
    assert(PNC.AbstractActions.Start(actionGroup, "SCAVENGE", worldHour,
        { duration = 0 }))
    actionBudgetGroups[#actionBudgetGroups + 1] = actionGroup
end
local completedBefore = PNC.AbstractActions.Metrics.completed
PNC.AbstractActions.AdvanceBatch(worldHour, 1)
equal(PNC.AbstractActions.Metrics.completed, completedBefore + 1,
    "action processing respects one-group budget")
PNC.AbstractActions.AdvanceBatch(worldHour, 3)
equal(PNC.AbstractActions.Metrics.completed, completedBefore + 3,
    "rotating action budget eventually completes all groups")

local persistedActionFaction = faction("faction_action_persist", "refugee",
    { hunger = 60, hydration = 60, fatigue = 80 })
local persistedActionMember = npc("npc_action_persist", persistedActionFaction,
    "scavenger", "Base.Axe")
local persistedActionGroup = group("agroup_action_persist", persistedActionFaction,
    "SCAVENGER", safeSite, { food = 0, water = 0 },
    { persistedActionMember.id })
assert(PNC.AbstractActions.Start(persistedActionGroup, "SCAVENGE", worldHour,
    { duration = 2 }))

-- Save/load retains completed mutations and safely normalizes optional action state.
truthy(PNC.AbstractWorldStore.Save(), "phase2 registry save")
PNC.AbstractWorldStore.Registry = {}; PNC.AbstractWorldStore.Loaded = false
truthy(PNC.AbstractWorldStore.Load(), "phase2 registry reload")
local reloaded = assert(PNC.AbstractGroups.Get(refugees.id))
truthy(reloaded.combatProfileDirty, "dirty profile survives reload")
truthy(reloaded.morale >= 0 and reloaded.morale <= 1, "morale survives reload")
local deadStillMember = false
for _, npcID in ipairs(reloaded.memberIds) do
    if npcID == applied.deaths[1] then deadStillMember = true end
end
equal(deadStillMember, false, "dead member remains reconciled after reload")
truthy(PNC.Registry.Data[applied.injuries[1].npcId].wounds ~= nil,
    "canonical injury remains after abstract registry reload")
local reloadedAction = assert(PNC.AbstractGroups.Get(persistedActionGroup.id))
equal(reloadedAction.state, "PERFORMING_ACTION",
    "active action state survives reload")
equal(reloadedAction.action.seed, persistedActionGroup.action.seed,
    "active action seed survives reload")

print("pnc_abstract_world_phase2_smoke: ok")
