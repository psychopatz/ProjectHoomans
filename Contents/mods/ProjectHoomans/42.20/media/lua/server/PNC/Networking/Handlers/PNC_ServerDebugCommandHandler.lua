-- Stable server-authoritative debug-command entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ServerDebugCommandHandler =
    PNC.ServerDebugCommandHandler or {}
PNC.ServerDebugCommandHandler.Internal =
    PNC.ServerDebugCommandHandler.Internal or {}

require "PNC/Networking/Handlers/ServerDebugCommandHandler/PNC_ServerDebugCommandHandler_Core"
require "PNC/Networking/Handlers/ServerDebugCommandHandler/PNC_ServerDebugCommandHandler_Relationships"
require "PNC/Networking/Handlers/ServerDebugCommandHandler/PNC_ServerDebugCommandHandler_KnowledgeRecruitment"
require "PNC/Networking/Handlers/ServerDebugCommandHandler/PNC_ServerDebugCommandHandler_Diagnostics"
require "PNC/Networking/Handlers/ServerDebugCommandHandler/PNC_ServerDebugCommandHandler_ApiActions"
require "PNC/Networking/Handlers/ServerDebugCommandHandler/PNC_ServerDebugCommandHandler_BodyAudit"
require "PNC/Networking/Handlers/ServerDebugCommandHandler/PNC_ServerDebugCommandHandler_Routing"

return PNC.ServerDebugCommandHandler
