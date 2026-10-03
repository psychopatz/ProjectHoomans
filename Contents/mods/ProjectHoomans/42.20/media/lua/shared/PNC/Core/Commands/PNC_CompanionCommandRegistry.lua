-- Data-driven, authority-owned companion command composition root.
-- Client adapters render the same definitions in the emote radial and NPC
-- context menu through the public PNC.CompanionCommands table.

PNC = PNC or {}
PNC.CompanionCommands = PNC.CompanionCommands or {}

local Commands = PNC.CompanionCommands

Commands.Definitions = Commands.Definitions or {}
Commands.DefinitionOrder = Commands.DefinitionOrder or {}
Commands.Groups = Commands.Groups or {}
Commands.GroupOrder = Commands.GroupOrder or {}

-- Load the registry and authority providers before gameplay effects.
require "PNC/Core/Commands/PNC_CompanionCommandRegistry_Registry"
require "PNC/Core/Commands/PNC_CompanionCommandRegistry_Authority"

-- Single-record application defines the public Apply seam before the group
-- camp extension and protocol execution adapters are attached.
require "PNC/Core/Commands/PNC_CompanionCommandRegistry_Application"
require "PNC/Core/Commands/PNC_CompanionCommandRegistry_GroupCamp"
require "PNC/Core/Commands/PNC_CompanionCommandRegistry_GroupCampApplication"
require "PNC/Core/Commands/PNC_CompanionCommandRegistry_Execution"

return Commands
