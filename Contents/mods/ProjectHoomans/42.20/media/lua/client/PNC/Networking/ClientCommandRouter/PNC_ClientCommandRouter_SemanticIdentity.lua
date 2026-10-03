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

-- A confirmed identity exchange must reach `ClientState.npcKnowledge` or the
-- world nameplate keeps hiding the NPC even though the portrait plate and the
-- conversation log already show the learned name. The disclosure clock records
-- when the claim was confirmed so the knowledge router can report how long the
-- mirror took, or that it never arrived on this route.
local function markIdentityDisclosurePending(npcID, disclosedName)
    if npcID == "" then return false end
    ClientState.identityDisclosurePending = ClientState.identityDisclosurePending
        or {}
    ClientState.identityDisclosurePending[npcID] = {
        at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
        requestID = ClientState.semanticIdentityResults
            and ClientState.semanticIdentityResults[npcID]
            and ClientState.semanticIdentityResults[npcID].requestID or nil,
        name = disclosedName,
    }
    return true
end

local function auditIdentityResultApplied(args, npcID, disclosedName)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    local knowledge = ClientState.npcKnowledge and ClientState.npcKnowledge[npcID]
    return Diagnostics.Record("semantic.identity.result_applied", {
        requestID = args and args.requestID,
        npcID = npcID,
        disclosedName = disclosedName,
        knowledgeMirrored = knowledge ~= nil,
        presentationState = ClientState.npcPresentations
            and ClientState.npcPresentations[npcID]
            and ClientState.npcPresentations[npcID].state or nil,
    }, { requestID = args and args.requestID })
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

require "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_SemanticIdentityResult"
local identityResultDependencies = {
    auditReceived = auditIdentityResult,
    markDisclosurePending = markIdentityDisclosurePending,
    auditApplied = auditIdentityResultApplied,
    activeViewFor = activeViewFor,
}

Internal.RegisterServerCommand(Const.CMD_SEMANTIC_IDENTITY_RESULT,
    function(args)
        Internal.HandleSemanticIdentityResult(args, identityResultDependencies)
    end)

return PNC.Client
