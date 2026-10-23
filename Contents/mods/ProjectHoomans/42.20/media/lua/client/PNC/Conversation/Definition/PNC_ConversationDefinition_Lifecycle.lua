-- Conversation entry points and active-view lifecycle adapters.
pcall(require, "PNC/Conversation/PNC_ConversationRuntimeDebugOverlay")

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Conversation = PNC.Conversation
local Relationship = Conversation.Relationship
local Lifecycle = Conversation.Lifecycle
local Composer = Conversation.Composer
local Registry = Conversation.Registry
local IdentityPresentation = PNC.NPCIdentityPresentation
local TalkStart = Conversation.TalkStart
    or require "PNC/Conversation/PNC_ConversationTalkStart"

local GIFT_PREFERENCE_RESPONSES = {
    like = {
        key = "semantic.gift.preference.like",
        text = "I like that.",
    },
    dislike = {
        key = "semantic.gift.preference.dislike",
        text = "I don't like that.",
    },
    neutral = {
        key = "semantic.gift.preference.neutral",
        text = "I don't have a strong preference.",
    },
    unknown = {
        key = "semantic.gift.preference.unknown",
        text = "I'm not sure which item you mean.",
    },
}

local function auditTalkStart(eventName, projection, extra)
    local diagnostics = PNC.Semantics
        and PNC.Semantics.SemanticDiagnostics or nil
    if not diagnostics or type(diagnostics.Record) ~= "function" then
        return false
    end
    local data = {
        entryID = projection and projection.entryID,
        targetType = projection and projection.targetType,
        tacticalClass = projection and projection.tacticalClass,
        route = projection and projection.route,
        routeReason = projection and projection.routeReason,
        available = projection and projection.availability
            and projection.availability.available,
        availabilityReason = projection and projection.availability
            and projection.availability.reason,
        hostileInlineAvailable = projection
            and projection.hostileInlineAvailable,
        hostileInlineReason = projection
            and projection.hostileInlineReason,
    }
    for key, value in pairs(type(extra) == "table" and extra or {}) do
        data[key] = value
    end
    return diagnostics.Record(eventName, data)
end

function Conversation.RequestCeasefire(context)
    return Lifecycle and Lifecycle.RequestCeasefire
        and Lifecycle.RequestCeasefire(context) or false
end

function Conversation.HandleCeasefireResult(args)
    args = type(args) == "table" and args or {}
    Conversation.lastCeasefireResult = args
    local source = {
        modID = "ProjectHoomans",
        pathPattern = "media/conversation/greetings/hostile/{language}/parley.json",
        domain = "pnc.greetings.hostile.parley",
    }
    Conversation.TextLoader.EnsureSource(source, {
        "result.accepted", "result.rejected",
    })
    local value = PsychopatzCore.Conversation.Text.Resolve({
        key = args.ok == true and "result.accepted" or "result.rejected",
        domain = source.domain,
    })
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    if player and HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, value)
    end
    return args.ok == true, args.reason
end

