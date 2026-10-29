-- Scene-specific handoff for an addressed player's existing semantic choices.
-- This reuses the canonical suggestion->IR conversion and only transports
-- meaning to the authoritative waiting Scene; it does not run a second local
-- NPC decision.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Input = PNC.Semantics.DialogueInput
local Internal = Input and Input.Internal or nil
if not Internal then return Input end

local Suggestions = Internal.Suggestions

local function boundedList(values, limit)
    local output = {}
    local seen = {}
    for _, value in ipairs(type(values) == "table" and values or {}) do
        value = tostring(value or "")
        if value ~= "" and #value <= 128 and not seen[value] then
            output[#output + 1] = value
            seen[value] = true
            if #output >= (limit or 8) then break end
        end
    end
    return output
end

local function semanticFromIR(ir)
    ir = type(ir) == "table" and ir or {}
    local extensions = type(ir.extensions) == "table"
        and ir.extensions or {}
    return {
        intent = ir.intent,
        speechAct = ir.speechAct or ir.intent,
        subject = ir.subject,
        topic = extensions.topic or ir.subject,
        action = ir.action,
        modifiers = type(ir.modifiers) == "table"
            and ir.modifiers or {},
        factRefs = boundedList(
            extensions.factRefs
                or extensions.groundedFactRefs
                or ir.factRefs,
            8
        ),
        eventRefs = boundedList(
            extensions.eventRefs
                or extensions.groundedEventRefs
                or ir.eventRefs,
            8
        ),
    }
end

function Internal.SubmitSceneHandoffFrame(view, frame)
    local root = view and view.spec and view.spec.context or nil
    local handoff = root and root.sceneHandoff or nil
    if type(handoff) ~= "table" or handoff.waiting ~= true then
        return false, nil, nil
    end
    if type(frame) ~= "table"
        or tostring(frame.kind or "") ~= "semantic_click_frame"
    then
        return false, nil, nil
    end
    if handoff.submitted == true then
        return true, false, "scene_response_pending"
    end
    if type(Suggestions) ~= "table"
        or type(Suggestions.FrameToIR) ~= "function"
        or type(Suggestions.CheckFrame) ~= "function"
    then
        return true, false, "scene_suggestion_unavailable"
    end

    local ir, irReason = Suggestions.FrameToIR(frame, view)
    if not ir then return true, false, irReason end
    local context = type(Internal.ShallowContext) == "function"
        and Internal.ShallowContext(view) or root
    local eligible, eligibilityReason = Suggestions.CheckFrame(
        frame, context, ir
    )
    if eligible ~= true then
        return true, false, eligibilityReason or "scene_choice_ineligible"
    end

    local semantic = semanticFromIR(ir)
    if semantic.action ~= nil then
        return true, false, "scene_player_action_unsupported"
    end
    if not semantic.intent or tostring(semantic.intent) == "" then
        return true, false, "scene_player_semantic_act_required"
    end
    if type(sendClientCommand) ~= "function"
        or not PNC.Const
        or not PNC.Const.CMD_SEMANTIC_SCENE_RESPONSE
    then
        return true, false, "scene_response_transport_unavailable"
    end

    sendClientCommand(
        PNC.Const.MODULE,
        PNC.Const.CMD_SEMANTIC_SCENE_RESPONSE,
        {
            sceneID = handoff.sceneID,
            expectedSceneSequence = handoff.expectedSceneSequence,
            npcID = handoff.npcID,
            semantic = semantic,
        }
    )
    handoff.submitted = true
    root.sceneResponsePlan = nil
    if type(root.conversationBlockContext) == "table" then
        root.conversationBlockContext.sceneResponsePlan = nil
        root.conversationBlockContext.sceneHandoff = handoff
    end
    return true, true, "scene_response_submitted"
end

return Input
