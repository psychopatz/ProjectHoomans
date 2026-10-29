-- Runtime-only projection for tactical combat response choices while the full
-- conversation UI is closed. The surface owns no semantic/action decisions:
-- rows come from DialogueSuggestions and clicks return through
-- DialogueInput.SubmitSemanticFrame.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Surface = PNC.Semantics.CombatResponseSurface or {}
PNC.Semantics.CombatResponseSurface = Surface

local Suggestions = PNC.Semantics.DialogueSuggestions
    or require "PNC/Semantics/PNC_SemanticDialogueSuggestions"

Surface.active = Surface.active or nil
Surface.UIAdapter = Surface.UIAdapter or nil
Surface.Clock = Surface.Clock or nil
Surface.ConversationProbe = Surface.ConversationProbe or nil

local function now()
    if type(Surface.Clock) == "function" then
        return tonumber(Surface.Clock()) or 0
    end
    if type(getTimeInMillis) == "function" then
        return tonumber(getTimeInMillis()) or 0
    end
    if type(getTimestampMs) == "function" then
        return tonumber(getTimestampMs()) or 0
    end
    return math.floor((os.clock and os.clock() or 0) * 1000)
end

local function boundedList(value, limit)
    local output = {}
    if type(value) ~= "table" then return output end
    for index = 1, math.min(#value, limit or 8) do
        if value[index] ~= nil and tostring(value[index]) ~= "" then
            output[#output + 1] = tostring(value[index])
        end
    end
    return output
end

local function copyContext(value)
    local output = {}
    for key, item in pairs(type(value) == "table" and value or {}) do
        output[key] = item
    end
    return output
end

local function dialogueInput()
    local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
    if type(input) == "table" then return input end
    local ok, loaded = pcall(
        require, "PNC/Semantics/PNC_SemanticDialogueInput"
    )
    return ok and type(loaded) == "table" and loaded or nil
end

local function playerUUID(context)
    local interaction = context and context.interaction
    local state = PNC.Network and PNC.Network.ClientState or {}
    local playerContext = state.playerContext or {}
    local value = type(interaction) == "table"
        and (interaction.playerUUID or interaction.targetID)
        or context and (context.playerUUID or context.characterUUID)
        or playerContext.characterUUID
        or playerContext.playerUUID
    if value ~= nil and tostring(value) ~= "" then return tostring(value) end
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if player and type(player.getUsername) == "function" then
        local ok, username = pcall(player.getUsername, player)
        if ok and username and tostring(username) ~= "" then
            return "player:" .. tostring(username)
        end
    end
    return "player"
end

local function conversationOpen(npcID)
    if type(Surface.ConversationProbe) == "function" then
        return Surface.ConversationProbe(npcID) == true
    end
    local presentation = PNC.SemanticSpeechPresentationInternal
    if presentation
        and type(presentation.ActiveConversationFor) == "function"
    then
        local ok, active = pcall(
            presentation.ActiveConversationFor, tostring(npcID or "")
        )
        if ok then return active == true end
    end
    local conversation = PsychopatzCore
        and PsychopatzCore.Conversation or nil
    local view = conversation and conversation.instance or nil
    return view ~= nil
        and view.closed ~= true
        and view.closing ~= true
        and view.spec ~= nil
        and tostring(view.spec.npcID or "") == tostring(npcID or "")
end

local function hide(reason)
    local adapter = Surface.UIAdapter
    if adapter and type(adapter.Hide) == "function" then
        pcall(adapter.Hide, reason)
    end
    if Surface.active then Surface.active.uiVisible = false end
end

local function show()
    local active = Surface.active
    if not active then return false end
    local adapter = Surface.UIAdapter
    if not adapter or type(adapter.Show) ~= "function" then return false end
    local ok, shown = pcall(adapter.Show, active)
    active.uiVisible = ok and shown ~= false
    return active.uiVisible
end

local function lifecycleFor(receive, eventRef, offerIDs, factRefs)
    local ambient = receive.ambientFlavor or {}
    return {
        schema = "semantic.interaction.lifecycle.v1",
        status = "ACTIVE",
        topic = ambient.topic or receive.eventType or "combat",
        activeBeat = {
            id = ambient.beatID
                or "beat:" .. tostring(receive.eventType or "combat")
                    .. ":" .. eventRef,
            topic = ambient.topic or receive.eventType or "combat",
            act = ambient.act or "QUESTION",
            eventRef = eventRef,
            eventType = receive.eventType,
            responsePlanID = ambient.responsePlanID,
            flowID = ambient.flowID,
            poolID = ambient.poolID or ambient.responsePlanID,
            realizationID = ambient.realizationID,
            factRefs = factRefs,
            offerIDs = offerIDs,
        },
    }
end

local function buildTransientView(receive, lifecycle)
    local context = copyContext(receive.context)
    local npcID = tostring(receive.npcID or "")
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local uuid = playerUUID(context)
    local clientState = PNC.Network and PNC.Network.ClientState or {}
    local snapshot = clientState.snapshots
        and clientState.snapshots[npcID] or nil

    context.npcID = npcID
    context.player = context.player or player
    context.playerUUID = context.playerUUID or uuid
    context.characterUUID = context.characterUUID or uuid
    context.interactionLifecycle = lifecycle
    context.currentTopic = "combat"
    context.actorAuthority = context.actorAuthority or {
        owned = true,
        companion = true,
    }
    context.npcState = context.npcState
        or type(snapshot) == "table" and snapshot
        or { activeBehavior = "FollowOwner" }
    context.combatTacticalPrompt = true
    context.presentationClass = "TACTICAL_PROMPT"

    local session = {
        conversationID = "combat-prompt:"
            .. tostring(lifecycle.activeBeat.eventRef),
        characterUUID = uuid,
        semanticInteractionLifecycle = lifecycle,
    }
    local view = {
        headless = true,
        semanticTransientSurface = true,
        spec = {
            npcID = npcID,
            characterUUID = uuid,
            context = context,
        },
        session = session,
    }
    return view, context
end

local function rowsForProjection(projection, wanted, eventRef)
    local rows = {}
    for _, candidate in ipairs(
        type(projection) == "table" and projection.candidates or {}
    ) do
        local id = tostring(candidate.id or "")
        local frame = candidate.frame
        local origin = type(frame) == "table" and frame.origin or nil
        if wanted[id]
            and type(frame) == "table"
            and tostring(frame.eventRef
                or origin and origin.eventRef or "") == eventRef
        then
            rows[#rows + 1] = {
                id = id,
                label = candidate.display
                    and (candidate.display.label
                        or candidate.display.labelFallback)
                    or id,
                utterance = candidate.display
                    and (candidate.display.utterance
                        or candidate.display.utteranceFallback)
                    or nil,
                frame = frame,
                rank = tonumber(candidate.rank) or #rows + 1,
                enabled = true,
            }
        end
    end
    table.sort(rows, function(a, b)
        return (a.rank or 0) < (b.rank or 0)
    end)
    return rows
end

function Surface.ObserveReceive(receive)
    receive = type(receive) == "table" and receive or {}
    local context = type(receive.context) == "table"
        and receive.context or {}
    local ambient = type(receive.ambientFlavor) == "table"
        and receive.ambientFlavor or {}
    if context.presentationClass ~= "TACTICAL_PROMPT"
        and ambient.presentationClass ~= "TACTICAL_PROMPT"
    then
        return false, "not_tactical_prompt"
    end

    local eventRef = tostring(
        ambient.eventRef or receive.eventID or context.eventRef or ""
    )
    local npcID = tostring(receive.npcID or ambient.npcID or "")
    local offerIDs = boundedList(
        ambient.offerIDs or context.offerIDs, 8
    )
    local factRefs = boundedList(
        ambient.factRefs or context.factRefs, 8
    )
    if eventRef == "" or npcID == ""
        or not ambient.responsePlanID
        or not ambient.realizationID
        or #offerIDs == 0 or #factRefs == 0
    then
        return false, "tactical_prompt_incomplete"
    end

    local lifecycle = lifecycleFor(receive, eventRef, offerIDs, factRefs)
    local view, buildContext = buildTransientView(receive, lifecycle)
    local input = dialogueInput()
    if not input or not input.Internal
        or type(input.Internal.RouterFor) ~= "function"
        or type(input.SubmitSemanticFrame) ~= "function"
    then
        return false, "semantic_input_unavailable"
    end
    local router = input.Internal.RouterFor(view)
    if type(router) ~= "table" or type(router.state) ~= "table" then
        return false, "semantic_router_unavailable"
    end
    local revision = tonumber(router.state.sequence) or 0
    local projectionContext = type(input.Internal.ShallowContext) == "function"
        and input.Internal.ShallowContext(view) or buildContext
    local projection = Suggestions.Build({
        sequence = revision,
        accepted = true,
        ir = {},
        decision = {},
    }, projectionContext, {})
    local wanted = {}
    for _, id in ipairs(offerIDs) do wanted[id] = true end
    local rows = rowsForProjection(projection, wanted, eventRef)
    if #rows == 0 then return false, "tactical_offers_unavailable" end

    view.semanticSuggestions = projection
    local ttlMs = math.max(1000, tonumber(ambient.ttlMs) or 8000)
    hide("replaced")
    Surface.active = {
        eventRef = eventRef,
        npcID = npcID,
        eventType = receive.eventType,
        presentationClass = "TACTICAL_PROMPT",
        responsePlanID = ambient.responsePlanID,
        realizationID = ambient.realizationID,
        offerIDs = offerIDs,
        rows = rows,
        view = view,
        receivedAt = now(),
        expiresAt = now() + ttlMs,
        uiVisible = false,
    }
    if conversationOpen(npcID) then
        return true, "conversation_owns_prompt"
    end
    show()
    return true, "combat_surface_shown"
end

function Surface.Submit(candidateID)
    local active = Surface.active
    if not active then return false, "tactical_prompt_inactive" end
    if now() >= (tonumber(active.expiresAt) or 0) then
        Surface.Clear("tactical_prompt_expired")
        return false, "tactical_prompt_expired"
    end
    if conversationOpen(active.npcID) then
        hide("conversation_owns_prompt")
        return false, "conversation_owns_prompt"
    end
    local row
    for _, candidate in ipairs(active.rows or {}) do
        if tostring(candidate.id) == tostring(candidateID) then
            row = candidate
            break
        end
    end
    if not row or row.enabled == false then
        return false, "tactical_choice_unavailable"
    end
    row.enabled = false
    local input = dialogueInput()
    local accepted, reason = input.SubmitSemanticFrame(
        active.view,
        row.frame,
        { transientCombatSurface = true }
    )
    if accepted == true then
        Surface.Clear("tactical_choice_submitted")
        return true, reason
    end
    row.enabled = true
    if tostring(reason or "") == "suggestion_stale"
        or tostring(reason or "") == "encounter_prompt_stale"
    then
        Surface.Clear(reason)
    end
    return false, reason
end

function Surface.ApplyAuthorityState(args)
    args = type(args) == "table" and args or {}
    local active = Surface.active
    if not active then return false, "tactical_prompt_inactive" end
    if tostring(args.eventRef or "") ~= tostring(active.eventRef) then
        return false, "different_encounter"
    end
    if args.active ~= true
        or tostring(args.intent or "undecided") ~= "undecided"
    then
        Surface.Clear(args.reason or "authority_resolved")
        return true, "tactical_prompt_cleared"
    end
    return true, "authority_still_undecided"
end

function Surface.OnTick()
    local active = Surface.active
    if not active then return false end
    if now() >= (tonumber(active.expiresAt) or 0) then
        Surface.Clear("tactical_prompt_expired")
        return false
    end
    if conversationOpen(active.npcID) then
        if active.uiVisible then hide("conversation_owns_prompt") end
        return true
    end
    if not active.uiVisible then
        show()
    elseif Surface.UIAdapter
        and type(Surface.UIAdapter.Sync) == "function"
    then
        pcall(Surface.UIAdapter.Sync, active)
    end
    return true
end

function Surface.Clear(reason)
    hide(reason or "cleared")
    Surface.active = nil
    return true
end

function Surface.Snapshot()
    local active = Surface.active
    if not active then return nil end
    local rows = {}
    for index, row in ipairs(active.rows or {}) do
        rows[index] = {
            id = row.id,
            label = row.label,
            enabled = row.enabled ~= false,
        }
    end
    return {
        eventRef = active.eventRef,
        npcID = active.npcID,
        presentationClass = active.presentationClass,
        responsePlanID = active.responsePlanID,
        realizationID = active.realizationID,
        offerIDs = boundedList(active.offerIDs, 8),
        rows = rows,
        receivedAt = active.receivedAt,
        expiresAt = active.expiresAt,
        uiVisible = active.uiVisible == true,
    }
end

function Surface.SetUIAdapter(adapter)
    Surface.UIAdapter = type(adapter) == "table" and adapter or nil
    if Surface.active then
        if conversationOpen(Surface.active.npcID) then
            hide("conversation_owns_prompt")
        else
            show()
        end
    end
    return Surface.UIAdapter ~= nil
end

function Surface.SetClock(callback)
    Surface.Clock = type(callback) == "function" and callback or nil
end

function Surface.SetConversationProbe(callback)
    Surface.ConversationProbe = type(callback) == "function" and callback or nil
end

function Surface.ResetRuntime()
    Surface.Clear("runtime_reset")
    Surface.Clock = nil
    Surface.ConversationProbe = nil
end

if type(Events) == "table" and Events.OnTick
    and type(Events.OnTick.Add) == "function"
    and Surface._tickInstalled ~= true
then
    Events.OnTick.Add(function() Surface.OnTick() end)
    Surface._tickInstalled = true
end

return Surface
