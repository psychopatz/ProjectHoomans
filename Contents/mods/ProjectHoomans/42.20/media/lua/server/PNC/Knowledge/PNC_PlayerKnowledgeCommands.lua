-- Stable authoritative player-knowledge command entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerKnowledgeCommands = PNC.PlayerKnowledgeCommands or {}
PNC.PlayerKnowledgeCommands.Internal =
    PNC.PlayerKnowledgeCommands.Internal or {}

local Commands = PNC.PlayerKnowledgeCommands
Commands.Processed = Commands.Processed or {}
Commands.Uncommitted = Commands.Uncommitted or {}
Commands.Diagnostics = Commands.Diagnostics or {}
Commands.Internal.BootstrapChunkSize = 32

require "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_Core"
require "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_Presentation"
require "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_Bootstrap"
require "PNC/Knowledge/PlayerKnowledgeCommands/PNC_PlayerKnowledgeCommands_Disclosure"
require "PNC/Knowledge/PNC_NPCKnowledgeAPI"

return Commands