function Conversation.Open(entry, player, forcedTime)
    local npcID = tostring(entry and entry.id or "debug-npc")
    local talkStart = TalkStart.Project(entry, player, {
        source = "native",
    })
    auditTalkStart("native.talk.start", talkStart)
    -- Hostile NPCs use the compact nameplate chat route. Opening the full
    -- conversation view first would create a normal scene lease and let the
    -- combat safety gate reject it before the player can type anything.
    -- Keep this handoff targeted to the selected entry so it cannot silently
    -- switch the player to the nearest unrelated NPC.
    if talkStart.route == "hostile_inline"
        and PNC.PBrainZ
        and PNC.PBrainZ.OpenInlineForTarget
    then
        local handedOff = PNC.PBrainZ.OpenInlineForTarget(entry)
        auditTalkStart("native.talk.inline_handoff", talkStart, {
            handedOff = handedOff == true,
        })
        if not handedOff then
            -- Continue through the production fallback conversation when the
            -- optional inline provider cannot open its selected target.
            talkStart.route = "hostile_full_conversation"
            talkStart.routeReason = "hostile_inline_handoff_rejected"
        else
            Relationship.RequestPresentation(npcID)
            if PNC.Client and PNC.Client.RequestNPCKnowledge then
                PNC.Client.RequestNPCKnowledge(npcID)
            end
            return nil
        end
    end
    local state = PNC.Network and PNC.Network.ClientState
    if state then
        state.npcPresentations = state.npcPresentations or {}
        local current = state.npcPresentations[npcID]
        if not current or current.state ~= "known" then
            current = current or { npcID = npcID }
            current.npcID = npcID
            if IdentityPresentation.IsNameKnown(entry) then
                current.state = "known"
                current.canAskName = false
                current.knowledgePending = false
                state.npcPresentations[npcID] = current
            else
                -- Unknown identity is a valid conversational state. The
                -- request for the player's latest knowledge is a separate
                -- transport concern and must never replace the category menu.
                if current.state ~= "unknown" then current.state = "unknown" end
                if current.canAskName == nil then current.canAskName = true end
                current.requestState = "loading"
                current.knowledgePending = true
                state.npcPresentations[npcID] = current
            end
        end
    end
    local definition = Conversation.BuildDefinition(
        entry,
        player,
        forcedTime,
        talkStart
    )
    local view = PsychopatzCore.Conversation.Open(definition)
    auditTalkStart("native.talk.view_result", talkStart, {
        opened = view ~= nil,
        conversationID = view and view.session
            and view.session.conversationID or nil,
    })
    if view then
        -- The semantic projection is rendered through Core's native choices
        -- part. Refresh once after Core has created the session; subsequent
        -- semantic turns refresh the same part through the input lifecycle.
        local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
        local internal = input and input.Internal or nil
        -- Keep the just-opened native host discoverable by the same semantic
        -- request/composer path used by later choice clicks. This reference
        -- is runtime-only; it is never persisted or sent over the network.
        if input then input.ActiveView = view end
        if internal and type(internal.RefreshRootSuggestions) == "function" then
            internal.RefreshRootSuggestions(view)
        end
        -- Core's audit panel is created while Core.Open constructs the view,
        -- so publish the route marker on the shared view for its live
        -- component report.  The Hoomans overlay remains the fallback when
        -- a stale Core copy has no native audit panel.
        view.pncRouteSource = "PNC.Conversation.Open [Workshop/ProjectHoomans]"
    end
    -- Core owns the full view, but this route-level marker is intentionally
    -- independent of the Core overlay.  It exposes stale/mismatched Core
    -- copies instead of silently assuming the source trees are loaded.
    local runtimeDebugEnabled = view
        and PsychopatzCore
        and PsychopatzCore.Conversation
        and type(PsychopatzCore.Conversation.IsRuntimeDebugEnabled)
            == "function"
        and PsychopatzCore.Conversation.IsRuntimeDebugEnabled(view.spec)
    if view and runtimeDebugEnabled and not view.debugOverlay
        and PNCConversationRuntimeDebugOverlay
        and type(view.addToUIManager) == "function"
    then
        local overlay = PNCConversationRuntimeDebugOverlay:new(view)
        overlay:initialise()
        overlay:instantiate()
        overlay:addToUIManager()
        if overlay.setAlwaysOnTop then overlay:setAlwaysOnTop(true) end
        if overlay.bringToTop then overlay:bringToTop() end
        view.pncRuntimeDebugOverlay = overlay
    end
    if view and view.setAlwaysOnTop then view:setAlwaysOnTop(true) end
    if view and view.bringToTop then view:bringToTop() end
    Relationship.RequestPresentation(definition.npcID)
    if PNC.Client and PNC.Client.RequestNPCKnowledge then
        PNC.Client.RequestNPCKnowledge(definition.npcID)
    end
    return view
end

