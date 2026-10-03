-- Client application and delivery of authoritative identity-claim results.

local Internal = PNC.Client.Internal
local ClientState = PNC.Network.ClientState

local function applyIdentityResultState(args, dependencies)
    args = type(args) == "table" and args or {}
    dependencies.auditReceived(args)
    local npcID = tostring(args.npcID or "")
    local pending = ClientState.pendingSemanticIdentity
        and ClientState.pendingSemanticIdentity[npcID]
    if pending and args.requestID and pending ~= args.requestID then
        return nil
    end
    if npcID ~= "" and ClientState.pendingSemanticIdentity then
        ClientState.pendingSemanticIdentity[npcID] = nil
    end

    ClientState.semanticIdentityResults =
        ClientState.semanticIdentityResults or {}
    ClientState.semanticIdentityResults[npcID] = args
    local responseArgs = type(args.responseArgs) == "table"
        and args.responseArgs or {}
    local disclosedName = tostring(responseArgs[2] or "")
    local identityDisclosureConfirmed = args.accepted == true
        and args.kind == "identity_claim"
        and args.truthful == true
        and args.responseKey
            == "UI_PNC_Conversation_Semantic_IdentityExchangeConfirmed"
        and disclosedName ~= ""
    if identityDisclosureConfirmed then
        ClientState.identityDisclosureVerified =
            ClientState.identityDisclosureVerified or {}
        ClientState.identityDisclosureVerified[npcID] = {
            verified = true,
            characterUUID = tostring(ClientState.playerContext
                and ClientState.playerContext.characterUUID or ""),
            displayName = disclosedName,
        }
        dependencies.markDisclosurePending(npcID, disclosedName)
    end
    -- The server ships the canonical identity projection with the accepted
    -- result. Mirror it through the shared knowledge receiver so the world
    -- nameplate learns the same fact the portrait plate already shows.
    if identityDisclosureConfirmed and type(args.presentation) == "table"
        and Internal.ApplyNPCPresentation
    then
        Internal.ApplyNPCPresentation(args.presentation)
    end
    dependencies.auditApplied(args, npcID, disclosedName)
    if args.trustLabel then
        ClientState.identityTrust = ClientState.identityTrust or {}
        ClientState.identityTrust[npcID] = args.trustLabel
    end

    if args.relationship then
        ClientState.conversationRelationships =
            ClientState.conversationRelationships or {}
        ClientState.conversationRelationships[npcID] = args.relationship
        local relationship = PNC.Conversation
            and PNC.Conversation.Relationship
        if relationship and relationship.ReceivePresentation then
            relationship.ReceivePresentation(
                args.relationship,
                args.accepted == true and args.relationshipDelta or nil,
                {
                    source = "semantic_identity",
                    eventID = args.eventID,
                    revision = args.relationshipRevision
                        or args.relationship.revision,
                }
            )
        end
    end

    return {
        args = args,
        npcID = npcID,
        disclosedName = disclosedName,
        confirmed = identityDisclosureConfirmed,
    }
end

local function deliverIdentityResult(context, dependencies)
    local args = context.args
    local npcID = context.npcID
    local disclosedName = context.disclosedName
    local view = dependencies.activeViewFor(npcID)
    if context.confirmed and view and view.spec
        and type(view.spec.context) == "table"
    then
        local viewContext = view.spec.context
        local firstName = string.match(disclosedName, "^(%S+)")
            or disclosedName
        viewContext.identityState = "known"
        viewContext.identityClaimVerified = true
        viewContext.npcName = disclosedName
        viewContext.npcFullName = disclosedName
        viewContext.npcFirstName = firstName
    end
    local unavailableResponse
    if args.accepted ~= true and args.kind == "identity_claim" then
        local semanticInput = PNC.Semantics
            and PNC.Semantics.DialogueInput
        local inputInternal = semanticInput and semanticInput.Internal
        if inputInternal
            and type(inputInternal.IdentityExchangeUnavailableResponse)
                == "function"
        then
            unavailableResponse =
                inputInternal.IdentityExchangeUnavailableResponse()
        end
    end

    if view and view.session and (args.responseText or args.responseKey
        or unavailableResponse)
    then
        local fallback = unavailableResponse
            and unavailableResponse.fallback
            or tostring(args.responseText or "")
        local text = fallback
        local translation = PNC.Translation
        if args.responseKey and translation
            and type(translation.TrFormat) == "function"
        then
            local responseArgs = type(args.responseArgs) == "table"
                and args.responseArgs or {}
            local ok, localized = pcall(
                translation.TrFormat,
                args.responseKey,
                fallback,
                responseArgs[1],
                responseArgs[2],
                responseArgs[3]
            )
            if ok and localized then text = tostring(localized) end
        end
        local response = unavailableResponse or {
            key = args.responseKey,
            text = text ~= "" and text or nil,
            fallback = fallback,
            args = args.responseArgs,
        }
        local metadata = {
            source = {
                kind = "semantic_identity",
                channel = "authoritative_response",
                requestID = args.requestID,
                truthful = args.truthful,
                trustLabel = args.trustLabel,
            },
            provenance = {
                provider = "server",
                parser = "semantic_identity_authority",
                requestID = args.requestID,
            },
        }
        if view.session.queueMessage then
            view.session:queueMessage("npc", response, metadata)
        else
            view.session:append("npc", response, metadata)
        end
    end
end

function Internal.HandleSemanticIdentityResult(args, dependencies)
    local context = applyIdentityResultState(args, dependencies)
    if not context then return end
    deliverIdentityResult(context, dependencies)
end

return Internal
