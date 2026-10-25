PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local Predicates = Internal.Predicates
local normalized = Internal.normalized
local resolvedText = Internal.resolvedText
local normalizeCandidate = Internal.normalizeCandidate
local sourceRecord = Internal.sourceRecord

local function isCompanionOrderAction(action)
    action = normalized(action)
    return action == "FOLLOW"
        or action == "STAY"
        or action == "GO"
        or action == "CAMP"
        or action == "WAIT_AT"
end

local function companionAuthorityEligible(context)
    local authority = type(context) == "table"
        and context.actorAuthority or nil
    return type(authority) == "table"
        and authority.eligible == true
        and authority.companion == true
        and authority.owned == true
end

local function companionOrderStateEligible(context)
    if not companionAuthorityEligible(context) then return false end
    local state = type(context) == "table"
        and type(context.npcState) == "table" and context.npcState or {}
    local behavior = tostring(state.activeBehavior or "")
    if behavior == "hostile" or behavior == "combat"
        or behavior == "busy" or behavior == "dead"
    then
        return false
    end
    local health = tostring(state.healthState or "")
    return health ~= "dead" and health ~= "incapacitated"
end

local function companionUnavailableReason(context)
    if not companionAuthorityEligible(context) then return nil end
    local state = type(context) == "table"
        and type(context.npcState) == "table" and context.npcState or {}
    local behavior = string.lower(tostring(state.activeBehavior or ""))
    local health = string.lower(tostring(state.healthState or ""))
    if health == "dead" or behavior == "dead" then
        return {
            code = "companion_dead",
            key = "UI_PNC_Conversation_Suggestion_CompanionDead_Tooltip",
            fallback = "Unavailable because the companion is dead.",
        }
    end
    if health == "incapacitated" then
        return {
            code = "companion_incapacitated",
            key = "UI_PNC_Conversation_Suggestion_CompanionIncapacitated_Tooltip",
            fallback = "Unavailable because the companion is incapacitated.",
        }
    end
    if behavior == "hostile" or behavior == "combat"
        or behavior == "busy"
    then
        return {
            code = "companion_busy",
            key = "UI_PNC_Conversation_Suggestion_CompanionBusy_Tooltip",
            fallback = "Unavailable while the companion is busy or in combat.",
        }
    end
    return nil
end

local function companionOrderReason(action, context)
    local unavailable = companionUnavailableReason(context)
    if unavailable then return unavailable end
    local state = type(context) == "table"
        and type(context.npcState) == "table" and context.npcState or {}
    local orderKind = string.lower(tostring(state.orderKind or ""))
    action = normalized(action)
    if action == "FOLLOW" and orderKind == "follow" then
        return {
            code = "already_following",
            key = "UI_PNC_Conversation_Suggestion_AlreadyFollowing_Tooltip",
            fallback = "Already following you.",
        }
    end
    if action == "STAY" and orderKind ~= "follow" then
        if orderKind == "guard" or orderKind == "camp"
            or orderKind == "patrol"
        then
            return {
                code = "already_staying",
                key = "UI_PNC_Conversation_Suggestion_AlreadyStaying_Tooltip",
                fallback = "Already holding position.",
            }
        end
        return {
            code = "not_following",
            key = "UI_PNC_Conversation_Suggestion_NotFollowing_Tooltip",
            fallback = "Stay is available while the companion is following you.",
        }
    end
    return nil
end

local function campSiteCandidates(context)
    return type(context) == "table"
        and (context.campSiteCandidates
            or context.semanticCampSiteCandidates
            or (context.npcState and context.npcState.campSiteCandidates))
        or {}
end

local function campCandidateTarget(candidate)
    local target = type(candidate) == "table"
        and (candidate.target or candidate) or nil
    return type(target) == "table" and target or nil
end

local function campCandidateUsable(candidate)
    local target = campCandidateTarget(candidate)
    return target ~= nil
        and (target.campfireID ~= nil
            or target.siteID ~= nil
            or target.roomID ~= nil)
end

local function firstCampSiteCandidate(candidates)
    if type(candidates) ~= "table" then return nil end
    for index = 1, math.min(#candidates,
        Suggestions.MAX_CAMP_DESTINATIONS) do
        if campCandidateUsable(candidates[index]) then
            return candidates[index]
        end
    end
    return nil
end

local function campSiteCandidateCount(context)
    local candidates = campSiteCandidates(context)
    if type(candidates) ~= "table" then return 0 end
    local count = 0
    for index = 1, math.min(#candidates,
        Suggestions.MAX_CAMP_DESTINATIONS) do
        if campCandidateUsable(candidates[index]) then
            count = count + 1
        end
    end
    return count
end

local function navigationDetails(groupID, context)
    if groupID == Suggestions.COMPANION_ORDERS_GROUP_ID then
        return "companion_orders", "COMPANION_ORDERS"
    end
    if groupID == Suggestions.COMPANION_CAMP_GROUP_ID then
        if campSiteCandidateCount(context) > 0 then
            return "companion_camp", "COMPANION_CAMP"
        end
        return "companion_camp", "COMPANION_CAMP_EMPTY"
    end
    return "topic", "CONVERSATION_TOPIC"
end

