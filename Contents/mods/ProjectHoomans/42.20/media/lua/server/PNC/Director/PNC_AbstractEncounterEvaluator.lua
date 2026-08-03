-- Encounter context, relationship/threat assessment, and utility-scored intent.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.AbstractEncounterEvaluator = PNC.AbstractEncounterEvaluator or {}

local Evaluator = PNC.AbstractEncounterEvaluator
local Config = PNC.DirectorConfig
local CombatProfiles = PNC.AbstractCombatProfile
local Behavior = PNC.AbstractBehaviorProfile
local Groups = PNC.AbstractGroups

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, tonumber(value) or minimum))
end

local function jitter(seed, text)
    local hash = PNC.AbstractScavengeResolver.Hash(tostring(seed) .. ":" .. text)
    return ((hash % 10001) / 10000 * 2 - 1) * Config.Intent.VARIANCE
end

function Evaluator.GetRelationship(first, second)
    if first.factionId and first.factionId == second.factionId then
        return { category = "friendly", state = "friendly", standing = 100 }
    end
    local relation = first.factionId and second.factionId and PNC.Factions
        and PNC.Factions.GetRelation and PNC.Factions.GetRelation(
            first.factionId, second.factionId) or nil
    local state = tostring(relation and relation.state or "neutral")
    local hostile = relation and relation.atWar == true
        or state == "war" or state == "hostile"
    local friendly = relation and relation.allied == true
        or state == "allied" or state == "friendly"
    return { category = friendly and "friendly" or hostile and "hostile" or "neutral",
        state = state, standing = tonumber(relation and relation.standing) or 0,
        atWar = relation and relation.atWar == true or false,
        allied = relation and relation.allied == true or false }
end

function Evaluator.AssessThreat(mine, enemy)
    local myPower = math.max(0.1, tonumber(mine.overallPower) or 0.1)
    local enemyPower = math.max(0.1, tonumber(enemy.overallPower) or 0.1)
    local ratio = clamp(myPower / enemyPower, 0.05, 20)
    return { myPower = myPower, enemyPower = enemyPower,
        relativeStrength = ratio, myRanged = mine.rangedPower or 0,
        enemyRanged = enemy.rangedPower or 0,
        myCombatants = mine.combatantCount or 0,
        enemyCombatants = enemy.combatantCount or 0,
        myMobility = mine.mobility or 0, enemyMobility = enemy.mobility or 0 }
end

function Evaluator.BuildContext(report, initiatorOrID, targetOrID, location)
    local initiator = type(initiatorOrID) == "table" and initiatorOrID
        or Groups.Get(initiatorOrID)
    local target = type(targetOrID) == "table" and targetOrID or Groups.Get(targetOrID)
    if not initiator or not target then return nil, "missing_participant" end
    local firstProfile = CombatProfiles.Get(initiator, false)
    local secondProfile = CombatProfiles.Get(target, false)
    local firstBehavior = Behavior.GetContext(initiator, firstProfile)
    local secondBehavior = Behavior.GetContext(target, secondProfile)
    return { id = report.id, locationId = location.id,
        initiatorId = initiator.id, targetId = target.id,
        relationship = Evaluator.GetRelationship(initiator, target),
        reverseRelationship = Evaluator.GetRelationship(target, initiator),
        initiatorCombatProfile = firstProfile, targetCombatProfile = secondProfile,
        initiatorBehavior = firstBehavior, targetBehavior = secondBehavior,
        initiatorThreat = Evaluator.AssessThreat(firstProfile, secondProfile),
        targetThreat = Evaluator.AssessThreat(secondProfile, firstProfile),
        playerObserved = report.abstractResolutionAllowed == false,
        seed = report.seed }, "context_built"
end

function Evaluator.Score(group, behaviorContext, threat, relationship, seed)
    local stable = behaviorContext.stable
    local aggression, bravery = stable.aggression, stable.bravery
    local greed, caution = stable.greed, stable.caution
    local mercy, civilian = stable.mercy, stable.civilianHostility
    local desperation, morale = behaviorContext.desperation, behaviorContext.morale
    local ratio = threat.relativeStrength
    local advantage = clamp((ratio - 1) / 1.5, 0, 1)
    local weakness = clamp((1 - ratio) / 0.8, 0, 1)
    local scores = {
        IGNORE = Config.Intent.BASE.IGNORE + mercy * 10 + (1 - desperation) * 12 - aggression * 10,
        AVOID = Config.Intent.BASE.AVOID + caution * 28 + weakness * 48 + (1 - aggression) * 10,
        FLEE = Config.Intent.BASE.FLEE + caution * 22 + weakness * 82 + (1 - morale) * 25 - aggression * 12,
        NEGOTIATE = Config.Intent.BASE.NEGOTIATE + mercy * 18 + caution * 8 - aggression * 5,
        EXTORT = Config.Intent.BASE.EXTORT + greed * 42 + aggression * 16
            + desperation * 24 + advantage * 35 - weakness * 58 + civilian * 10,
        ROB = Config.Intent.BASE.ROB + greed * 35 + aggression * 24
            + desperation * 28 + advantage * 30 - weakness * 66 + civilian * 12,
        ATTACK = Config.Intent.BASE.ATTACK + aggression * 48 + bravery * 20
            + desperation * 20 + advantage * 38 - weakness * 78 - caution * 18,
    }
    if relationship.category == "friendly" then
        scores.IGNORE = scores.IGNORE + 30
        scores.NEGOTIATE = scores.NEGOTIATE + 25
        for _, intent in ipairs({ "EXTORT", "ROB", "ATTACK" }) do
            scores[intent] = scores[intent] - Config.Intent.FRIENDLY_HOSTILE_PENALTY
        end
    elseif relationship.category == "hostile" then
        scores.ATTACK = scores.ATTACK + Config.Intent.HOSTILE_BONUS
        scores.ROB = scores.ROB + Config.Intent.HOSTILE_BONUS * 0.60
        scores.EXTORT = scores.EXTORT + Config.Intent.HOSTILE_BONUS * 0.45
        scores.NEGOTIATE = scores.NEGOTIATE - 12
    end
    local selected, selectedScore
    for _, intent in ipairs(Config.Intent.OPTIONS) do
        scores[intent] = scores[intent] + jitter(seed, group.id .. ":" .. intent)
        if not selected or scores[intent] > selectedScore then
            selected, selectedScore = intent, scores[intent]
        end
    end
    return { selected = selected, scores = scores,
        components = { aggression = aggression, bravery = bravery,
            greed = greed, caution = caution, mercy = mercy,
            civilianHostility = civilian, desperation = desperation,
            morale = morale, relativeStrength = ratio, advantage = advantage,
            weakness = weakness, relationship = relationship.category } }
end

function Evaluator.Evaluate(context, initiator, target)
    local first = Evaluator.Score(initiator, context.initiatorBehavior,
        context.initiatorThreat, context.relationship, context.seed)
    local second = Evaluator.Score(target, context.targetBehavior,
        context.targetThreat, context.reverseRelationship, context.seed + 17)
    return { [initiator.id] = first, [target.id] = second }
end

return Evaluator
