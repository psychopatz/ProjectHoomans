-- Bounded aggregate group combat: pressure, morale, retreat, then casualties.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.AbstractCombatResolver = PNC.AbstractCombatResolver or {}

local Combat = PNC.AbstractCombatResolver
local Config = PNC.DirectorConfig
local Store = PNC.AbstractWorldStore
local Profiles = PNC.AbstractCombatProfile
local Behavior = PNC.AbstractBehaviorProfile
local Casualties = PNC.AbstractCasualtyResolver
local Retreat = PNC.AbstractRetreatResolver
local Groups = PNC.AbstractGroups

Combat.Metrics = Combat.Metrics or { combats = 0, retreats = 0,
    casualties = 0, rounds = 0 }

local function unit(seed, salt) return PNC.AbstractScavengeResolver.Unit(seed, salt) end
local function alive(group) return #(group.memberIds or {}) end

local function environment(location)
    return Config.CombatResolution.ENVIRONMENT[location.type]
        or Config.CombatResolution.ENVIRONMENT.POI
end

local function values(profile, morale, env, seed, side, round)
    local variance = 1 + (unit(seed, side .. ":" .. round) * 2 - 1)
        * Config.CombatResolution.VARIANCE
    local offense = ((profile.overallPower or 0) * 0.78
        + (profile.rangedPower or 0) * 4 * env.ranged) * (0.55 + morale * 0.45) * variance
    local defense = ((profile.defense or 0) * 5 + (profile.manpower or 0) * 4
        + (profile.condition or 0) * 8 + 5) * env.defense
    return { offense = offense, defense = defense,
        mobility = (profile.mobility or 0) * env.mobility,
        morale = morale, variance = variance }
end

local function severityCounts(pressure, maximum, seed, salt)
    local count = math.min(maximum, math.max(0, math.floor(pressure
        + unit(seed, salt .. ":count"))))
    local output = { MINOR = 0, SERIOUS = 0, CRITICAL = 0, DEAD = 0 }
    for index = 1, count do
        local roll = unit(seed, salt .. ":severity:" .. index)
        if pressure >= 1.7 and roll < math.min(0.16, pressure * 0.055) then
            output.DEAD = output.DEAD + 1
        elseif roll < 0.22 + math.min(0.18, pressure * 0.06) then
            output.CRITICAL = output.CRITICAL + 1
        elseif roll < 0.62 then output.SERIOUS = output.SERIOUS + 1
        else output.MINOR = output.MINOR + 1 end
    end
    return output, count
end

local function spendAmmo(group, profile, seed, salt)
    local available = math.max(0, tonumber(group.resources.ammo) or 0)
    local used = math.min(available, math.ceil((profile.rangedPower or 0)
        * Config.CombatResolution.AMMO_EXPENDITURE_SCALE
        * (0.8 + unit(seed, salt) * 0.4)))
    if used > 0 then
        group.resources.ammo = available - used
        Groups.MarkCombatProfileDirty(group, "abstract_ammo_expenditure")
    end
    return used
end

local function spendMedical(group, applied)
    local requested = (applied.counts.SERIOUS or 0) + (applied.counts.CRITICAL or 0)
    local available = math.max(0, tonumber(group.resources.medical) or 0)
    local used = math.min(available, requested)
    group.resources.medical = available - used
    return used
end

local function accumulateCounts(target, source)
    for _, severity in ipairs({ "MINOR", "SERIOUS", "CRITICAL", "DEAD" }) do
        target[severity] = (target[severity] or 0) + (source[severity] or 0)
    end
end

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
        if alive(first) == 0 or alive(second) == 0 then break end
        result.rounds = round
        Combat.Metrics.rounds = Combat.Metrics.rounds + 1
        local firstProfile = Profiles.Get(first, false)
        local secondProfile = Profiles.Get(second, false)
        local env = environment(location)
        local a = values(firstProfile, morale[first.id], env, seed, first.id, round)
        local b = values(secondProfile, morale[second.id], env, seed, second.id, round)
        local pressureAB = a.offense / math.max(1, b.defense)
            * Config.CombatResolution.CASUALTY_PRESSURE_SCALE
        local pressureBA = b.offense / math.max(1, a.defense)
            * Config.CombatResolution.CASUALTY_PRESSURE_SCALE
        local countsB, countB = severityCounts(pressureAB,
            math.min(Config.CombatResolution.MAX_CASUALTIES_PER_ROUND, alive(second)),
            seed, "AtoB:" .. round)
        local countsA, countA = severityCounts(pressureBA,
            math.min(Config.CombatResolution.MAX_CASUALTIES_PER_ROUND, alive(first)),
            seed, "BtoA:" .. round)
        local appliedA = Casualties.Apply(first, countsA, seed + round * 31, second.id)
        local appliedB = Casualties.Apply(second, countsB, seed + round * 47, first.id)
        local ammoA = spendAmmo(first, firstProfile, seed, "ammoA:" .. round)
        local ammoB = spendAmmo(second, secondProfile, seed, "ammoB:" .. round)
        local medicalA = spendMedical(first, appliedA)
        local medicalB = spendMedical(second, appliedB)
        result.resourceChanges[first.id].ammo = result.resourceChanges[first.id].ammo - ammoA
        result.resourceChanges[second.id].ammo = result.resourceChanges[second.id].ammo - ammoB
        result.resourceChanges[first.id].medical = result.resourceChanges[first.id].medical - medicalA
        result.resourceChanges[second.id].medical = result.resourceChanges[second.id].medical - medicalB
        accumulateCounts(result.casualties[first.id], appliedA.counts)
        accumulateCounts(result.casualties[second.id], appliedB.counts)
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
        if alive(first) == 0 or alive(second) == 0 then break end
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
    local firstPower = alive(first) > 0 and (Profiles.Get(first, false).overallPower or 0) or 0
    local secondPower = alive(second) > 0 and (Profiles.Get(second, false).overallPower or 0) or 0
    local winner
    if retreating then winner = retreating.id == first.id and second.id or first.id
    elseif firstPower > secondPower * 1.08 then winner = first.id
    elseif secondPower > firstPower * 1.08 then winner = second.id end
    result.winnerId = winner
    result.reasonEnded = ended or (alive(first) == 0 or alive(second) == 0)
        and "DESTRUCTION" or "MAX_ROUNDS"
    result.outcome = result.reasonEnded == "DESTRUCTION" and "DESTRUCTION"
        or result.reasonEnded == "RETREAT" and "WITHDRAWAL"
        or winner and "VICTORY" or "STALEMATE"
    for _, group in ipairs(participants) do
        result.participantResults[group.id] = {
            survivors = alive(group), morale = group.morale,
            outcome = alive(group) == 0 and "DESTROYED"
                or group == retreating and "WITHDRAWAL"
                or winner == group.id and "VICTORY" or "DEFEAT" }
        Groups.MarkCombatProfileDirty(group, "abstract_combat_resolved")
    end
    result.moraleChanges[first.id] = morale[first.id]
    result.moraleChanges[second.id] = morale[second.id]
    Store.Touch("abstract_combat_resolved")
    Store.Emit("ABSTRACT_COMBAT_RESOLVED", result)
    return result
end

return Combat
