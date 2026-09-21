-- Client presentation for authoritative identity-claim outcomes.
require "PNC/Semantics/PNC_SemanticDiagnostics"

PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Internal = PNC.Client.Internal
local Const = PNC.Const
local ClientState = PNC.Network.ClientState
local Diagnostics = PNC.Semantics
    and PNC.Semantics.SemanticDiagnostics or nil

local function auditIdentityResult(args)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    args = type(args) == "table" and args or {}
    return Diagnostics.Record("semantic.identity.result_received", {
        requestID = args.requestID,
        npcID = args.npcID,
        kind = args.kind,
        accepted = args.accepted == true,
        truthful = args.truthful,
        reason = args.reason,
    }, { requestID = args.requestID })
end

local function activeViewFor(npcID)
    local semanticInput = PNC.Semantics
        and PNC.Semantics.DialogueInput or nil
    local active = semanticInput and semanticInput.ActiveView or nil
    if active and active.session
        and tostring(active.spec and active.spec.npcID or "")
            == tostring(npcID or "")
    then
        return active
    end
    local conversation = PsychopatzCore and PsychopatzCore.Conversation
    local view = conversation and conversation.instance or nil
    if not view or tostring(view.spec and view.spec.npcID or "")
        ~= tostring(npcID or "")
    then
        return nil
    end
    return view
end

Internal.RegisterServerCommand(Const.CMD_SEMANTIC_IDENTITY_RESULT,
    function(args)
        args = type(args) == "table" and args or {}
        auditIdentityResult(args)
        local npcID = tostring(args.npcID or "")
        local pending = ClientState.pendingSemanticIdentity
            and ClientState.pendingSemanticIdentity[npcID]
        if pending and args.requestID and pending ~= args.requestID then return end
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
        end
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

        local view = activeViewFor(npcID)
        if identityDisclosureConfirmed and view and view.spec
            and type(view.spec.context) == "table"
        then
            local context = view.spec.context
            local firstName = string.match(disclosedName, "^(%S+)")
                or disclosedName
            context.identityState = "known"
            context.identityClaimVerified = true
            context.npcName = disclosedName
            context.npcFullName = disclosedName
            context.npcFirstName = firstName
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

    end)

return PNC.Client
