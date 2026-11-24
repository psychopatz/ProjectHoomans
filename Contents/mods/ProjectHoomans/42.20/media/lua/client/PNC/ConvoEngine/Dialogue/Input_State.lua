-- Semantic input state, text resolution, and UI-part construction.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}
local Input = PNC.ConvoEngine.DialogueInput
local Internal = Input.Internal
local Text = Internal.Text

local function loadSwitchController()
    local ok, ctrl = pcall(require, "PNC/ConvoEngine/Dialogue/ConversationSwitchAndFarewell")
    if ok and type(ctrl) == "table" then return ctrl end
    return PNC.ConvoEngine and PNC.ConvoEngine.ConversationSwitchAndFarewell or nil
end

local function switchTarget(view, direction)
    local ctrl = loadSwitchController()
    if type(ctrl) ~= "table" or type(ctrl.RequestSpeakerSwitch) ~= "function" then
        return false, "switch_controller_unavailable"
    end
    local roster, currentIndex = ctrl.ResolveSpeakerRoster(view)
    if #roster < 2 then return false, "insufficient_participants" end
    local player = (view and view.spec and view.spec.context and view.spec.context.player)
        or (getSpecificPlayer and getSpecificPlayer(0))
        or (getPlayer and getPlayer()) or nil
    return ctrl.RequestSpeakerSwitch(view, direction, {
        roster = roster,
        currentIndex = currentIndex,
        applySwitch = function(nextActor)
            if not view or not nextActor then return end
            local entry = nextActor
            if PNC.CompanionTargetResolver
                and type(PNC.CompanionTargetResolver.BuildConversationEntry) == "function"
            then
                local okEntry, built = pcall(PNC.CompanionTargetResolver.BuildConversationEntry, nextActor)
                if okEntry and type(built) == "table" then entry = built end
            end
            if PNC.Conversation and type(PNC.Conversation.BuildDefinition) == "function"
                and type(view.refreshConversationSpec) == "function"
            then
                local okDef, nextDef = pcall(PNC.Conversation.BuildDefinition, entry, player)
                if okDef and type(nextDef) == "table" then
                    if type(view.session) == "table" then
                        view.session.speakerRoster = roster
                    end
                    view:refreshConversationSpec(nextDef)
                end
            end
        end,
    })
end

function Input.GetState(view, part)
    if not view or not view.session then
        -- The full-screen view constructs extension parts before it creates
        -- its Session. Keep the field mounted during that short lifecycle
        -- gap; hiding it here makes the widget stay invisible because native
        -- child updates may be skipped while the part is hidden.
        return { visible = view ~= nil, enabled = false, statusText = "", hasMultipleTargets = false }
    end
    local isGroupMode = (type(part) == "table" and part.inputMode == "nearby")
        or (PNC.Conversation and PNC.Conversation.InlineChat
            and PNC.Conversation.InlineChat.State
            and PNC.Conversation.InlineChat.State.part == part
            and PNC.Conversation.InlineChat.State.mode == "nearby")
    local ctrl = loadSwitchController()
    local hasMultiple = false
    if not isGroupMode and type(ctrl) == "table" and type(ctrl.ResolveSpeakerRoster) == "function" then
        local roster = ctrl.ResolveSpeakerRoster(view)
        hasMultiple = type(roster) == "table" and #roster >= 2
    end
    if view.session.llmPending
        or view.session.semanticDialoguePending
        or view.session.busy == true
        or #(view.session.queue or {}) > 0
    then
        return {
            visible = true,
            enabled = false,
            statusText = "",
            hasMultipleTargets = hasMultiple,
        }
    end
    return {
        visible = true,
        enabled = Internal.Interactive(view),
        statusText = "",
        sendKey = "UI_PsychopatzConversation_LLM_Send",
        hasMultipleTargets = hasMultiple,
    }
end

function Input.ResolveText(key, fallback)
    return Text.Resolve({
        key = key,
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
    options.tooltipKey = options.tooltipKey
        or "UI_PsychopatzConversation_LLM_InputTooltip"
    options.sendKey = options.sendKey
        or "UI_PsychopatzConversation_LLM_Send"
    options.sendTitle = options.sendTitle or "SEND"
    options.onPrevTarget = options.onPrevTarget or function(view)
        return switchTarget(view, -1)
    end
    options.onNextTarget = options.onNextTarget or function(view)
        return switchTarget(view, 1)
    end
    return PsychopatzConversationLLMInput:new(
        bounds.x, bounds.y, bounds.width, bounds.height, options
    )
end

return Input
