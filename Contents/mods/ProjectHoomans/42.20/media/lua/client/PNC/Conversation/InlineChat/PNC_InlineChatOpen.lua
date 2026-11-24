-- Inline widget construction and unified semantic-first submit/open actions.
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.Conversation.InlineChat = PNC.Conversation.InlineChat or {}
PNC.Conversation.InlineChat.Internal = PNC.Conversation.InlineChat.Internal or {}

local InlineChat = PNC.Conversation.InlineChat
local Internal = InlineChat.Internal
local Config = Internal.Config
local Resolver = PNC.CompanionTargetResolver
local State = InlineChat.State
local Diagnostics = Internal.Diagnostics
local Targets = Internal.Targets
local Hosts = Internal.Hosts
local Open = Internal.Open or {}
Internal.Open = Open
local LLMInput = PsychopatzConversationLLMInput

local function reject(reason, details)
    if Diagnostics and Diagnostics.LogOpenRejected then
        Diagnostics.LogOpenRejected(reason, details)
    end
    return false
end

local function semanticInput()
    pcall(require, "PNC/ConvoEngine/RuntimeFacade")
    local engine = PNC.ConvoEngine
    local input = engine and engine.DialogueInput or nil
    if input and type(input.Submit) == "function" then return input end
    return nil
end

local function loadSwitchController()
    local ok, ctrl = pcall(require, "PNC/ConvoEngine/Dialogue/ConversationSwitchAndFarewell")
    if ok and type(ctrl) == "table" then return ctrl end
    return PNC.ConvoEngine and PNC.ConvoEngine.ConversationSwitchAndFarewell or nil
end

local function switchInlineTarget(direction)
    local ctrl = loadSwitchController()
    if type(ctrl) ~= "table" or type(ctrl.RequestSpeakerSwitch) ~= "function" then
        return false
    end
    local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
    if not player then return false end
    local roster = {}
    if Resolver and type(Resolver.CollectNearbyTargets) == "function" then
        local ok, nearby = pcall(Resolver.CollectNearbyTargets, player, nil, State.scope or Config.SCOPE_COLONISTS)
        if ok and type(nearby) == "table" then roster = nearby end
    end
    if #roster < 2 and type(State.entries) == "table" and #State.entries >= 2 then
        roster = State.entries
    end
    if #roster < 2 then return false end
    local currentIndex = 1
    for i = 1, #roster do
        if tostring(roster[i] and roster[i].id or "") == tostring(State.targetID or "") then
            currentIndex = i
            break
        end
    end
    return ctrl.RequestSpeakerSwitch(State.host, direction, {
        roster = roster,
        currentIndex = currentIndex,
        applySwitch = function(nextActor)
            if not nextActor then return end
            State.targetID = tostring(nextActor.id or "")
            local nextResolved = { primary = nextActor, targets = { nextActor }, scope = State.scope }
            if Hosts.Rebuild(player, nextResolved, State.mode) then
                if State.part then
                    State.part.owner = State.host
                    if State.part.refreshControls then State.part:refreshControls() end
                end
                Targets.RefreshHighlights(0)
                Targets.Position(0, player)
            end
        end,
    })
end

local function closeInlineAsGoodbye()
    local ctrl = loadSwitchController()
    if type(ctrl) == "table" and type(ctrl.TriggerStandardizedGoodbye) == "function" then
        local actor = State.target or { id = State.targetID }
        ctrl.TriggerStandardizedGoodbye(State.host, function()
            InlineChat.Close("goodbye")
        end, {
            actor = actor,
            salt = "inline:" .. tostring(State.targetID or ""),
        })
        return
    end
    InlineChat.Close("user_closed")
end

function InlineChat.Submit(view, value, part)
    local input = semanticInput()
    local accepted, reason
    if input and type(input.Submit) == "function" then
        accepted, reason = input.Submit(view, value, part)
        if accepted == true then
            State.hasUserSubmitted = true
            local result = view and view.lastSemanticDialogueResult
            local decision = result and result.decision
            local route = decision and decision.route or "deterministic"
            if decision and (decision.branch == "FAREWELL_ACKNOWLEDGED"
                or decision.action == "FAREWELL_ACKNOWLEDGED"
                or decision.closeConversation == true)
            then
                InlineChat.Close("semantic_farewell")
            elseif route == "llm_fallback" then
                InlineChat.Close("message_submitted")
            end
        end
    else
        accepted, reason = false, "semantic_input_unavailable"
    end
    if accepted == true then return true, reason end
    Diagnostics.LogSubmitRejection(view, reason)
    return false, reason
