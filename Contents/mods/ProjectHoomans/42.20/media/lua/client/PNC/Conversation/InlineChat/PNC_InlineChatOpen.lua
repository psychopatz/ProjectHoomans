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

local function speakOverheadPlayer(player, text)
    if not player or tostring(text or "") == "" then return end
    if PNC.PlayerSpeech and type(PNC.PlayerSpeech.Speak) == "function" then
        pcall(PNC.PlayerSpeech.Speak, player, tostring(text), {
            commandID = "conversation_pause_switch",
            eventID = "pause_switch:player:" .. tostring(getTimestampMs and getTimestampMs() or 0),
            suppressSocialReaction = true,
        })
        return
    end
    if type(player.Say) == "function" then
        pcall(player.Say, player, tostring(text))
    end
end

local function speakOverheadNPC(actor, text)
    if not actor or tostring(text or "") == "" then return end
    local npcID = tostring(actor.id or "")
    local pres = PNC.SemanticSpeechPresentation
    if type(pres) ~= "table" or type(pres.Receive) ~= "function" then
        local ok, loaded = pcall(require, "PNC/Conversation/PNC_SemanticSpeechPresentation")
        if ok and type(loaded) == "table" then pres = loaded end
    end
    if type(pres) == "table" and type(pres.Receive) == "function" and npcID ~= "" then
        local eid = "pause_switch:" .. npcID .. ":" .. tostring(getTimestampMs and getTimestampMs() or 0)
        pcall(pres.Receive, {
            eventID = eid,
            eventRef = eid,
            eventType = "conversation_pause_switch",
            family = "conversation_switch",
            npcID = npcID,
            semanticOwned = true,
            poolID = "semantic.conversation.pause_switch.ack",
            realizationID = "semantic.conversation.pause_switch.ack",
            text = tostring(text),
            resolvedText = tostring(text),
            llmEligible = false,
            memoryEligible = false,
            pumpImmediately = true,
            priority = 80,
            weight = 100,
            ttlMs = 6000,
            cooldowns = { ambientMs = 0, familyMs = 0, speakerMs = 0 },
            context = { npcID = npcID, npcName = tostring(actor.name or npcID) },
        })
    end
end

local function switchInlineTarget(direction)
    if State.mode == Config.MODE_NEARBY then return false end
    local ctrl = loadSwitchController()
    if type(ctrl) ~= "table" or type(ctrl.RequestSpeakerSwitch) ~= "function" then
        return false
    end
    local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
    if not player then return false end
    local scope = Resolver.NormalizeScope(State.scope or Config.SCOPE_COLONISTS)
    local roster = {}
    if Resolver and type(Resolver.CollectNearbyTargets) == "function" then
        local ok, nearby = pcall(Resolver.CollectNearbyTargets, player, nil, scope)
        if ok and type(nearby) == "table" then roster = nearby end
        if #roster < 2 and scope == Config.SCOPE_COLONISTS and Config.SCOPE_SOCIAL then
            local okSocial, socialNearby = pcall(Resolver.CollectNearbyTargets, player, nil, Config.SCOPE_SOCIAL)
            if okSocial and type(socialNearby) == "table" and #socialNearby > #roster then
                roster = socialNearby
            end
        end
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
    local hadConversation = State.hasUserSubmitted == true
    return ctrl.RequestSpeakerSwitch(State.host, direction, {
        roster = roster,
        currentIndex = currentIndex,
        delayMs = hadConversation and ctrl.SWITCH_DELAY_MS or 0,
        skipHandoffLines = not hadConversation,
        skipOpeningLine = not hadConversation,
        onHandoffLines = function(sayLine, ackLine, curActor)
            speakOverheadPlayer(player, sayLine)
            speakOverheadNPC(curActor, ackLine)
        end,
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
    if view and view.session
        and (view.session.busy == true or #(view.session.queue or {}) > 0)
    then
        Diagnostics.LogSubmitRejection(view, "conversation_busy")
        return false, "conversation_busy"
    end
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
    State.mode = Resolver.NormalizeMode(
        State.mode or Config.DEFAULT_MODE or Config.MODE_NEARBY
    )
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
        onQuickReply = function(_, choiceID)
            local host = State.host
            if host and type(host.isConversationInteractive) == "function"
                and not host:isConversationInteractive()
            then
                return false
            end
            if host and host.session
                and (host.session.busy == true or #(host.session.queue or {}) > 0)
            then
                return false
            end
            local matched = nil
            for _, row in ipairs(State.activeQuickReplies or {}) do
                if tostring(row.id or "") == tostring(choiceID or "") then
                    matched = row
                    break
                end
            end
            if not matched or matched._source == "combat_surface" then
                local surface = PNC.ConvoEngine and PNC.ConvoEngine.CombatResponseSurface or nil
                if surface and type(surface.Submit) == "function" then
                    local accepted = surface.Submit(choiceID)
                    if accepted == true then
                        State.hasUserSubmitted = true
                        if State.part and State.part.refreshControls then
                            State.part:refreshControls()
                        end
                    end
                    return accepted == true
                end
            end
            if matched and matched._source == "semantic_host" then
                local accepted = false
                if type(matched.action) == "function" then
                    local ok, res = pcall(matched.action)
                    accepted = ok and res ~= false
                else
                    local input = semanticInput()
                    if input and type(input.SubmitSemanticFrame) == "function" and type(matched.frame) == "table" then
                        local ok, res = pcall(input.SubmitSemanticFrame, State.host, matched.frame)
                        accepted = ok and res == true
                    elseif matched.label and matched.label ~= "" then
                        accepted = InlineChat.Submit(State.host, matched.label, State.part) == true
                    end
                end
                if accepted then
                    State.hasUserSubmitted = true
                    if State.part and State.part.refreshControls then
                        State.part:refreshControls()
                    end
                end
                return accepted
            end
            return false
        end,
    })
    if not part then return reject("input_widget_unavailable") end
    part:initialise()
    part:instantiate()
    part:addToUIManager()
    part:setReveal(1)
    if part.setAlwaysOnTop then part:setAlwaysOnTop(true) end
    State.part = part
    State.toggleKeyHeld = binding ~= nil
    State.suppressReopenUntilRelease = false
    part:refreshControls()
    Targets.RefreshHighlights(0)
    Targets.Position(0, player)
    if part.bringToTop then part:bringToTop() end
    Diagnostics.PrepareFocus(binding)
    return true
end

return Open
