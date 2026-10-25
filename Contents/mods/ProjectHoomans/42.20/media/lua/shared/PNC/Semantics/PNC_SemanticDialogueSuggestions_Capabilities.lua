-- Internal implementation spoke for semantic dialogue suggestions.
-- The public entry point remains PNC_SemanticDialogueSuggestions.lua.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local Predicates = Internal.Predicates
local ChoiceRegistry = Internal.ChoiceRegistry
local StaticProvider = Internal.StaticProvider
local CapabilityProvider = Internal.CapabilityProvider
local CampSite = Internal.CampSite
local copyValue = Internal.copyValue
local predicateIR = Internal.predicateIR
local normalized = Internal.normalized
local resolvedText = Internal.resolvedText
local normalizeCandidate = Internal.normalizeCandidate
local sourceRecord = Internal.sourceRecord
local capabilityDefinitionFor = Internal.capabilityDefinitionFor
local projectedCapabilityFor = Internal.projectedCapabilityFor
local CAPABILITY_DEFINITIONS = Internal.CAPABILITY_DEFINITIONS
local CAMP_HERE_TEXT_KEY = Internal.CAMP_HERE_TEXT_KEY
local CAMP_CAMPFIRE_TEXT_KEY = Internal.CAMP_CAMPFIRE_TEXT_KEY
local CAMP_ROOM_TEXT_KEY = Internal.CAMP_ROOM_TEXT_KEY

local function isActiveHubDefinition(definition, activeHubID)
    if type(definition) ~= "table" or activeHubID == nil then return false end
    local extensions = type(definition.extensions) == "table"
        and definition.extensions or {}
    return extensions.route == "semantic_hub"
        and tostring(extensions.hubID or "") == activeHubID
end

local function isActiveHubCandidate(candidate, activeHubID)
    if type(candidate) ~= "table" or activeHubID == nil then return false end
    local frame = type(candidate.frame) == "table" and candidate.frame or {}
    local extensions = type(frame.extensions) == "table"
        and frame.extensions or {}
    return extensions.route == "semantic_hub"
        and tostring(extensions.hubID or "") == activeHubID
end

local function sourceRecord(kind, revision, reason)
    return {
        kind = kind,
        revision = revision,
        reason = reason,
    }
end

local function capabilityFrame(action, definition, revision)
    return {
        schemaVersion = Suggestions.VERSION,
        kind = "semantic_click_frame",
        candidateID = definition.id,
        topic = definition.topic,
        intent = "REQUEST",
        speechAct = "REQUEST",
        action = action,
        groupID = definition.groupID,
        textKey = definition.utteranceKey,
        textFallback = definition.utteranceFallback,
        labelKey = definition.labelKey,
        target = copyValue(definition.target)
            or { kind = "conversation_actor", ref = "npc" },
        destination = copyValue(definition.destination),
        slots = {
            npcID = { kind = "conversation_actor", ref = "npc" },
        },
        requestRevision = revision,
    }
end

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

local function campTargetForCandidate(candidate)
    local target = copyValue(campCandidateTarget(candidate))
    local campfire
    if type(target) ~= "table" then return nil, false end
    campfire = target.campfireID ~= nil or target.kind == "campfire"
    if campfire then
        target.kind = "camp_site"
        target.scope = target.scope or "campfire"
        target.siteScope = target.siteScope or target.scope
    end
    return target, campfire
end

local function campDisplayLabel(candidate, target, campfire)
    local label
    if campfire then return "campfire" end
    if CampSite and type(CampSite.DisplayLabel) == "function" then
        label = CampSite.DisplayLabel(target or candidate)
        if label and label ~= "" then return label end
    end
    return candidate and (candidate.label or candidate.roomName
        or candidate.roomType) or "room"
end

local function campDisplayText(candidate, target, campfire, automatic)
    local label
    local text
    if automatic then
        return resolvedText(CAMP_HERE_TEXT_KEY, "Let's camp here.")
    end
    if candidate and (candidate.utterance or candidate.displayText) then
        return candidate.utterance or candidate.displayText
    end
    label = campDisplayLabel(candidate, target, campfire)
    if campfire then
        return resolvedText(
            CAMP_CAMPFIRE_TEXT_KEY,
            "Let's camp by the campfire."
        )
    end
    text = resolvedText(
        CAMP_ROOM_TEXT_KEY,
        "Let's camp in the %1."
    )
    return string.gsub(text, "%%1", function()
        return tostring(label)
    end, 1)
