-- Deterministic ReactionPolicy decision-table evaluator matching (eventType, archetype, relTier).
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ReactionPolicyEvaluator = PNC.ReactionPolicyEvaluator or {}

local Evaluator = PNC.ReactionPolicyEvaluator
local ReactionPolicyRegistry = PNC.ReactionPolicy and PNC.ReactionPolicy.Registry
if not ReactionPolicyRegistry and type(require) == "function" then
    ReactionPolicyRegistry = require "PNC/ReactionPolicy/Registry"
end

local function policyRegistry()
    if PNC.ReactionPolicy and PNC.ReactionPolicy.Registry then
        return PNC.ReactionPolicy.Registry
    end
    return ReactionPolicyRegistry
end

function Evaluator.ResolveRelTier(record, event)
    if type(event) == "table" and event.relTier ~= nil and event.relTier ~= "" then
        return tostring(event.relTier)
    end
    if type(event) == "table" and type(event.payload) == "table"
        and event.payload.relTier ~= nil and event.payload.relTier ~= ""
    then
        return tostring(event.payload.relTier)
    end
    local sourceId = type(event) == "table" and event.sourceId or nil
    if sourceId and PNC.Relationships then
        if type(PNC.Relationships.AreNPCsEnemies) == "function" then
            local srcRec = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(sourceId)
            if srcRec and PNC.Relationships.AreNPCsEnemies(record, srcRec) then
                return "hostile"
            end
        end
        if type(PNC.Relationships.GetTier) == "function" then
            local tier = PNC.Relationships.GetTier(record, sourceId)
            if tier then return tostring(tier) end
        end
    end
    if sourceId and record and record.factionID then
        local srcRec = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(sourceId)
        if srcRec and srcRec.factionID and srcRec.factionID == record.factionID then
            return "friend"
        end
    end
    return "neutral"
end

---Selects best matching compiled ReactionPolicy entry for `(record, event)`.
function Evaluator.Evaluate(record, event)
    if type(record) ~= "table" or type(event) ~= "table" then
        return nil, "INVALID_REACTION_INPUT"
    end
    local eventType = tostring(event.eventType or "")
    if eventType == "" then return nil, "EVENT_TYPE_REQUIRED" end

    local reg = policyRegistry()
    local reactions = reg and reg.reactions or nil
    if type(reactions) ~= "table" then return nil, "REACTION_REGISTRY_UNAVAILABLE" end

    local archetype = tostring(record.archetype or "default")
    local relTier = Evaluator.ResolveRelTier(record, event)

    local best = nil
    local bestSpecificity = -1
    local bestPriority = -1
    for reactionId, spec in pairs(reactions) do
        if type(spec) == "table" and spec.eventType == eventType then
            local specArch = tostring(spec.archetype or "default")
            local specTier = tostring(spec.relTier or "any")
            local archMatches = (specArch == archetype or specArch == "default")
            local tierMatches = (specTier == relTier or specTier == "any")
            if archMatches and tierMatches then
                local specificity = (specArch == archetype and 2 or 1) + (specTier == relTier and 2 or 1)
                local priority = tonumber(spec.priority) or 0
                local replace = false
                if specificity > bestSpecificity then
                    replace = true
                elseif specificity == bestSpecificity and priority > bestPriority then
                    replace = true
                elseif specificity == bestSpecificity and priority == bestPriority
                    and tostring(reactionId) < tostring(best and best.id or "~")
                then
                    replace = true
                end
                if replace then
                    best = spec
                    bestSpecificity = specificity
                    bestPriority = priority
                end
            end
        end
    end
    if not best then return nil, "NO_MATCHING_REACTION" end
    return {
        reaction = best,
        relTier = relTier,
        archetype = archetype,
        specificity = bestSpecificity,
        priority = bestPriority,
    }
end

return Evaluator
