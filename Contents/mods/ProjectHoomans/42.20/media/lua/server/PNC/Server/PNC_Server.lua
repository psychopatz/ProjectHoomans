-- Stable PNC server authority entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Teleport = require "PsychopatzCore/World/PsychopatzTeleport"

PNC = PNC or {}
PNC.Server = PNC.Server or {}
PNC.Server.Internal = PNC.Server.Internal or {}

if PNC.ServerDebugCommandHandler
    and PNC.ServerDebugCommandHandler.ConfigureTeleport
then
    PNC.ServerDebugCommandHandler.ConfigureTeleport(Teleport)
end

require "PNC/Server/Server/PNC_Server_RecordProcessing"
require "PNC/Server/Server/PNC_Server_SubsystemPumps"
require "PNC/Server/Server/PNC_Server_Tick"
require "PNC/Server/Server/PNC_Server_Lifecycle"

return PNC.Server
