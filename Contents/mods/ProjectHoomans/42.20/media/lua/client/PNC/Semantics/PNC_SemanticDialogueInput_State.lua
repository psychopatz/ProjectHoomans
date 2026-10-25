-- Semantic input state, text resolution, and UI-part construction.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Input = PNC.Semantics.DialogueInput
local Internal = Input.Internal
local Text = Internal.Text

function Input.GetState(view)
    if not view or not view.session then
        -- The full-screen view constructs extension parts before it creates
        -- its Session. Keep the field mounted during that short lifecycle
        -- gap; hiding it here makes the widget stay invisible because native
        -- child updates may be skipped while the part is hidden.
        return { visible = view ~= nil, enabled = false, statusText = "" }
    end
    if view.session.llmPending or view.session.semanticDialoguePending then
        return {
            visible = true,
            enabled = false,
            statusText = "",
        }
    end
    return {
        visible = true,
        enabled = Internal.Interactive(view),
        statusText = "",
        sendKey = "llm.send",
    }
end

function Input.ResolveText(key, fallback)
    return Text.Resolve({
        key = key,
        domain = "pnc.system.shared.categories",
        fallback = fallback,
    }, fallback)
end

function Input.IsAvailable()
    return type(PsychopatzConversationLLMInput) == "table"
        and type(PsychopatzConversationLLMInput.new) == "function"
end

function Input.CreatePart(bounds, options)
    if not Input.IsAvailable() then return nil end
    options = options or {}
    local definition = options.definition
    local definitionPartID = type(definition) == "table"
        and definition.partID or nil
    options.partID = options.partID or definitionPartID or "llmInput"
    if options.title == nil and type(definition) == "table" then
        options.title = definition.title
    end
    options.minimumWidth = options.minimumWidth or 280
    options.minimumHeight = options.minimumHeight or 82
    options.submit = options.submit or Input.Submit
    options.getState = options.getState or Input.GetState
    options.resolveText = options.resolveText or Input.ResolveText
    options.maxInputLength = options.maxInputLength or Input.MAX_INPUT_LENGTH
    options.submitOnEnter = options.submitOnEnter ~= false
    options.tooltipKey = options.tooltipKey or "llm.input_tooltip"
    options.sendKey = options.sendKey or "llm.send"
    options.sendTitle = options.sendTitle or "SEND"
    return PsychopatzConversationLLMInput:new(
        bounds.x, bounds.y, bounds.width, bounds.height, options
    )
end

return Input
