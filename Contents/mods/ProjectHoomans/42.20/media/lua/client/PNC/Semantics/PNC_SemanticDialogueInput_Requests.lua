-- Narrow semantic request contracts for client-owned dialogue integrations.
PNC = PNC or {}

local Requests = {}

function Requests.RequestCognitionForIR(view, ir)
    local subject
    local fact
    local target
    local targetID
    local lifecycle
    local context
    local request
    local session = view and view.session or nil
    if session then
        session.semanticMemoryTargetID = nil
    end
    if type(ir) ~= "table"
        or ir.intent ~= "QUESTION"
    then
        return false, "not_a_fact_question"
    end
    subject = tostring(ir.subject or "")
    if subject == ""
        or subject == "TIME"
        or subject == "DATE"
        or subject == "WEATHER"
        or subject == "IDENTITY"
        or subject == "GIFT_PREFERENCE"
    then
        return false, "local_world_fact"
    end
    fact = ir.extensions and ir.extensions.facts
        and ir.extensions.facts[subject] or nil
    if type(fact) == "table" and fact.status == "known" then
        return false, "fact_already_known"
    end
    target = ir.target
    if type(target) ~= "table" or target.unresolved == true then
        return false, "target_unresolved"
    end
    targetID = target.id or target.entityID or target.npcID
    if tostring(targetID or "") == "" then
        return false, "target_id_unavailable"
    end
    if session then
        session.semanticMemoryTargetID = tostring(targetID)
    end
    context = view and view.spec and view.spec.context or {}
    lifecycle = context and context.conversationLifecycleState or nil
    request = PNC.Client and PNC.Client.RequestSemanticCognition
    if type(request) ~= "function" then
        return false, "cognition_request_unavailable"
    end
    return request(
        view and view.spec and view.spec.npcID,
        {
            subject = subject,
            targetID = targetID,
            conversationToken = lifecycle and lifecycle.token,
        }
    )
end

local function identityClaimName(ir)
    local claim = ir and ir.slots and ir.slots.identityClaim or nil
    return type(claim) == "table" and claim.name or nil
end

local function giftPreferenceFullType(value)
    if type(value) == "table" then
        value = value.fullType or value.itemType or value.value
    end
    value = tostring(value or "")
    if value ~= "" and #value <= 128
        and string.match(value, "^[A-Za-z0-9_.:%-]+$")
        and string.find(value, ".", 1, true)
    then
        return value
    end
    return nil
end

local function giftPreferenceText(value)
    if type(value) == "table" then
        value = value.text or value.name or value.displayName or value.value
    end
    if type(value) == "string" or type(value) == "number" then
        value = tostring(value)
        if value ~= "" and #value <= 128 then return value end
    end
    return nil
end

local function giftPreferenceItemType(ir)
    local object = ir and (ir.object
        or ir.slots and (ir.slots.object or ir.slots.gift)) or nil
    if type(object) == "string" then
        object = { value = object }
    end
    if type(object) ~= "table" then return nil end
    local reference = object.reference
    local fullType
    if type(reference) == "table" then
        fullType = giftPreferenceFullType(reference.fullType)
            or giftPreferenceFullType(reference.itemType)
            or giftPreferenceFullType(reference.value)
            or giftPreferenceFullType(reference.id)
    elseif type(reference) == "string" then
        fullType = giftPreferenceFullType(reference)
    end
    fullType = fullType or giftPreferenceFullType(object.fullType)
        or giftPreferenceFullType(object.itemType)
        or giftPreferenceFullType(object.value)
        or giftPreferenceFullType(object.id)
    if fullType then return fullType end

    local query = giftPreferenceText(object.text)
        or giftPreferenceText(object.value)
        or giftPreferenceText(object.name)
        or giftPreferenceText(object.concept)
        or giftPreferenceText(object.category)
    if not query and type(reference) == "table" then
        query = giftPreferenceText(reference.text)
            or giftPreferenceText(reference.name)
            or giftPreferenceText(reference.concept)
    elseif not query and type(reference) == "string"
    then
        local normalizedReference = string.upper(reference)
        if normalizedReference ~= "THIS" and normalizedReference ~= "IT"
            and normalizedReference ~= "THAT"
        then
            query = giftPreferenceText(reference)
        end
    end
    if not query then return nil end

    local giftSelection = PNC.Semantics
        and PNC.Semantics.GiftSelection or nil
    if type(giftSelection) ~= "table"
        or type(giftSelection.Find) ~= "function"
    then
        local loadedOK
        local loaded
        loadedOK, loaded = pcall(require,
            "PNC/Semantics/PNC_SemanticGiftSelection")
        giftSelection = loadedOK and type(loaded) == "table"
            and loaded or nil
    end
    if not giftSelection or type(giftSelection.Find) ~= "function" then
        return nil
    end
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    local ok, selection = pcall(giftSelection.Find, player, {
        object = { text = query },
    })
    return ok and selection
        and giftPreferenceFullType(selection.fullType) or nil
