-- Context and prompt assembly for ambient social flavor packets.
PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Integration = PNC.HoomansLLM
local Context = Integration.Context
local MemoryIdentity = Integration.Identity
local Message = PsychopatzCore.Conversation.Message
local AmbientContext = Integration.Internal.AmbientContext or {}
Integration.Internal.AmbientContext = AmbientContext

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

function AmbientContext.Build(item, source, npcID, playerID, identity, requestID)
    local victimID = tostring(source.victimNPCID or "")
    local eventType = tostring(source.eventType or item and item.family
        or "ambient_social")
    local playerMessage = tostring(source.playerMessage or "")
    local memoryIdentity = MemoryIdentity.Current()
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
        relationship_capabilities = {
            server_authoritative = true,
            available_reactions = {},
        },
        current_state = {},
        scene = {
            current_speaker_id = npcID,
            addressed_targets = { playerID },
        },
        recent_conversation = {},
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
