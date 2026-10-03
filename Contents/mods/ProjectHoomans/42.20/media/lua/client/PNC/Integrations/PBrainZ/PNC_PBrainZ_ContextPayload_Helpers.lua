local Internal = PNC.PBrainZ.Internal
local Payload = Internal.ContextPayload
local Runtime = Internal.Runtime
local Actors = Internal.ContextActors
local History = Internal.ContextHistory
local Needs = Internal.ContextNeeds
local Tools = Internal.ContextTools
local Message = PsychopatzCore.Conversation.Message
local ToolPolicy = PNC.ConversationLLMTools
local MemoryIdentity = PNC.PBrainZ.Identity
local DialogueFacts = PNC.PBrainZ.ContextPayloadDialogueFacts
local SemanticResult = PNC.Semantics and PNC.Semantics.LLMResult
local WorldContext = PNC.Semantics and PNC.Semantics.WorldContext
local DialogueSituation = PNC.Semantics
    and PNC.Semantics.DialogueSituation

local function text(value, fallback)
    value = Runtime.Trim(value)
    return value ~= "" and value or fallback
end

local function compactValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 3 then return nil end
    local output = {}
    local count = 0
    local key
    local item
    for key, item in pairs(value) do
        if count >= 24 then break end
        if type(key) == "string" or type(key) == "number" then
            output[key] = compactValue(item, depth + 1)
            count = count + 1
        end
    end
    return output
end

local function topicOf(ir)
    local topic = ir and ir.extensions and ir.extensions.topic or nil
    if type(topic) == "table" then topic = topic.id or topic.key end
    topic = tostring(topic or "")
    return topic ~= "" and topic or nil
end

local function semanticFallbackFor(session, currentMessage)
    local pending = session and session.semanticDialoguePending or nil
    local preview = pending and pending.preview or nil
    local ir = preview and preview.ir or nil
    if type(ir) ~= "table" then return nil end
    local diagnostics = ir.diagnostics or {}
    local interpretation = {
        raw_text = text(pending.rawText or ir.rawText, currentMessage),
        normalized_text = text(ir.normalizedText, nil),
        intent = ir.intent,
        speech_act = ir.speechAct,
        action = ir.action,
        subject = ir.subject,
        actor = compactValue(ir.actor),
        recipient = compactValue(ir.recipient),
        target = compactValue(ir.target),
        object = compactValue(ir.object),
        source = compactValue(ir.source),
        destination = compactValue(ir.destination),
        slots = compactValue(ir.slots),
        modifiers = compactValue(ir.modifiers),
        facts = compactValue(ir.extensions and ir.extensions.facts),
        confidence = tonumber(ir.confidence) or 0,
        confidence_band = ir.confidenceBand,
        topic = topicOf(ir),
        diagnostics = {
            no_match = diagnostics.noMatch == true,
            ambiguous_intent = diagnostics.ambiguousIntent == true,
            ambiguous_concept = diagnostics.ambiguousConcept == true,
            unresolved_entity = diagnostics.unresolvedEntity == true,
            recommended_route = diagnostics.recommendedRoute,
            reason = preview.decision and preview.decision.diagnostics
                and preview.decision.diagnostics.reason or nil,
        },
    }
    return {
        schema_version = 1,
        route = "llm_fallback",
        lua_interpretation = interpretation,
    }
end

Internal.ContextPayloadText = text
Internal.ContextPayloadCompactValue = compactValue
Internal.ContextPayloadTopicOf = topicOf
Internal.ContextPayloadSemanticFallback = semanticFallbackFor

return Payload