end

local function appendCampCapabilityRow(
    rows, revision, context, candidate, stateEligible,
    disabledCode, disabledKey, disabledFallback, automatic
)
    local target
    local campfire
    local targetKey
    local candidateID
    local displayText
    local definition
    local frame
    local rowAvailable
    local rowStatus
    local rowReasonCode
    local rowReasonKey
    local rowReasonFallback
    if automatic then
        target = {
            kind = CampSite.KIND or "camp_site",
            scope = CampSite.SCOPES.HERE or "here",
            siteScope = CampSite.SCOPES.HERE or "here",
        }
        if campCandidateUsable(candidate) then
            local candidateTarget = campCandidateTarget(candidate)
            local hint = candidateTarget.clientHint or candidateTarget
            if type(hint) == "table" then
                target.clientHint = copyValue(hint)
            end
        end
        candidateID = "action.camp_here"
        targetKey = "auto"
    else
        target, campfire = campTargetForCandidate(candidate)
        if not target then return false end
        if campfire then
            targetKey = target.campfireID
        elseif target.siteID ~= nil and target.roomID ~= nil then
            targetKey = tostring(target.siteID) .. "|"
                .. tostring(target.roomID)
        else
            targetKey = target.roomID or target.siteID
        end
        candidateID = candidate.id
            or ("action.camp_site:" .. tostring(targetKey or "unknown"))
    end
    displayText = campDisplayText(candidate, target, campfire, automatic)
    rowAvailable = stateEligible and campCandidateUsable(candidate)
    if rowAvailable then
        rowStatus = "eligible"
        rowReasonCode = "valid_client_camp_site_hint"
    elseif automatic and not campCandidateUsable(candidate)
        and stateEligible
    then
        rowStatus = "unavailable_no_camp_site"
        rowReasonCode = "no_camp_site"
        rowReasonKey = "UI_PNC_Conversation_Suggestion_NoCampSite_Tooltip"
        rowReasonFallback = "No valid camp location is currently available."
    else
        rowStatus = "unavailable_companion"
        rowReasonCode = disabledCode
        rowReasonKey = disabledKey
        rowReasonFallback = disabledFallback
    end
    definition = {
        id = candidateID,
        topic = "movement",
        groupID = Suggestions.COMPANION_CAMP_GROUP_ID,
        labelFallback = displayText,
        utteranceFallback = displayText,
        target = target,
        slots = {
            npcID = { kind = "conversation_actor", ref = "npc" },
        },
    }
    frame = capabilityFrame("CAMP", definition, revision)
    if not frame then return false end
    rows[#rows + 1] = {
        id = candidateID,
        topic = "movement",
        groupID = Suggestions.COMPANION_CAMP_GROUP_ID,
        rank = #rows + 1,
        enabled = rowAvailable,
        status = rowStatus,
        reasonCode = rowReasonCode,
        reasonKey = rowReasonKey,
        reasonFallback = rowReasonFallback,
        frame = frame,
        semanticFrame = frame,
        source = {
            groupID = Suggestions.COMPANION_CAMP_GROUP_ID,
            kind = automatic and "automatic_camp_capability"
                or "permitted_capability",
        },
        text = displayText,
        display = {
            label = displayText,
            utterance = displayText,
            visibility = "player",
        },
        visibility = "player",
        eligibility = {
            status = rowAvailable and "allowed" or "rejected",
            allowed = rowAvailable,
            reasonCode = rowReasonCode,
            reason = rowReasonCode,
            reasonKey = rowReasonKey,
            reasonFallback = rowReasonFallback,
        },
        capability = {
            id = candidateID,
            action = "CAMP",
            source = automatic and "automatic_camp_site"
                or "production_camp_site",
            status = rowStatus,
            groupID = Suggestions.COMPANION_CAMP_GROUP_ID,
            selectionMode = automatic and "auto" or "specific",
            targetKey = targetKey,
        },
    }
    rows[#rows] = normalizeCandidate(
        rows[#rows], "permitted_capability", #rows
    )
    return true
end

local function appendCampSiteCapabilityRows(rows, revision, context, ir)
    local candidates = campSiteCandidates(context)
    if type(candidates) ~= "table" then return end
    local stateEligible = companionOrderStateEligible(context)
    local unavailable = not stateEligible
        and companionUnavailableReason(context) or nil
    local disabledCode = unavailable and unavailable.code
        or "companion_unavailable"
    local disabledKey = unavailable and unavailable.key
        or "UI_PNC_Conversation_Suggestion_CompanionUnavailable_Tooltip"
    local disabledFallback = unavailable and unavailable.fallback
        or "Unavailable because this companion cannot receive orders right now."

    local seen = {}
    local count = 0

    -- The generic action is intentionally first.  It carries the best
    -- observed primitive as a hint, while the target remains scope="here" so
    -- the normal camp resolver owns the final room/campfire choice.
    appendCampCapabilityRow(
        rows, revision, context, firstCampSiteCandidate(candidates),
        stateEligible,
        disabledCode, disabledKey, disabledFallback, true
    )

    for _, candidate in ipairs(candidates) do
        if count >= Suggestions.MAX_CAMP_DESTINATIONS then break end
        if campCandidateUsable(candidate) then
            local target, campfire = campTargetForCandidate(candidate)
            local targetKey
            if campfire then targetKey = target and target.campfireID
            elseif target and target.siteID ~= nil and target.roomID ~= nil then
                targetKey = tostring(target.siteID) .. "|"
                    .. tostring(target.roomID)
            else targetKey = target and (target.roomID or target.siteID) end
            local candidateID = candidate.id
                or ("action.camp_site:" .. tostring(targetKey or count + 1))
            local dedupeKey = tostring(candidateID) .. "|"
                .. tostring(targetKey or "")
            if targetKey ~= nil and not seen[dedupeKey] then
                seen[dedupeKey] = true
                appendCampCapabilityRow(
                    rows, revision, context, candidate, stateEligible,
                    disabledCode, disabledKey, disabledFallback, false
                )
                count = count + 1
            end
        end
    end
end

local function capabilityRows(revision, currentAction, context, ir)
    local catalog = PNC.Semantics and PNC.Semantics.CapabilityCatalog
    if not catalog or type(catalog.ListActions) ~= "function" then
        return {}, sourceRecord(
            "permitted_capability", revision, "catalog_unavailable"
        ), {}
    end

    local rows = {}
    local allowed = 0
    local predicateTrace = {}
    local predicateContext = {}
    for key, value in pairs(type(context) == "table" and context or {}) do
        predicateContext[key] = value
    end
    predicateContext.ir = predicateIR(ir)
    predicateContext.suggestion = {
        destination = context.suggestionDestination,
    }
    for _, row in ipairs(catalog.ListActions()) do
        local action = normalized(row and row.id)
        local definition = CAPABILITY_DEFINITIONS[action]
        if definition and row.dispatchable == true then
            local menuOnlyWhenDestination = definition.menuOnlyWhenDestination
            local hideWithoutDestination = menuOnlyWhenDestination == false
                and action == "WAIT_AT"
                and type(context.suggestionDestination) ~= "table"
            if not hideWithoutDestination then
                local eligibility = Predicates.Evaluate(
                    definition.constraints, predicateContext
                )
                for _, traceRow in ipairs(eligibility.trace or {}) do
                    if #predicateTrace < Predicates.MAX_TRACE then
                        predicateTrace[#predicateTrace + 1] = {
                            capability = action,
                            path = traceRow.path,
                            status = traceRow.status,
                            reason = traceRow.reason,
                        }
                    end
                end
            local authorityEligible = not definition.requiresOwnedCompanion
                or type(context.actorAuthority) == "table"
                and context.actorAuthority.eligible == true
            if definition.requiresOwnedCompanion and not authorityEligible then
                if #predicateTrace < Predicates.MAX_TRACE then
                    predicateTrace[#predicateTrace + 1] = {
                        capability = action,
                        path = "actorAuthority",
                        status = "hidden",
                        reason = type(context.actorAuthority) == "table"
                            and (context.actorAuthority.status or "not_commandable")
                            or "authority_unknown",
                    }
                end
                -- A non-owned or unknown NPC is not an unavailable button.
                -- It is outside the player's discoverable command surface.
            end
            if not (definition.requiresOwnedCompanion and not authorityEligible) then
                local destinationPending = false
                for _, traceRow in ipairs(eligibility.trace or {}) do
                    if traceRow.path == "suggestion.destination"
                        and traceRow.status == "unknown"
                    then
                        destinationPending = true
                    end
                end
                local hideIneligibleOrder = isCompanionOrderAction(action)
                    and eligibility.allowed ~= true
                    and definition.showWhenUnavailable ~= true
                if eligibility.status ~= "private"
                    and not hideIneligibleOrder
                then
                    local binding = type(row.binding) == "table" and row.binding or {}
                    local bindingView = {
                        id = row.bindingID or binding.id,
                        owner = binding.owner or row.owner,
                        route = binding.route or row.route,
                        handlerID = binding.handlerID or row.handlerID,
                        targetScope = row.targetScope,
                        status = row.bindingStatus,
                    }
                    local status
                    if eligibility.allowed == true then
                        status = action == currentAction
                            and "selected_for_preflight" or "eligible"
                    elseif action == "WAIT_AT" and destinationPending
                    then
                        status = action == currentAction
                            and "selected_requires_destination"
                            or "requires_destination"
                    else
                        status = "unavailable_" .. tostring(eligibility.status)
                    end
                    local predicateReason = eligibility.reason
                    local reasonCode = predicateReason
                    local reasonKey
                    local reasonFallback
                    if definition.unavailableReasonCode
                        and definition.unavailableReasonPath
                    then
                        for _, traceRow in ipairs(eligibility.trace or {}) do
                            if traceRow.path
                                    == definition.unavailableReasonPath
                                and traceRow.status == "rejected"
                            then
                                reasonCode = definition.unavailableReasonCode
                                reasonKey = definition.unavailableReasonKey
                                reasonFallback =
                                    definition.unavailableReasonFallback
                                break
                            end
                        end
                    end
                    if eligibility.allowed ~= true
                        and isCompanionOrderAction(action)
                    then
                        local orderReason = companionOrderReason(
                            action, context
                        )
                        if orderReason then
                            reasonCode = orderReason.code
                            reasonKey = orderReason.key
                            reasonFallback = orderReason.fallback
                        end
                    end
                    local capability = {
                        id = definition.id,
                        action = action,
                        source = sourceRecord(
                            "permitted_capability", revision, status
                        ),
                        status = status,
                        enabled = status == "eligible"
                            or status == "selected_for_preflight",
                        reasonCode = reasonCode,
                        reasonKey = reasonKey,
                        reasonFallback = reasonFallback,
                        eligibility = {
                            status = eligibility.status,
                            reason = reasonCode,
                            predicateReason = predicateReason,
                            reasonCode = reasonCode,
                            reasonKey = reasonKey,
                            reasonFallback = reasonFallback,
                            trace = eligibility.trace,
                        },
                        binding = bindingView,
                        topic = definition.topic,
                        groupID = definition.groupID
                            or (isCompanionOrderAction(action)
                                and Suggestions.COMPANION_ORDERS_GROUP_ID
                                or "owned_actions"),
                        frame = capabilityFrame(action, definition, revision),
                        display = {
                            labelKey = definition.labelKey,
                            labelFallback = definition.labelFallback,
                            label = resolvedText(
                                definition.labelKey, definition.labelFallback
                            ),
                            utteranceKey = definition.utteranceKey,
                            utteranceFallback = definition.utteranceFallback,
                            utterance = resolvedText(
                                definition.utteranceKey,
                                definition.utteranceFallback
                            ),
                        },
                        visibility = "player",
                    }
                    capability = normalizeCandidate(
                        capability, "permitted_capability", #rows + 1
                    )
                    rows[#rows + 1] = capability
                    allowed = allowed + 1
                end
            end
            end
        end
    end
    return rows, sourceRecord(
        "permitted_capability", revision,
        allowed > 0 and "registered_dispatchable" or "none_registered"
    ), predicateTrace
end


Internal.isActiveHubDefinition = isActiveHubDefinition
Internal.isActiveHubCandidate = isActiveHubCandidate
Internal.sourceRecord = sourceRecord
Internal.capabilityFrame = capabilityFrame
Internal.isCompanionOrderAction = isCompanionOrderAction
Internal.companionAuthorityEligible = companionAuthorityEligible
Internal.companionOrderStateEligible = companionOrderStateEligible
Internal.campSiteCandidateCount = campSiteCandidateCount
Internal.appendCompanionOrderNavigation = appendCompanionOrderNavigation
Internal.appendCompanionCampNavigation = appendCompanionCampNavigation
Internal.appendCampSiteCapabilityRows = appendCampSiteCapabilityRows
Internal.capabilityRows = capabilityRows

