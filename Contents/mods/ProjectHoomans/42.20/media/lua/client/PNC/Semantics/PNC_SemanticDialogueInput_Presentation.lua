-- Conversation-history and response-queue presentation for semantic input.
-- The existing conversation session remains the authority for ordering and
-- TTS; this module only translates semantic results into queued messages.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput or {}
PNC.Semantics.DialogueInput = Input

local Internal = Input.Internal or {}
Input.Internal = Internal
local Policy = PNC.Semantics.DialoguePolicy

local function responsePayload(decision)
    local response = decision and decision.response or {}
    local fallback = tostring(response.fallback or "")
    return {
        key = response.templateID,
        domain = "pnc.system.shared.categories",
        -- Keep the authored English fallback on the live payload as well as
        -- in the keyed field.  Text.Resolve still gives a registered
        -- translation precedence, but a missing/late domain registration
        -- cannot leak an internal semantic template ID into the UI.
        text = fallback ~= "" and fallback or nil,
        fallback = fallback,
        args = response.args,
    }
end

function Internal.AppendPlayerInput(view, value, result)
    local session = view.session
    local ir = result.ir or {}
    local provenance = ir.provenance or {}
    local topic = ir.extensions and ir.extensions.topic or nil
    topic = type(topic) == "table" and (topic.id or topic.key) or topic
    return session:append("player", value, {
        source = {
            kind = "semantic",
            channel = "input",
            route = result.decision and result.decision.route,
            branch = result.decision and result.decision.branch,
        },
        provenance = {
            provider = provenance.provider,
            parser = provenance.parser,
            pattern = provenance.pattern,
            confidence = ir.confidence,
            topic = topic,
        },
    })
end

function Internal.QueueDeterministicResponse(view, value, result, actionResult)
    local session = view.session
    local pendingChoices = session.currentNode
        and session.currentNode.choices or session.pendingChoices
    local decision = result.decision or {}
    local response = responsePayload(decision)
    local ir = result.ir or {}
    local topic = ir.extensions and ir.extensions.topic or nil
    topic = type(topic) == "table" and (topic.id or topic.key) or topic
    session.pendingChoices = pendingChoices
    session.pendingNext = nil
    session.pendingClose = nil
    session.pendingCloseReason = nil
    session:queueMessage("npc", response, {
        source = {
            kind = "semantic",
            channel = "response",
            branch = decision.branch,
            action = decision.action,
            topic = topic,
            actionResult = actionResult,
            input = tostring(value or ""),
        },
        provenance = {
            provider = "lua",
            parser = "semantic_dialogue_policy",
            branch = decision.branch,
        },
    })
    return true
end

return Input
