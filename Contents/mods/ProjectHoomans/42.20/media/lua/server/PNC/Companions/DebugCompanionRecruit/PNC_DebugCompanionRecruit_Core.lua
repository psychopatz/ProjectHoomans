if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.DebugCompanionRecruit = PNC.DebugCompanionRecruit or {}
PNC.Recruitment = PNC.Recruitment or PNC.DebugCompanionRecruit
PNC.DebugCompanionRecruitInternal =
    PNC.DebugCompanionRecruitInternal or {}

local Recruit = PNC.DebugCompanionRecruit
local H = PNC.DebugCompanionRecruitInternal
local Const = PNC.Const
local Core = PNC.Core
local Factions = PNC.Factions
local Registry = PNC.Registry
local Graph = PNC.RelationshipGraph
local RECRUIT_APPROVAL_MINIMUM = Graph
    and Graph.RECRUIT_APPROVAL_MINIMUM or 25
local RECRUIT_RESPECT_MINIMUM = Graph
    and Graph.RECRUIT_RESPECT_MINIMUM or 35
local RECRUIT_SCORE_THRESHOLD = Graph
    and Graph.RECRUIT_SCORE_THRESHOLD or 70
local RECRUIT_FEAR_APPROVAL_MAXIMUM = Graph
    and Graph.RECRUIT_FEAR_APPROVAL_MAXIMUM or -30
local RECRUIT_FEAR_RESPECT_MINIMUM = Graph
    and Graph.RECRUIT_FEAR_RESPECT_MINIMUM or 70
local RECRUIT_FEAR_SCORE_THRESHOLD = Graph
    and Graph.RECRUIT_FEAR_SCORE_THRESHOLD or 60
local RECRUIT_FEAR_BRAVERY_MAXIMUM = Graph
    and Graph.RECRUIT_FEAR_BRAVERY_MAXIMUM or 0.85

function H.WorldAgeHours()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and math.max(0, tonumber(gameTime:getWorldAgeHours()) or 0)
        or 0
end

function Recruit.IsEligible(record)
    if not record or record.alive == false or record.recruited == true then
        return false
    end
    local tacticalClass = PNC.Types and PNC.Types.NormalizeTacticalClass
        and PNC.Types.NormalizeTacticalClass(record.tacticalClass)
        or tostring(record.tacticalClass or "")
    return tacticalClass == Const.TACTICAL_CLASS_NEUTRAL
        or tacticalClass == Const.TACTICAL_CLASS_HOSTILE
end

-- Recruitment is an action requirement, not another relationship axis.  The
-- normal route is the upper-right (approval + respect) region; a frightened
-- NPC may also accept when respect is exceptionally high even though approval
-- is negative.  Hostile audience classification is always rejected by the
-- conversation path, regardless of its coordinates.
function Recruit.EvaluateConversation(record, relationship)
    relationship = type(relationship) == "table" and relationship or {}
    if not record or record.alive == false then
        return { eligible = false, reason = "npc_unavailable" }
    end
    if record.recruited == true then
        return { eligible = false, reason = "already_recruited" }
    end
    local tacticalClass = PNC.Types and PNC.Types.NormalizeTacticalClass
        and PNC.Types.NormalizeTacticalClass(record.tacticalClass)
        or tostring(record.tacticalClass or "")
    if tacticalClass == Const.TACTICAL_CLASS_HOSTILE then
        return { eligible = false, reason = "hostile_audience" }
    end
    local approval = tonumber(relationship.approval) or 0
    local respect = tonumber(relationship.respect) or 0
    local personality = Graph and Graph.ResolveNPCPersonality
        and Graph.ResolveNPCPersonality(record)
        or record.personality or record.socialProfile
        or record.social and record.social.personality or {}
    local recruitmentEvaluation = Graph
        and Graph.EvaluateRecruitment
        and Graph.EvaluateRecruitment(approval, respect, personality)
        or nil
    local loyalty = recruitmentEvaluation
        and recruitmentEvaluation.loyalty
        or math.max(0, math.min(1, tonumber(personality.loyalty) or 0))
    local bravery = recruitmentEvaluation
        and recruitmentEvaluation.bravery
        or math.max(0, math.min(1, tonumber(personality.bravery) or 0))
    local loyaltyPenalty = recruitmentEvaluation
        and recruitmentEvaluation.loyaltyPenalty or loyalty * 20
    local admireScore = recruitmentEvaluation
        and recruitmentEvaluation.admireScore
        or respect * 0.55 + approval * 0.45 - loyaltyPenalty
    local fearScore = recruitmentEvaluation
        and recruitmentEvaluation.fearScore
        or respect * 0.70 + math.max(0, -approval) * 0.30
            - bravery * 25 - loyaltyPenalty
    local normal = approval >= RECRUIT_APPROVAL_MINIMUM
        and respect >= RECRUIT_RESPECT_MINIMUM
        and admireScore >= RECRUIT_SCORE_THRESHOLD
    local fear = approval <= RECRUIT_FEAR_APPROVAL_MAXIMUM
        and respect >= RECRUIT_FEAR_RESPECT_MINIMUM
        and fearScore >= RECRUIT_FEAR_SCORE_THRESHOLD
        and bravery < RECRUIT_FEAR_BRAVERY_MAXIMUM
    local meetsMinimums = approval >= RECRUIT_APPROVAL_MINIMUM
        and respect >= RECRUIT_RESPECT_MINIMUM
    if recruitmentEvaluation then
        normal = recruitmentEvaluation.normal == true
        fear = recruitmentEvaluation.fear == true
        meetsMinimums = recruitmentEvaluation.meetsMinimums == true
    end
    local affiliation = PNC.Factions and PNC.Factions.GetNPCAffiliation
        and PNC.Factions.GetNPCAffiliation(record.id) or nil
    local leader = record.leader == true
        or affiliation and (affiliation.role == "leader"
            or affiliation.rank == "leader" or affiliation.role == "chief")
    if leader and not record.leaderAlone then
        normal, fear = false, false
    end
    local route = normal and "admire" or fear and "fear" or nil
    return {
        eligible = route ~= nil,
        reason = route and "eligible"
            or leader and "leader_active"
            or "relationship_threshold",
        route = route,
        approval = approval,
        respect = respect,
        attitude = recruitmentEvaluation
            and recruitmentEvaluation.attitude or nil,
        score = recruitmentEvaluation and recruitmentEvaluation.score or nil,
        threshold = recruitmentEvaluation
            and recruitmentEvaluation.threshold or RECRUIT_SCORE_THRESHOLD,
        margin = recruitmentEvaluation
            and recruitmentEvaluation.margin or admireScore
                - RECRUIT_SCORE_THRESHOLD,
        meetsMinimums = meetsMinimums,
        admireScore = admireScore,
        fearScore = fearScore,
        loyaltyPenalty = loyaltyPenalty,
        braveryPenalty = recruitmentEvaluation
            and recruitmentEvaluation.braveryPenalty or bravery * 25,
        personalityBreakdown = recruitmentEvaluation
            and recruitmentEvaluation.personalityBreakdown or nil,
        leaderBlocked = leader == true and route == nil,
    }
end

return Recruit