end

function InlineChat.Open(binding)
    local pbrainz = PNC.PBrainZ
    local pending = pbrainz and pbrainz.GetPending and pbrainz.GetPending() or nil
    if pending then
        return reject("request_pending", "npc=" .. tostring(pending.npcID or "unknown"))
    end
    local currentView = Targets.CurrentView()
    if currentView then
        return reject("conversation_active",
            "npc=" .. tostring(currentView.spec and currentView.spec.npcID or "unknown"))
    end
    local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
    if not player then return reject("player_unavailable") end
    if not Resolver then return reject("target_resolver_unavailable") end
    State.mode = Resolver.NormalizeMode(State.mode or Config.MODE_NEAREST)
    State.scope = Resolver.NormalizeScope(State.scope or Config.SCOPE_COLONISTS)
    local resolved = Targets.ResolveRecipients(player)
    local candidate = resolved and resolved.primary
    if not candidate then
        return reject("no_primary_target",
            "mode=" .. tostring(State.mode) .. " scope=" .. tostring(State.scope)
                .. " count=" .. tostring(resolved and #(resolved.targets or {}) or 0))
    end
    if State.part and tostring(State.targetID) == tostring(candidate.id)
        and State.mode == (State.part.inputMode or State.mode)
    then
        Targets.RefreshHighlights(0)
        if State.part.bringToTop then State.part:bringToTop() end
        Diagnostics.PrepareFocus(binding)
        return true
    end
    if State.part then InlineChat.Close("retargeted") end
    local rebuilt, rebuildReason = Hosts.Rebuild(player, resolved)
    if not rebuilt then
        return reject(rebuildReason or "host_rebuild_failed",
            "target=" .. tostring(candidate.id or "unknown"))
    end
    State.hasUserSubmitted = false
    State.nextLifecycleAt = 0
    State.nextContextRefreshAt = 0
    State.nextControlsRefreshAt = 0
    local part = LLMInput:new(0, 0, Config.WIDTH, Config.HEIGHT, {
        owner = State.host,
        partID = "llmInlineInput",
        title = Config.TITLE,
        submit = InlineChat.Submit,
        getState = InlineChat.GetState,
        resolveText = InlineChat.ResolveText,
        maxInputLength = Config.MAX_INPUT_LENGTH,
        submitOnEnter = true,
        tooltipKey = "UI_PsychopatzConversation_LLM_InputTooltip",
        sendKey = "UI_PsychopatzConversation_LLM_Send",
        sendTitle = "UI_PsychopatzConversation_LLM_Send",
        modeButtons = Config.MODE_BUTTONS,
        initialMode = State.mode,
        onModeChanged = InlineChat.SetMode,
        onModeCommitted = Diagnostics.OnModeCommitted,
        onVisualRefresh = Diagnostics.OnVisualRefresh,
        onNativeControlState = Diagnostics.OnNativeControlState,
        toggleButton = Config.SCOPE_TOGGLE,
        initialToggleValue = State.scope == Config.SCOPE_OTHER,
        onToggleChanged = InlineChat.SetScope,
        maxInputLines = 6,
        maxInputHeight = 122,
        showClose = true,
        onClose = closeInlineAsGoodbye,
        closeTitle = "X",
        onPrevTarget = function() return switchInlineTarget(-1) end,
        onNextTarget = function() return switchInlineTarget(1) end,
    })
    if not part then return reject("input_widget_unavailable") end
    part:initialise()
    part:instantiate()
    part:addToUIManager()
    part:setReveal(1)
    if part.setAlwaysOnTop then part:setAlwaysOnTop(true) end
    State.part = part
    part:refreshControls()
    Targets.RefreshHighlights(0)
    Targets.Position(0, player)
    if part.bringToTop then part:bringToTop() end
    Diagnostics.PrepareFocus(binding)
    return true
end

return Open