local function refreshForNPC(npcID)
    local view = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    if not view or tostring(npcID or "") ~= tostring(view.spec and view.spec.npcID) then
        return false
    end
    local context = view.spec and view.spec.context or {}
    if not context.entry then return false end
    -- Headless Semantic Lab sessions provide the same live session contract
    -- but intentionally omit the native UI definition builder. The receipt
    -- still records the authoritative disclosure and knowledge snapshot;
    -- refreshing a missing UI definition must not turn that receipt into a
    -- client error.
    if type(Conversation.BuildDefinition) ~= "function" then return false end
    local updated = Conversation.BuildDefinition(
        context.entry, context.player, context.conversationTimeID
    )
    local updatedContext = updated.context or {}
    for _, key in ipairs({
        "conversationLifecycleState",
        "pendingConversationRequest",
        "pendingConversationAutoChoice",
        "activeConversationBlockID",
        "lastConversationError",
    }) do
        if context[key] ~= nil then updatedContext[key] = context[key] end
    end
    updated.context = updatedContext
    updated.lifecycle = view.spec.lifecycle or updated.lifecycle
    local activeBlockID = context.activeConversationBlockID
    local activeBlock = activeBlockID and Registry.GetBlock(activeBlockID) or nil
    if activeBlock then
        Composer.AttachBlock(
            updated,
            activeBlock,
            updatedContext.conversationBlockContext
        )
    end
    if not view.refreshConversationSpec
        or view:refreshConversationSpec(updated) ~= true
    then
        return false
    end
    local input = PNC.Semantics and PNC.Semantics.DialogueInput or nil
    local internal = input and input.Internal or nil
    if internal and type(internal.RefreshRootSuggestions) == "function" then
        internal.RefreshRootSuggestions(view)
    end
    -- Core refreshes the session and portrait, while extension parts are
    -- owned by this integration. Keep the live relationship graph in sync
    -- when its authoritative presentation arrives after the window opened.
    for _, extension in ipairs(updated.extensionParts or {}) do
        local part = view.extensionParts
            and view.extensionParts[extension.partID] or nil
        if part and extension.partID == "relationship"
            and part.setRelationship
        then
            part:setRelationship(extension.relationship)
        end
    end
    return true
end

-- Relationship receipt is composed before this definition. Register the
-- narrow active-view refresh callback so receipt does not call back into the
-- whole Conversation definition module.
if type(Relationship.SetConversationRefreshHandler) == "function" then
    Relationship.SetConversationRefreshHandler(refreshForNPC)
end

function Conversation.ReceiveKnowledgeSnapshot(snapshot)
    return snapshot and refreshForNPC(snapshot.npcID) or false
end

function Conversation.ReceiveIdentityPresentation(presentation)
    return presentation and refreshForNPC(presentation.npcID) or false
end

local function localizedBackstoryContent(result, kind)
    local registry = PNC.Registry
    local memory = PNC.Conversation and PNC.Conversation.Memory or nil
    local record = registry and type(registry.Get) == "function"
        and registry.Get(result.npcID) or nil
    if type(record) ~= "table" or type(memory) ~= "table"
        or type(memory.GetBackstory) ~= "function"
        or type(memory.GetBackstoryText) ~= "function"
    then
        return nil
    end
    local fact = memory.GetBackstory(record, kind)
    if type(fact) ~= "table" then return nil end
    local language = "EN"
    if Translator and type(Translator.getLanguage) == "function" then
        local languageValue = Translator.getLanguage()
        if languageValue and type(languageValue.toString) == "function" then
            language = tostring(languageValue:toString())
        end
    end
    local content = memory.GetBackstoryText(fact, language) or fact.value
    if type(memory.RenderText) == "function" then
        content = memory.RenderText(content, fact)
    end
    return type(content) == "string" and content ~= "" and content or nil
end

