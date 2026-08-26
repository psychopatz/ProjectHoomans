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
    return tacticalClass == Const.FACTION_NEUTRAL
        or tacticalClass == Const.FACTION_HOSTILE
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
    if tacticalClass == Const.FACTION_HOSTILE then
        return { eligible = false, reason = "hostile_audience" }
    end
    local approval = tonumber(relationship.approval) or 0
    local respect = tonumber(relationship.respect) or 0
    local personality = record.personality or record.socialProfile or {}
    local loyalty = math.max(0, math.min(1,
        tonumber(personality.loyalty) or 0))
    local bravery = math.max(0, math.min(1,
        tonumber(personality.bravery) or 0))
    local loyaltyPenalty = loyalty * 20
    local admireScore = respect * 0.55 + approval * 0.45
        - loyaltyPenalty
    local fearScore = respect * 0.70
        + math.max(0, -approval) * 0.30
        - bravery * 25 - loyaltyPenalty
    local normal = approval >= 25 and respect >= 35 and admireScore >= 60
    local fear = approval <= -30 and respect >= 70
        and fearScore >= 60 and bravery < 0.85
    local affiliation = PNC.Factions and PNC.Factions.GetNPCAffiliation
        and PNC.Factions.GetNPCAffiliation(record.id) or nil
    local leader = record.leader == true
        or affiliation and (affiliation.role == "leader"
            or affiliation.rank == "leader" or affiliation.role == "chief")
    if leader and not record.leaderAlone then
        normal, fear = false, false
    end
    local route = normal and "admire" or fear and "fear" or nil
    local evaluation = Graph and Graph.Evaluate
        and Graph.Evaluate(approval, respect, "recruit") or nil
    return {
        eligible = route ~= nil,
        reason = route and "eligible"
            or leader and "leader_active"
            or "relationship_threshold",
        route = route,
        approval = approval,
        respect = respect,
        attitude = evaluation and evaluation.attitude or nil,
        score = evaluation and evaluation.finalScore or nil,
        threshold = evaluation and evaluation.threshold or 35,
        admireScore = admireScore,
        fearScore = fearScore,
        loyaltyPenalty = loyaltyPenalty,
        leaderBlocked = leader == true and route == nil,
    }
end

return Recruit
