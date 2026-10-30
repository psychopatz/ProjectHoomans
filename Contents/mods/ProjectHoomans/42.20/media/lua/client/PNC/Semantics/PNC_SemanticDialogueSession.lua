-- Public working-session ownership boundary. Loading this command/query seam
-- never boots the parser, UI, networking, or an optional language provider.
local Session = {}

local function dialogueInput()
    return PNC and PNC.Semantics and PNC.Semantics.DialogueInput or nil
end

function Session.GetActiveView()
    local input = dialogueInput()
    return input and input.ActiveView or nil
end

function Session.ClearWorkingState(session)
    if not session then return end
    session.semanticDialoguePending = nil
    session.semanticDialogueRouter = nil
    session.semanticActorConversationService = nil
    if session.semanticDialogueContext
        and type(session.semanticDialogueContext.Reset) == "function"
    then
        session.semanticDialogueContext:Reset()
    end
    session.semanticDialogueContext = nil
    session.semanticDialogueState = nil
end

function Session.ReleaseView(view)
    local input = dialogueInput()
    if input and input.ActiveView == view then
        input.ActiveView = nil
    end
    if view then
        view.lastSemanticDialogueResult = nil
        view.lastSemanticActionResult = nil
    end
end

return Session