end

local function pendingIdentity(context)
    local state = context and context.semanticContextState
    return context and context.pendingIdentityExchange
        or state and state.pendingIdentityExchange
        or context and context.semanticDialogueContext
        and context.semanticDialogueContext.pendingIdentityExchange
end

-- Identity disclosure and claims retain their existing network contracts.
function Requests.PrepareIdentityRequest(view, ir, context)
    local npcID = view and view.spec and view.spec.npcID
    local lifecycle = context and context.conversationLifecycleState or nil
    if type(ir) ~= "table" or not npcID then
        return nil
    end

    if ir.intent == "QUESTION" and ir.subject == "GIFT_PREFERENCE" then
        local itemType = giftPreferenceItemType(ir)
        return {
            kind = "gift_preference_disclosure",
            npcID = npcID,
            preferenceItemType = itemType,
            conversationToken = lifecycle and lifecycle.token,
        }
    end

    if ir.intent == "QUESTION" and ir.subject == "IDENTITY" then
        if context.identityTrust == "untrustworthy" then
            return nil
        end
        if context.identityState == "known"
        then
            return nil
        end
        return {
            kind = "identity_disclosure",
            npcID = npcID,
            conversationToken = lifecycle and lifecycle.token,
        }
    end

    if ir.socialContext and ir.socialContext.identityClaim == true then
        return {
            kind = "identity_claim",
            npcID = npcID,
            claimedName = identityClaimName(ir),
            conversationToken = lifecycle and lifecycle.token,
        }
    end

    if pendingIdentity(context)
        and not (ir.intent == "QUESTION" and ir.subject == "IDENTITY")
    then
        return {
            kind = "identity_evasion",
            npcID = npcID,
            conversationToken = lifecycle and lifecycle.token,
        }
    end
    return nil
end

function Requests.DispatchIdentityRequest(request)
    request = type(request) == "table" and request or nil
    local client = PNC.Client
    if not request or not client then return false, "identity_request_unavailable" end
    if request.kind == "identity_disclosure"
        or request.kind == "gift_preference_disclosure"
    then
        if type(client.RequestNPCKnowledgeTopic) ~= "function" then
            return false, "identity_disclosure_unavailable"
        end
        local pending = PNC.Network and PNC.Network.ClientState
            and PNC.Network.ClientState.pendingDisclosure
            and PNC.Network.ClientState.pendingDisclosure[
                tostring(request.npcID)
            ]
        if pending then return false, "identity_request_pending" end
        local topicID = request.kind == "gift_preference_disclosure"
            and "gift_preferences" or "identity_name"
        return client.RequestNPCKnowledgeTopic(
            request.npcID, topicID, {
                conversationToken = request.conversationToken,
                origin = "semantic_dialogue",
                preferenceItemType = request.preferenceItemType,
            }
        )
    end
    if type(client.SubmitSemanticIdentity) ~= "function" then
        return false, "identity_claim_transport_unavailable"
    end
    return client.SubmitSemanticIdentity(request.npcID, {
        kind = request.kind,
        claimedName = request.claimedName,
        conversationToken = request.conversationToken,
        origin = "semantic_dialogue",
    })
end

function Requests.RequestIdentityForIR(view, ir, context, internal)
    internal = internal or Requests
    return internal.DispatchIdentityRequest(
        internal.PrepareIdentityRequest(view, ir, context)
    )
end

return Requests
