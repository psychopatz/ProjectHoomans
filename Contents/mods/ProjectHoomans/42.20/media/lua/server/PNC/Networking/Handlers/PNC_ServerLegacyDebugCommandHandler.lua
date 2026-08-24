-- Stable legacy debug-command compatibility entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ServerLegacyDebugCommandHandler =
    PNC.ServerLegacyDebugCommandHandler or {}
PNC.ServerLegacyDebugCommandHandler.Internal =
    PNC.ServerLegacyDebugCommandHandler.Internal or {}

require "PNC/Networking/Handlers/ServerLegacyDebugCommandHandler/PNC_ServerLegacyDebugCommandHandler_Core"
require "PNC/Networking/Handlers/ServerLegacyDebugCommandHandler/PNC_ServerLegacyDebugCommandHandler_Relationships"
require "PNC/Networking/Handlers/ServerLegacyDebugCommandHandler/PNC_ServerLegacyDebugCommandHandler_KnowledgeRecruitment"
require "PNC/Networking/Handlers/ServerLegacyDebugCommandHandler/PNC_ServerLegacyDebugCommandHandler_Diagnostics"
require "PNC/Networking/Handlers/ServerLegacyDebugCommandHandler/PNC_ServerLegacyDebugCommandHandler_ApiActions"
require "PNC/Networking/Handlers/ServerLegacyDebugCommandHandler/PNC_ServerLegacyDebugCommandHandler_BodyAudit"
require "PNC/Networking/Handlers/ServerLegacyDebugCommandHandler/PNC_ServerLegacyDebugCommandHandler_Routing"

return PNC.ServerLegacyDebugCommandHandler
