-- Context and prompt assembly for ambient social flavor packets.
PNC = PNC or {}
PNC.PBrainZ = PNC.PBrainZ or {}
PNC.PBrainZ.Internal = PNC.PBrainZ.Internal or {}
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_Runtime"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ContextHistory"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ContextActors"
require "PNC/Semantics/PNC_SemanticWorldContext"
require "PNC/Integrations/PBrainZ/PNC_PBrainZ_ContextPayload_DialogueFacts"

local Integration = PNC.PBrainZ
local Context = Integration.Context
local MemoryIdentity = Integration.Identity
local Message = PsychopatzCore.Conversation.Message
local AmbientContext = Integration.Internal.AmbientContext or {}
local History = Integration.Internal.ContextHistory
local ConversationActors = Integration.Internal.ContextActors
Integration.Internal.AmbientContext = AmbientContext
local WorldContext = PNC.Semantics and PNC.Semantics.WorldContext
local DialogueFacts = Integration.ContextPayloadDialogueFacts

local function promptFor(eventType, playerMessage, playerFirstName, victimFirstName)
    if eventType == "player_spoke" and playerMessage ~= "" then
        return (
            "Write one brief in-character reaction because the player just "
            .. "said: \"" .. playerMessage .. "\". Respond naturally to "
            .. "what they said. Use only the player's first name if you "
            .. "address them (" .. playerFirstName .. "). Do not mention "
            .. "being an AI, prompts, or game systems. Keep it under one "
            .. "sentence."
        )
    elseif eventType == "witnessed_teammate_hurt" then
        return (
            "Write one brief in-character reaction because you witnessed "
            .. "your teammate take damage from a zombie. If you address "
            .. "the teammate, use only their first name ("
            .. victimFirstName .. "). Do not use their surname or full name. "
            .. "Do not mention being an AI, prompts, or game systems. "
            .. "Keep it under one sentence."
        )
    end
    return (
        "Write one brief in-character reaction because you witnessed "
        .. "the player kill a zombie. Do not mention being an AI, prompts, "
        .. "or game systems. If you address the player, use only their first "
        .. "name; never repeat their surname or full name. Keep it under one "
        .. "sentence."
    )
end

local function activeConversationView(npcID, playerID)
    local input = PNC.Semantics
        and PNC.Semantics.DialogueInput or nil
    local view = input and input.ActiveView or nil
    local session = view and view.session or nil
    local spec = view and type(view.spec) == "table" and view.spec or {}
    local activeNPCID = session and session.npcID
        or spec.npcID or spec.id
    local activePlayerID = session and session.characterUUID or nil
    if ConversationActors and type(ConversationActors.PlayerUUID) == "function" then
        local ok
        ok, activePlayerID = pcall(
            ConversationActors.PlayerUUID,
            view
        )
        if not ok then activePlayerID = nil end
    end
    if type(session) ~= "table"
        or session.closed == true
        or session.conversationMemoryClosed == true
        or view.lifecycleFinished == true
        or view.closed == true
        or view.closing == true
        or tostring(playerID or "") == ""
        or tostring(playerID or "") == "unbound-player"
        or tostring(playerID or "") == "ambient-player"
        or tostring(activeNPCID or "") ~= tostring(npcID or "")
        or tostring(activePlayerID or "") ~= tostring(playerID or "")
    then
        return nil
    end
    return view
end

