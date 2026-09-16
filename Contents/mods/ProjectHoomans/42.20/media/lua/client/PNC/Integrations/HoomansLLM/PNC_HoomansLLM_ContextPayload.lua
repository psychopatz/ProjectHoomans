-- Context payload assembly for the client-owned HoomansLLM snapshot.
--
-- The public facade keeps the stable Context API while source selection, actor
-- identity, history, needs, and tool policy live in focused providers.
PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Context = PNC.HoomansLLM.Context or {}

require "PsychopatzCore/Conversation/PsychopatzConversationMessage"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Runtime"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ActorIdentity"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ContextActors"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ContextHistory"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ContextNeeds"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_ContextTools"
require "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Identity"
require "PNC/Semantics/PNC_SemanticLLMResult"
require "PNC/Semantics/PNC_SemanticWorldContext"
require "PNC/Semantics/PNC_SemanticDialogueSituation"

local Internal = PNC.HoomansLLM.Internal
local Payload = Internal.ContextPayload or {}
Internal.ContextPayload = Payload
local Runtime = Internal.Runtime
local Actors = Internal.ContextActors
local History = Internal.ContextHistory
local Needs = Internal.ContextNeeds
local Tools = Internal.ContextTools
local Message = PsychopatzCore.Conversation.Message
local ToolPolicy = PNC.ConversationLLMTools
local MemoryIdentity = PNC.HoomansLLM.Identity
local SemanticResult = PNC.Semantics and PNC.Semantics.LLMResult
local WorldContext = PNC.Semantics and PNC.Semantics.WorldContext
local DialogueSituation = PNC.Semantics
    and PNC.Semantics.DialogueSituation

local function text(value, fallback)
    value = Runtime.Trim(value)
    return value ~= "" and value or fallback
end

local function compactValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 3 then return nil end
    local output = {}
    local count = 0
    local key
    local item
    for key, item in pairs(value) do
        if count >= 24 then break end
        if type(key) == "string" or type(key) == "number" then
            output[key] = compactValue(item, depth + 1)
            count = count + 1
        end
    end
    return output
end

local function topicOf(ir)
    local topic = ir and ir.extensions and ir.extensions.topic or nil
    if type(topic) == "table" then topic = topic.id or topic.key end
    topic = tostring(topic or "")
    return topic ~= "" and topic or nil
end

local function semanticFallbackFor(session, currentMessage)
    local pending = session and session.semanticDialoguePending or nil
    local preview = pending and pending.preview or nil
    local ir = preview and preview.ir or nil
    if type(ir) ~= "table" then return nil end
    local diagnostics = ir.diagnostics or {}
    local interpretation = {
        raw_text = text(pending.rawText or ir.rawText, currentMessage),
        normalized_text = text(ir.normalizedText, nil),
        intent = ir.intent,
        speech_act = ir.speechAct,
        action = ir.action,
        subject = ir.subject,
        actor = compactValue(ir.actor),
        recipient = compactValue(ir.recipient),
        target = compactValue(ir.target),
        object = compactValue(ir.object),
        source = compactValue(ir.source),
        destination = compactValue(ir.destination),
        slots = compactValue(ir.slots),
        modifiers = compactValue(ir.modifiers),
        facts = compactValue(ir.extensions and ir.extensions.facts),
        confidence = tonumber(ir.confidence) or 0,
        confidence_band = ir.confidenceBand,
        topic = topicOf(ir),
        diagnostics = {
            no_match = diagnostics.noMatch == true,
            ambiguous_intent = diagnostics.ambiguousIntent == true,
            ambiguous_concept = diagnostics.ambiguousConcept == true,
            unresolved_entity = diagnostics.unresolvedEntity == true,
            recommended_route = diagnostics.recommendedRoute,
            reason = preview.decision and preview.decision.diagnostics
                and preview.decision.diagnostics.reason or nil,
        },
    }
    return {
        schema_version = 1,
        route = "llm_fallback",
        lua_interpretation = interpretation,
    }
end

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
