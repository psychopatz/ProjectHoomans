-- Presentation-only filtering for daily What's Up hub rows.
--
-- This module is intentionally stateless. The client owns the ephemeral
-- suppression snapshot and passes it through the bounded suggestion context.
-- No semantic eligibility, parser, policy, or gameplay state is changed here.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Presentation = {}
local HUB_ID = "whats_up"
local HUB_GROUP_ID = "semantic_hub.whats_up"

local function isHubSurface(context, activeHubID)
    return tostring(activeHubID or "") == HUB_ID
        or type(context) == "table"
        and (tostring(context.activeSuggestionGroupID or "")
                == HUB_GROUP_ID
            or tostring(context.semanticSuggestionGroupID or "")
                == HUB_GROUP_ID)
end

function Presentation.FilterCandidates(candidates, context, activeHubID)
    if type(candidates) ~= "table"
        or not isHubSurface(context, activeHubID)
    then
        return candidates, 0
    end

    local presentation = type(context) == "table"
        and context.semanticHubPresentation or nil
    local suppressed = type(presentation) == "table"
        and presentation.suppressedChoices or nil
    if type(suppressed) ~= "table" then
        return candidates, 0
    end

    local output = {}
    local removed = 0
    for index = 1, #candidates do
        local candidate = candidates[index]
        local candidateID = type(candidate) == "table"
            and tostring(candidate.id or candidate.candidateID or "") or ""
        local groupID = type(candidate) == "table"
            and tostring(candidate.groupID or "") or ""
        if groupID == HUB_GROUP_ID
            and candidateID ~= ""
            and suppressed[candidateID] == true
        then
            removed = removed + 1
        else
            output[#output + 1] = candidate
        end
    end
    return output, removed
end

Presentation.HUB_ID = HUB_ID
Presentation.HUB_GROUP_ID = HUB_GROUP_ID

return Presentation