local function disclosureResponsePayload(result)
    local topicID = tostring(result and result.topicID or "")
    if string.sub(topicID, 1, 10) ~= "backstory." then return nil end
    local input = PNC.Semantics and PNC.Semantics.DialogueInput
    local internal = input and input.Internal or nil
    local responsePayload = internal
        and internal.ResponsePayload or nil
    local catalog = PNC.Semantics and PNC.Semantics.ResponseCatalog or nil
    if type(responsePayload) ~= "function"
        or type(catalog) ~= "table"
        or type(catalog.Select) ~= "function"
    then
        return nil
    end
    local kind = string.sub(topicID, 11)
    local poolID
    if result.success == true then
        if type(result.responsePoolID) == "string"
            and result.responsePoolID ~= "" then
            poolID = result.responsePoolID
        else
            poolID = "semantic.question.backstory.known." .. kind
        end
    else
        poolID = "semantic.question.backstory.refusal"
    end
    local variant = catalog.Select(poolID, {
        npcID = result.npcID,
        topic = "NPC_BACKSTORY",
        subject = "NPC_BACKSTORY",
    }, result.requestID)
    if type(variant) ~= "table"
        and result.success == true
        and poolID ~= "semantic.question.backstory.known." .. kind then
        poolID = "semantic.question.backstory.known." .. kind
        variant = catalog.Select(poolID, {
            npcID = result.npcID,
            topic = "NPC_BACKSTORY",
            subject = "NPC_BACKSTORY",
        }, result.requestID)
    end
    if type(variant) ~= "table" then return nil end
    local content = result.success == true
        and localizedBackstoryContent(result, kind) or result.responseText
    local response = {
        templateID = variant.templateID,
        fallback = variant.fallback,
        args = result.success == true and {
            kind = kind,
            content = content,
        } or {},
        dialogueAct = variant.dialogueAct or "FACT_ANSWER",
        topic = "NPC_BACKSTORY",
        uncertainty = result.success == true and "known" or "refused",
        tone = result.success == true and "direct" or "guarded",
        groundedFactRefs = { "backstory." .. kind },
    }
    return responsePayload({ response = response })
end

function Conversation.ReceiveDisclosureResult(result)
    local view = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    local preference = result and result.giftPreference or nil
    local reaction = preference and GIFT_PREFERENCE_RESPONSES[
        tostring(preference.disposition or "")
    ] or nil
    local function recordBackstoryResponse(text)
        local topicID = tostring(result and result.topicID or "")
        local session = view and view.session or nil
        local context = session and session.semanticDialogueContext or nil
        if string.sub(topicID, 1, 10) ~= "backstory."
            or type(text) ~= "string" or text == ""
            or not context or type(context.RecordNPCResponse) ~= "function"
        then return end
        context:RecordNPCResponse({
            intent = "RESPONSE",
            speechAct = "ANSWER",
            subject = "NPC_BACKSTORY",
            rawText = text,
            extensions = { topic = topicID },
        }, {
            speaker = "npc",
            source = "knowledge_disclosure",
            branch = "QUESTION_RECEIVED",
            topic = topicID,
        })
    end
    if not view or not result
        or tostring(result.npcID) ~= tostring(view.spec and view.spec.npcID)
    then return false end
    local translatedPayload = disclosureResponsePayload(result)
    if translatedPayload
        and view.session and view.session.append
    then
        local responseText = translatedPayload.text
            or translatedPayload.fallback
            or result.responseText
        view.session:append("npc", translatedPayload)
        recordBackstoryResponse(responseText)
    elseif result.responseText
        and view.session and view.session.append
    then
        local responseText = tostring(result.responseText)
        view.session:append("npc", { fallback = responseText })
        recordBackstoryResponse(responseText)
    elseif result.success == true and reaction
        and view.session and view.session.append
    then
        view.session:append("npc", {
            key = reaction.key,
            domain = "pnc.system.shared.categories",
            text = reaction.text,
            fallback = reaction.text,
        })
    elseif result.success ~= true
        and tostring(result.topicID or "") == "gift_preferences"
        and (result.reason == "preference_item_required"
            or result.reason == "invalid_gift_item_type"
            or result.reason == "gift_preference_unavailable"
            or result.reason == "marketsense_unavailable")
        and view.session and view.session.append
    then
        local unknown = GIFT_PREFERENCE_RESPONSES.unknown
        view.session:append("npc", {
            key = unknown.key,
            domain = "pnc.system.shared.categories",
            text = unknown.text,
            fallback = unknown.text,
        })
    end
    return refreshForNPC(result.npcID)
end

return Conversation
