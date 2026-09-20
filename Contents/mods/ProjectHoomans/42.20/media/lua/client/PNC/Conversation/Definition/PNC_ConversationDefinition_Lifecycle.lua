-- Conversation entry points and active-view lifecycle adapters.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Conversation = PNC.Conversation
local Relationship = Conversation.Relationship
local Audience = Conversation.Audience
local Lifecycle = Conversation.Lifecycle
local Composer = Conversation.Composer
local Registry = Conversation.Registry
local IdentityPresentation = PNC.NPCIdentityPresentation
local isAggressive = Audience.IsPlayerHostile

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
    -- Hostile NPCs use the compact nameplate chat route. Opening the full
    -- conversation view first would create a normal scene lease and let the
    -- combat safety gate reject it before the player can type anything.
    -- Keep this handoff targeted to the selected entry so it cannot silently
    -- switch the player to the nearest unrelated NPC.
    if isAggressive(entry)
        and PNC.PBrainZ
        and PNC.PBrainZ.OpenInlineForTarget
        and PNC.PBrainZ.OpenInlineForTarget(entry)
    then
        Relationship.RequestPresentation(npcID)
        if PNC.Client and PNC.Client.RequestNPCKnowledge then
            PNC.Client.RequestNPCKnowledge(npcID)
        end
        return nil
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
    local definition = Conversation.BuildDefinition(entry, player, forcedTime)
    local view = PsychopatzCore.Conversation.Open(definition)
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

function Conversation.ReceiveDisclosureResult(result)
    local view = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
    local preference = result and result.giftPreference or nil
    local reaction = preference and GIFT_PREFERENCE_RESPONSES[
        tostring(preference.disposition or "")
    ] or nil
    if not view or not result
        or tostring(result.npcID) ~= tostring(view.spec and view.spec.npcID)
    then return false end
    if result.success == true and result.responseText
        and view.session and view.session.append
    then
        view.session:append("npc", { fallback = tostring(result.responseText) })
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