function AmbientContext.Build(item, source, npcID, playerID, identity, requestID)
    local victimID = tostring(source.victimNPCID or "")
    local eventType = tostring(source.eventType or item and item.family
        or "ambient_social")
    local playerMessage = tostring(source.playerMessage or "")
    local memoryIdentity = MemoryIdentity.Current()
    -- source.player is normally the resolved display/address name (for
    -- example, "Friend"), not an engine character. Never pass that identity
    -- value into Java-backed world observers.
    local player = source.runtimePlayer
        or source.playerObject
        or getSpecificPlayer and getSpecificPlayer(0)
    local npcRecord = source.npcRecord or source.record
        or source.entry and source.entry.record or nil
    local activeView = activeConversationView(npcID, playerID)
    local activeSession = activeView and activeView.session or nil
    local recentConversation = {}
    if not npcRecord and PNC.Registry
        and type(PNC.Registry.Get) == "function"
    then
        npcRecord = PNC.Registry.Get(npcID)
    end
    local ok
    local dialogueFacts
    if DialogueFacts and type(DialogueFacts.Build) == "function" then
        ok, dialogueFacts = pcall(
            DialogueFacts.Build,
            npcRecord,
            nil,
            playerID,
            activeSession
        )
        if not ok then dialogueFacts = nil end
    end
    if activeView and History and type(History.Recent) == "function" then
        ok, recentConversation = pcall(
            History.Recent,
            activeView,
            playerMessage,
            4,
            160
        )
        if not ok or type(recentConversation) ~= "table" then
            recentConversation = {}
        end
    end
    local worldContext = WorldContext and WorldContext.Get and WorldContext.Get({
        player = player,
    }) or {}
    return {
        world_uuid = Message.GetSaveID(),
        world_mode = memoryIdentity.world_mode,
        save_relative_path = memoryIdentity.save_relative_path,
        server_instance_id = memoryIdentity.server_instance_id,
        server_world_generation = memoryIdentity.server_world_generation,
        player_uuid = playerID,
        npc_uuid = npcID,
        session_id = "pnc_ambient_" .. tostring(requestID),
        npc_name = identity.npcFullName,
        player_name = identity.playerFirstName,
        player_address_name = identity.player.addressName,
        player_name_known = identity.player.known,
        player_is_female = identity.player.isFemale,
        npc_full_name = identity.npcFullName,
        npc_first_name = identity.npcFirstName,
        npc_surname = identity.npcSurname,
        player_full_name = identity.playerFullName,
        player_first_name = identity.playerFirstName,
        player_surname = identity.playerSurname,
        victim_npc_id = victimID ~= "" and victimID or nil,
        victim_name = identity.victimFirstName,
        victim_full_name = identity.victimFullName,
        victim_first_name = identity.victimFirstName,
        victim_surname = identity.victim.surname or "",
        player_message = playerMessage ~= "" and playerMessage or nil,
        world_age_hours = worldContext.worldAgeHours,
        game_day = worldContext.gameDay,
        world_context = worldContext,
        message = promptFor(
            eventType,
            playerMessage,
            identity.playerFirstName,
            identity.victimFirstName
        ),
        character_card = {},
        relationship_snapshot = {
            state = source.relationshipState,
            category = source.relationshipState,
            npcType = source.socialRole or source.npcType,
            relationshipTier = source.relationshipTier,
        },
        dialogue_facts = dialogueFacts,
        relationship_capabilities = {
            server_authoritative = true,
            available_reactions = {},
        },
        current_state = {},
        scene = {
            current_speaker_id = npcID,
            addressed_targets = { playerID },
            current_topic = source.currentTopic or source.conversationTopic,
        },
        recent_conversation = recentConversation,
        available_tools = {},
        voice_binding = source.voiceBinding or source.voice_binding,
        audio_presentation = Context.GetAudioPresentation(source),
        metadata = {
            source = "project-hoomans",
            mode = "ambient_social",
            family = tostring(item and item.family or "ambient"),
            event_type = eventType,
            victim_npc_id = victimID ~= "" and victimID or nil,
            victim_first_name = identity.victimFirstName,
            player_name_known = identity.player.known,
            player_message = playerMessage ~= "" and playerMessage or nil,
            social_role = source.socialRole or source.npcType,
            relationship_state = source.relationshipState,
            relationship_tier = source.relationshipTier,
            llm_instruction = "Return dialogue only; no actions or analysis.",
        },
    }
end

return AmbientContext
