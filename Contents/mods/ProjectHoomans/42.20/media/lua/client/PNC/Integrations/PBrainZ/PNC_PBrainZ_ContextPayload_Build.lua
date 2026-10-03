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

local text = Internal.ContextPayloadText
local compactValue = Internal.ContextPayloadCompactValue
local topicOf = Internal.ContextPayloadTopicOf
local semanticFallbackFor = Internal.ContextPayloadSemanticFallback

function Payload.Build(view, message)
    local definition = view and view.spec or {}
    local presentation = definition.context or {}
    local block = presentation.conversationBlockContext or {}
    local entry = presentation.entry or {}
    local source = Actors.SourceFor(entry)
    local actor = Actors.ResolveConversation(
        view, entry, source, definition, presentation
    )
    local npcID = actor.npcID
    local dialogueMemoryRecord = entry.record
    if type(dialogueMemoryRecord) ~= "table"
        or type(dialogueMemoryRecord.memory) ~= "table"
    then
        local registry = PNC.Registry
        if registry and type(registry.Get) == "function" then
            local ok, resolved = pcall(registry.Get, npcID)
            if ok and type(resolved) == "table" then
                dialogueMemoryRecord = resolved
            end
        end
    end
    if type(dialogueMemoryRecord) ~= "table" then
        dialogueMemoryRecord = source
    end
    local clientState = actor.clientState
    local playerID = actor.playerID
    local playerAddress = actor.playerAddress
    local npcParts = actor.npcParts
    local playerParts = actor.playerParts
    local npcName = actor.npcName
    local playerName = actor.playerName
    local worldContext = WorldContext and WorldContext.Get and WorldContext.Get({
        player = presentation.player,
    }) or {}
    local worldHours = tonumber(
        worldContext.worldAgeHours
            or Message and Message.GetWorldAgeHours
            and Message.GetWorldAgeHours()
            or presentation.worldAgeHours
    ) or 0
    local lifecycle = presentation.conversationLifecycleState or {}
    local gameDay = tonumber(worldContext.gameDay)
        or Message and Message.GetGameDay
        and Message.GetGameDay(worldHours)
        or math.floor(worldHours / 24)
    local participants = History.CompactParticipants(
        view, npcID, npcName, playerID, playerName
    )
    local relationship = presentation.relationship
        or presentation.relationshipSnapshot
        or PNC.Conversation and PNC.Conversation.Relationship
        and PNC.Conversation.Relationship.GetPresentation
        and PNC.Conversation.Relationship.GetPresentation(npcID)
        or {}
    local reactionCapabilities = clientState.llmReactionCapabilities
        and clientState.llmReactionCapabilities[npcID] or nil
    local availableReactions = reactionCapabilities
        and reactionCapabilities.available_reactions or nil
    if type(availableReactions) ~= "table" then
        availableReactions = ToolPolicy and ToolPolicy.ListAll
            and ToolPolicy.ListAll() or {}
    end
    local capabilityCooldownUntil = reactionCapabilities
        and tonumber(reactionCapabilities.positive_action_cooldown_until)
        or nil
    local capabilityCooldownActive = reactionCapabilities
        and reactionCapabilities.positive_action_cooldown_active == true
        or false
    local capabilityCooldownRemaining = reactionCapabilities
        and tonumber(
            reactionCapabilities.positive_action_cooldown_remaining_hours
        ) or 0
    if capabilityCooldownUntil and worldHours >= capabilityCooldownUntil then
        capabilityCooldownActive = false
        capabilityCooldownRemaining = 0
        availableReactions = {}
        for _, reaction in ipairs(
            ToolPolicy and ToolPolicy.ListAll and ToolPolicy.ListAll() or {}
        ) do
            if reaction ~= "flirt"
                or reactionCapabilities.flirt_available_when_ready == true
            then
                availableReactions[#availableReactions + 1] = reaction
            end
        end
    end
    local personality = block.npcPersonality
        or source.socialProfile
        or source.personality
        or source.social and source.social.personality
        or {}
    local traits = block.npcTraits
    if type(traits) ~= "table"
        and PNC.NPCTraitContext
        and PNC.NPCTraitContext.Collect
    then
        traits = PNC.NPCTraitContext.Collect(source)
    end
    traits = traits or {}
    local preferences = source.preferences or entry.preferences or {}
    local state = Actors.CopyMap(source, {
        "aiState", "activeBehavior", "activeJob", "orderKind", "attackType",
        "inCombat", "attackMode", "healthState", "staminaState",
        "presenceState", "weaponMode", "weaponStatus", "tacticalClass",
    })
    local needs = Needs.Build(npcID, source)
    if needs then state.needs = needs end
    local voiceProfile = PNC.NPCVoice
        and PNC.NPCVoice.GetProfile
        and PNC.NPCVoice.GetProfile(source, entry.zombie)
        or nil
    local characterCard = {
        archetype = text(
            source.archetypeLabel or actor.sourceIdentity.archetypeLabel,
            nil
        ),
        archetype_id = text(
            source.archetypeID or actor.sourceIdentity.archetypeID,
            nil
        ),
        role = text(presentation.factionRole or presentation.npcType, "survivor"),
        traits = traits,
        personality = personality,
        skills = block.npcSkills
            or source.skillLevels
            or source.skills
            or {},
    }
    local definitions = Tools.GetDefinitions(entry)
    local catalogID, availableToolIDs = Tools.CatalogReference(definitions)
    local memoryIdentity = MemoryIdentity.Current()
    local currentMessage = text(message, "")
    local session = view and view.session or {}
    local semanticState = session.semanticDialogueState
    local semanticContext = semanticState
        and type(semanticState.ToContext) == "function"
        and semanticState:ToContext() or nil
    local semanticFallback = semanticFallbackFor(session, currentMessage)
    local semanticFallbackTopic = semanticFallback
        and semanticFallback.lua_interpretation
        and semanticFallback.lua_interpretation.topic
    local semanticInputContext = session.semanticDialoguePending
        and session.semanticDialoguePending.context or {}
    local authoredTopic = text(
        presentation.conversationTopic or block.topic,
        nil
    )
    local currentTopic = authoredTopic
        or semanticFallbackTopic
        or semanticContext and semanticContext.currentTopic
    local dialogueSituation = semanticInputContext.dialogueSituation
        or presentation.dialogueSituation
    if type(dialogueSituation) ~= "table"
        and DialogueSituation
        and type(DialogueSituation.Build) == "function"
    then
        -- Legacy/debug callers may enter the provider path without the
        -- semantic input's pending context. Reconstruct only the bounded
        -- situation projection from authorized presentation sources; never
        -- expose the full NPC record to the payload.
        local ok, projected = pcall(DialogueSituation.Build, {
            npcID = npcID,
            npcRecord = entry.record,
            npcSnapshot = entry.snapshot,
            entry = entry,
            npcPersonality = personality,
            npcTraits = traits,
            relationship = relationship,
            relationshipState = presentation.relationshipState
                or presentation.conversationRelationshipID,
            currentTopic = currentTopic,
            semanticDialogueState = semanticContext,
            worldContext = worldContext,
        })
        if ok and type(projected) == "table" then
            dialogueSituation = projected
        end
    end
    local context = {
        world_uuid = Actors.WorldUUID(),
        world_mode = memoryIdentity.world_mode,
        save_relative_path = memoryIdentity.save_relative_path,
        server_instance_id = memoryIdentity.server_instance_id,
        server_world_generation = memoryIdentity.server_world_generation,
        player_uuid = playerID,
        npc_uuid = npcID,
        conversation_id = session.llmSessionID,
        conversation_token = text(lifecycle.token, nil),
        voice_binding = voiceProfile and {
            npc_uuid = npcID,
            slot = tostring(voiceProfile.prefix or "")
                .. ":" .. tostring(voiceProfile.voiceType or 0),
            pitch = tonumber(voiceProfile.pitch) or 0,
        } or nil,
        audio_presentation = Actors.AudioPresentation(presentation)
            or Actors.AudioPresentation(source),
        npc_name = npcName,
        player_name = playerName,
        player_address_name = playerAddress.addressName,
        player_name_known = playerAddress.known,
        player_is_female = playerAddress.isFemale,
        npc_full_name = npcParts.fullName,
        npc_first_name = npcParts.firstName,
        npc_surname = npcParts.surname,
        player_full_name = playerParts.fullName,
        player_first_name = playerParts.firstName,
        player_surname = playerParts.surname,
        game_day = gameDay,
        world_age_hours = worldHours,
        world_context = worldContext,
        dialogue_situation = compactValue(dialogueSituation),
        semantic_fallback = semanticFallback,
        semantic_entity_index = compactValue(
            semanticInputContext.semanticEntityIndex
        ),
        -- Request-local Lua facts are rendered by PBrainZ as prompt context;
        -- they are not written to its memory store.
        dialogue_facts = compactValue(DialogueFacts.Build(
            dialogueMemoryRecord,
            semanticInputContext,
            playerID,
            session
        )),
        semantic_fact_values = compactValue(
            semanticInputContext.semanticFactValues
        ),
        semantic_dialogue_state = semanticContext,
        participants = participants,
        scene = {
            participants = participants,
            active_participants = participants,
            current_speaker_id = npcID,
            addressed_targets = { playerID },
            current_topic = currentTopic,
        },
        current_topic = currentTopic,
        message = currentMessage,
        character_card = characterCard,
        relationship_snapshot = relationship,
        relationship_capabilities = {
            state = relationship.state or relationship.category,
            revision = relationship.revision,
            available_reactions = availableReactions,
            server_authoritative = true,
            positive_action_cooldown_hours = reactionCapabilities
                and reactionCapabilities.positive_action_cooldown_hours
                or 24,
            positive_action_cooldown_active = reactionCapabilities
                and capabilityCooldownActive or false,
            positive_action_cooldown_remaining_hours =
                capabilityCooldownRemaining,
            flirt_available = reactionCapabilities
                and reactionCapabilities.flirt_available or nil,
            flirt_reason = reactionCapabilities
                and reactionCapabilities.flirt_reason or nil,
            flirt_available_when_ready = reactionCapabilities
                and reactionCapabilities.flirt_available_when_ready or nil,
        },
        preferences = preferences,
        current_state = state,
        recent_conversation = History.Recent(view, currentMessage),
        session_id = session.llmSessionID,
        metadata = {
            source = "project-hoomans",
            relationship_state = text(
                presentation.conversationRelationshipID,
                "unknown"
            ),
            world_age_hours = worldHours,
            game_day = gameDay,
            time_band = worldContext.timeBand,
            needs_revision = needs and needs.revision or nil,
        },
    }
    if SemanticResult and SemanticResult.DescribeContract then
        context.semantic_ir_contract = SemanticResult.DescribeContract()
    end
    if catalogID then
        context.tool_catalog_id = catalogID
        context.available_tool_ids = availableToolIDs
    else
        context.available_tools = definitions
    end
    return context
end


return Payload
