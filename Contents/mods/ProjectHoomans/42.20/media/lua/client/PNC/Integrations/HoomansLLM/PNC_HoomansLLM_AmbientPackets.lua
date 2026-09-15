-- Ambient social flavor packet construction.
PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Integration = PNC.HoomansLLM
local Internal = Integration.Internal
local AmbientPackets = Internal.AmbientPackets or {}
Internal.AmbientPackets = AmbientPackets
local ActorIdentity = Internal.ActorIdentity
local AmbientContext = Internal.AmbientContext

function AmbientPackets.Build(item, requestID)
    local source = item and item.context or {}
    local npcID = tostring(item and item.speakerID or source.npcID or "")
    local playerID = tostring(item and item.playerUUID
        or source.playerUUID or "ambient-player")
    local identity = ActorIdentity.Resolve(item, source, npcID, playerID)
    local context = AmbientContext.Build(
        item,
        source,
        npcID,
        playerID,
        identity,
        requestID
    )
    return {
        status = "pending",
        request_id = requestID,
        npc_id = npcID,
        world_uuid = context.world_uuid,
        world_mode = context.world_mode,
        save_relative_path = context.save_relative_path,
        server_instance_id = context.server_instance_id,
        server_world_generation = context.server_world_generation,
        player_uuid = playerID,
        session_id = context.session_id,
        npc_name = identity.npcFullName,
        player_name = identity.playerFirstName,
        victim_name = identity.victimFirstName,
        model = "default",
        conversation_context = context,
    }
end

return AmbientPackets
