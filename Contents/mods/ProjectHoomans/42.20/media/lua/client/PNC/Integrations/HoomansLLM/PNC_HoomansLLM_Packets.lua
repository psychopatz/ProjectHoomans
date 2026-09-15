-- Interactive conversation packet construction.
PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Integration = PNC.HoomansLLM
local Internal = Integration.Internal
local Packets = Internal.Packets or {}
Internal.Packets = Packets
local Runtime = Internal.Runtime
local Context = Integration.Context
local Trace = PsychopatzCore.DebugTrace

function Packets.Build(view, requestID, message)
    local context = Context.Build(view, message)
    context.request_id = requestID
    context.session_id = context.session_id
        or "pnc_session_" .. tostring(Runtime.Now()) .. "_"
            .. tostring(Internal.State.serial)
    view.session.llmSessionID = context.session_id
    local packet = {
        status = "pending",
        request_id = requestID,
        npc_id = context.npc_uuid,
        world_uuid = context.world_uuid,
        world_mode = context.world_mode,
        save_relative_path = context.save_relative_path,
        server_instance_id = context.server_instance_id,
        server_world_generation = context.server_world_generation,
        player_uuid = context.player_uuid,
        session_id = context.session_id,
        npc_name = context.npc_name,
        player_name = context.player_name,
        model = "default",
        conversation_context = context,
    }
    if Runtime.TraceEnabled() then
        Trace.Record({
            source = "ProjectHoomans",
            event = "llm.request_queued",
            requestID = requestID,
            data = packet,
        })
    end
    return packet
end

return Packets
