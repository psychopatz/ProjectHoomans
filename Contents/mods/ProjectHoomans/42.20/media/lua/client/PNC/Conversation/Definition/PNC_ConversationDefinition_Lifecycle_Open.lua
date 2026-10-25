-- Conversation open and ceasefire entry points.

local Conversation = PNC.Conversation
local Relationship = Conversation.Relationship
local Lifecycle = Conversation.Lifecycle
local IdentityPresentation = PNC.NPCIdentityPresentation
local TalkStart = Conversation.TalkStart
    or require "PNC/Conversation/PNC_ConversationTalkStart"

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
        -- component report. The Hoomans overlay remains the fallback when
        -- a stale Core copy has no native audit panel.
        view.pncRouteSource = "PNC.Conversation.Open [Workshop/ProjectHoomans]"
    end
    -- Core owns the full view, but this route-level marker is intentionally
    -- independent of the Core overlay. It exposes stale/mismatched Core
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
