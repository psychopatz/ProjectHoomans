if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Combat = PNC.AbstractCombatResolver
local Config = PNC.DirectorConfig
local Store = PNC.AbstractWorldStore
local Profiles = PNC.AbstractCombatProfile
local Behavior = PNC.AbstractBehaviorProfile
local Casualties = PNC.AbstractCasualtyResolver
local Retreat = PNC.AbstractRetreatResolver
local Groups = PNC.AbstractGroups
local H = Combat.Internal

function Combat.Resolve(context, first, second, location)
    local seed = context.seed
    local result = { encounterId = context.id, seed = seed, rounds = 0,
        participantResults = {}, casualties = {}, injuries = {}, deaths = {},
        resourceChanges = {}, moraleChanges = {}, retreat = {}, roundReports = {} }
    local morale = { [first.id] = tonumber(first.morale) or context.initiatorBehavior.morale,
        [second.id] = tonumber(second.morale) or context.targetBehavior.morale }
    local participants = { first, second }
    for _, group in ipairs(participants) do
        result.casualties[group.id] = { MINOR = 0, SERIOUS = 0,
            CRITICAL = 0, DEAD = 0 }
        result.resourceChanges[group.id] = { ammo = 0, medical = 0 }
    end
    Store.Emit("ABSTRACT_COMBAT_STARTED", { encounterId = context.id,
        participantIds = { first.id, second.id }, seed = seed })
    Combat.Metrics.combats = Combat.Metrics.combats + 1
    local ended, retreating
    for round = 1, Config.CombatResolution.MAX_ABSTRACT_COMBAT_ROUNDS do
        if H.Alive(first) == 0 or H.Alive(second) == 0 then break end
        result.rounds = round
        Combat.Metrics.rounds = Combat.Metrics.rounds + 1
        local firstProfile = Profiles.Get(first, false)
        local secondProfile = Profiles.Get(second, false)
        local env = H.Environment(location)
        local a = H.Values(firstProfile, morale[first.id], env, seed, first.id, round)
        local b = H.Values(secondProfile, morale[second.id], env, seed, second.id, round)
        local pressureAB = a.offense / math.max(1, b.defense)
            * Config.CombatResolution.CASUALTY_PRESSURE_SCALE
        local pressureBA = b.offense / math.max(1, a.defense)
            * Config.CombatResolution.CASUALTY_PRESSURE_SCALE
        local countsB, countB = H.SeverityCounts(pressureAB,
            math.min(Config.CombatResolution.MAX_CASUALTIES_PER_ROUND, H.Alive(second)),
            seed, "AtoB:" .. round)
        local countsA, countA = H.SeverityCounts(pressureBA,
            math.min(Config.CombatResolution.MAX_CASUALTIES_PER_ROUND, H.Alive(first)),
            seed, "BtoA:" .. round)
        local appliedA = Casualties.Apply(first, countsA, seed + round * 31, second.id)
        local appliedB = Casualties.Apply(second, countsB, seed + round * 47, first.id)
        local ammoA = H.SpendAmmo(first, firstProfile, seed, "ammoA:" .. round)
        local ammoB = H.SpendAmmo(second, secondProfile, seed, "ammoB:" .. round)
        local medicalA = H.SpendMedical(first, appliedA)
        local medicalB = H.SpendMedical(second, appliedB)
        result.resourceChanges[first.id].ammo = result.resourceChanges[first.id].ammo - ammoA
        result.resourceChanges[second.id].ammo = result.resourceChanges[second.id].ammo - ammoB
        result.resourceChanges[first.id].medical = result.resourceChanges[first.id].medical - medicalA
        result.resourceChanges[second.id].medical = result.resourceChanges[second.id].medical - medicalB
        H.AccumulateCounts(result.casualties[first.id], appliedA.counts)
        H.AccumulateCounts(result.casualties[second.id], appliedB.counts)
        local oldA, oldB = morale[first.id], morale[second.id]
        morale[first.id] = math.max(0, oldA - countA
            * Config.CombatResolution.MORALE_CASUALTY_LOSS
            - math.min(0.2, pressureBA * Config.CombatResolution.MORALE_PRESSURE_LOSS))
        morale[second.id] = math.max(0, oldB - countB
            * Config.CombatResolution.MORALE_CASUALTY_LOSS
            - math.min(0.2, pressureAB * Config.CombatResolution.MORALE_PRESSURE_LOSS))
        first.morale, second.morale = morale[first.id], morale[second.id]
        local roundReport = { round = round,
            [first.id] = { effective = a, pressureReceived = pressureBA,
                casualties = appliedA, ammoUsed = ammoA, medicalUsed = medicalA,
                moraleBefore = oldA, moraleAfter = morale[first.id] },
            [second.id] = { effective = b, pressureReceived = pressureAB,
                casualties = appliedB, ammoUsed = ammoB, medicalUsed = medicalB,
                moraleBefore = oldB, moraleAfter = morale[second.id] } }
        result.roundReports[#result.roundReports + 1] = roundReport
        for _, injury in ipairs(appliedA.injuries) do result.injuries[#result.injuries + 1] = injury end
        for _, injury in ipairs(appliedB.injuries) do result.injuries[#result.injuries + 1] = injury end
        for _, death in ipairs(appliedA.deaths) do result.deaths[#result.deaths + 1]
            = { npcId = death, groupId = first.id } end
        for _, death in ipairs(appliedB.deaths) do result.deaths[#result.deaths + 1]
            = { npcId = death, groupId = second.id } end
        Combat.Metrics.casualties = Combat.Metrics.casualties + countA + countB
        Store.Emit("ABSTRACT_COMBAT_ROUND", { encounterId = context.id,
            round = round, report = roundReport })
        if H.Alive(first) == 0 or H.Alive(second) == 0 then break end
        local behaviorA = Behavior.GetContext(first, Profiles.Get(first, false))
        local behaviorB = Behavior.GetContext(second, Profiles.Get(second, false))
        local ratioA = a.offense / math.max(1, b.offense)
        local ratioB = 1 / math.max(0.05, ratioA)
        local retreatA = Retreat.Decide(first, morale[first.id], ratioA,
            a.mobility, b.mobility, countA, behaviorA, seed + round * 59)
        local retreatB = Retreat.Decide(second, morale[second.id], ratioB,
            b.mobility, a.mobility, countB, behaviorB, seed + round * 61)
        local chosen, threat, decision
        if retreatA.attempted and (not retreatB.attempted
            or morale[first.id] <= morale[second.id]) then
            chosen, threat, decision = first, second, retreatA
        elseif retreatB.attempted then chosen, threat, decision = second, first, retreatB end
        if chosen and decision.succeeded then
            Retreat.Apply(chosen, threat, location, Store.WorldAgeHours(), "combat_morale_break")
            result.retreat[chosen.id] = decision
            retreating, ended = chosen, "RETREAT"
            Combat.Metrics.retreats = Combat.Metrics.retreats + 1
            break
        elseif chosen then
            decision.failed = true
            result.retreat[chosen.id] = decision
            morale[chosen.id] = math.max(0, morale[chosen.id]
                - Config.Retreat.FAILED_RETREAT_PRESSURE)
        end
    end
    return H.Finalize(result, first, second, participants, morale,
        retreating, ended)
end

return Combat

