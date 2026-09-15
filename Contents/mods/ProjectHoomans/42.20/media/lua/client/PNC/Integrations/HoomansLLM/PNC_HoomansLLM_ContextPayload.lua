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

local function text(value, fallback)
    value = Runtime.Trim(value)
    return value ~= "" and value or fallback
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
    local worldHours = tonumber(
        Message and Message.GetWorldAgeHours and Message.GetWorldAgeHours()
            or presentation.worldAgeHours
    ) or 0
    local lifecycle = presentation.conversationLifecycleState or {}
    local gameDay = Message and Message.GetGameDay
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
        participants = participants,
        scene = {
            participants = participants,
            active_participants = participants,
            current_speaker_id = npcID,
            addressed_targets = { playerID },
            current_topic = text(
                presentation.conversationTopic or block.topic,
                nil
            ),
        },
        current_topic = text(
            presentation.conversationTopic or block.topic,
            nil
        ),
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
            needs_revision = needs and needs.revision or nil,
        },
    }
    if catalogID then
        context.tool_catalog_id = catalogID
        context.available_tool_ids = availableToolIDs
    else
        context.available_tools = definitions
    end
    return context
end

return Payload
