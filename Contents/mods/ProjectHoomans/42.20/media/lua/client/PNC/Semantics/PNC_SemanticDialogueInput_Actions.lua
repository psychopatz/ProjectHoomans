-- Side-effect boundary for semantic dialogue actions.
-- Known movement actions use the existing authoritative command transport;
-- task actions use only explicitly registered domain transports.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

local Internal = Input.Internal or {}
Input.Internal = Internal
local CommandAdapter = PNC.Semantics.CommandAdapter
local TaskAdapter = PNC.Semantics.TaskAdapter

function Internal.DispatchAction(view, result, value)
    local decision = result and result.decision or {}
    if not decision.actionIntent then return nil end
    local spec = view and view.spec or {}
    local session = view and view.session
    local actorID = session and session.characterUUID
    local recipientID = spec.npcID
    local context = {
        npcID = spec.npcID,
        targetID = spec.npcID,
        actor = actorID and { id = actorID } or nil,
        recipient = recipientID and { id = recipientID } or nil,
        dialogueID = session and session.conversationID,
        requestID = result.sequence,
        scope = "single",
        rawText = value,
    }
    local commandResult = CommandAdapter.Dispatch(
        decision.actionIntent, context)
    if commandResult.status ~= "unmapped" then return commandResult end
    return TaskAdapter.Dispatch(decision.actionIntent, context)
end

return Input