local function addGroupNavigationCandidate(
    output,
    seen,
    context,
    revision,
    predicateTrace,
    groupID,
    parentGroupID,
    candidateID,
    labelKey,
    labelFallback,
    reason,
    availability
)
    if seen[candidateID] or #output >= Suggestions.MAX_CANDIDATES then
        return
    end
    local frame = Suggestions.BuildGroupFrame({
        id = groupID,
        labelKey = labelKey,
        label = resolvedText(labelKey, labelFallback),
        allowBack = true,
        parentGroupID = parentGroupID,
        navigationKind = navigationDetails(groupID, context),
        navigationSubject = select(2, navigationDetails(groupID, context)),
        utterance = labelFallback,
    }, revision)
    if not frame then return end
    local available = not availability
        or availability.allowed ~= false
    local status = available and "eligible"
        or "unavailable_" .. tostring(availability.status or "unavailable")
    local availabilityReason = availability and availability.reason or reason
    local source = sourceRecord("conversation_root", revision, reason)
    local candidate = {
        id = candidateID,
        topic = "movement",
        groupID = parentGroupID,
        rank = #output + 1,
        source = source,
        sources = { source },
        frame = frame,
        enabled = available,
        status = status,
        reasonCode = availability and availability.reasonCode or nil,
        reasonKey = availability and availability.reasonKey or nil,
        reasonFallback = availability and availability.reasonFallback or nil,
        display = {
            labelKey = labelKey,
            labelFallback = labelFallback,
            label = resolvedText(labelKey, labelFallback),
        },
        visibility = "player",
        eligibility = {
            status = available and "allowed" or "rejected",
            allowed = available,
            reason = availabilityReason,
            reasonCode = availability and availability.reasonCode or nil,
            reasonKey = availability and availability.reasonKey or nil,
            reasonFallback = availability
                and availability.reasonFallback or nil,
        },
    }
    candidate = normalizeCandidate(candidate, "conversation_root", #output + 1)
    output[#output + 1] = candidate
    seen[candidateID] = candidate
    if #predicateTrace < Predicates.MAX_TRACE then
        predicateTrace[#predicateTrace + 1] = {
            candidateID = candidateID,
            source = "conversation_root",
            path = "actorAuthority.eligible",
            status = "allowed",
            reason = reason,
        }
    end
end

local function appendCompanionOrderNavigation(
    output, seen, context, revision, predicateTrace
)
    if not companionAuthorityEligible(context) then return end
    addGroupNavigationCandidate(
        output,
        seen,
        context,
        revision,
        predicateTrace,
        Suggestions.COMPANION_ORDERS_GROUP_ID,
        Suggestions.ROOT_GROUP_ID,
        "companion.orders:open",
        "UI_PNC_Conversation_Suggestion_CompanionOrders_Label",
        "I need you to do something...",
        "companion_orders_hub"
    )
end

local function appendCompanionCampNavigation(
    output, seen, context, revision, predicateTrace
)
    if not companionAuthorityEligible(context) then return end
    local stateEligible = companionOrderStateEligible(context)
    local available = stateEligible and campSiteCandidateCount(context) > 0
    local availability
    if not available then
        local unavailable = companionUnavailableReason(context)
        availability = stateEligible and {
            allowed = false,
            status = "no_camp_site",
            reason = "no_camp_site",
            reasonCode = "no_camp_site",
            reasonKey =
                "UI_PNC_Conversation_Suggestion_NoCampSite_Tooltip",
            reasonFallback =
                "No valid camp location is currently available.",
        } or {
            allowed = false,
            status = unavailable and unavailable.code
                or "companion_unavailable",
            reason = unavailable and unavailable.code
                or "companion_unavailable",
            reasonCode = unavailable and unavailable.code
                or "companion_unavailable",
            reasonKey = unavailable and unavailable.key or
                "UI_PNC_Conversation_Suggestion_CompanionUnavailable_Tooltip",
            reasonFallback = unavailable and unavailable.fallback
                or "Unavailable because this companion cannot receive orders right now.",
        }
    end
    addGroupNavigationCandidate(
        output,
        seen,
        context,
        revision,
        predicateTrace,
        Suggestions.COMPANION_CAMP_GROUP_ID,
        Suggestions.COMPANION_ORDERS_GROUP_ID,
        "companion.orders:camp",
        "UI_PNC_Conversation_Suggestion_CompanionCamp_Label",
        "Let's camp...",
        "companion_camp_branch",
        availability
    )
end


Internal.isCompanionOrderAction = isCompanionOrderAction
Internal.companionAuthorityEligible = companionAuthorityEligible
Internal.companionOrderStateEligible = companionOrderStateEligible
Internal.companionUnavailableReason = companionUnavailableReason
Internal.companionOrderReason = companionOrderReason
Internal.campSiteCandidates = campSiteCandidates
Internal.campCandidateTarget = campCandidateTarget
Internal.campCandidateUsable = campCandidateUsable
Internal.firstCampSiteCandidate = firstCampSiteCandidate
Internal.campSiteCandidateCount = campSiteCandidateCount
Internal.appendCompanionOrderNavigation = appendCompanionOrderNavigation
Internal.appendCompanionCampNavigation = appendCompanionCampNavigation

return Suggestions
