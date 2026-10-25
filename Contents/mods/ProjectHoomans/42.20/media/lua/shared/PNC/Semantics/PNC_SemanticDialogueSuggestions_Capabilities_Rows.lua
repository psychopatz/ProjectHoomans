PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Suggestions = PNC.Semantics.DialogueSuggestions
local Internal = Suggestions.Internal

local Predicates = Internal.Predicates
local copyValue = Internal.copyValue
local predicateIR = Internal.predicateIR
local normalized = Internal.normalized
local resolvedText = Internal.resolvedText
local normalizeCandidate = Internal.normalizeCandidate
local sourceRecord = Internal.sourceRecord
local capabilityFrame = Internal.capabilityFrame
local companionOrderReason = Internal.companionOrderReason
local isCompanionOrderAction = Internal.isCompanionOrderAction
local appendCampSiteCapabilityRows = Internal.appendCampSiteCapabilityRows
local CAPABILITY_DEFINITIONS = Internal.CAPABILITY_DEFINITIONS

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
                local activeBehavior = type(context.npcState) == "table"
                    and tostring(context.npcState.activeBehavior or "")
                    or ""
                local hideCompletedHomeOrder = action == "GO"
                    and (activeBehavior == "AtHome"
                        or activeBehavior == "AtHome:returning")
                if eligibility.status ~= "private"
                    and not hideIneligibleOrder
                    and not hideCompletedHomeOrder
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



Internal.capabilityRows = capabilityRows

return Suggestions
