-- Stable command-flavor entry point. Registration helpers and deterministic
-- base, typed, and social records load in the same order as the old catalog.
PNC = PNC or {}
PNC.CompanionCommandFlavor = PNC.CompanionCommandFlavor or {}

require "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions_Core"
require "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions_Base"
require "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions_TypedA"
require "PNC/Core/Commands/PNC_CompanionCommandFlavorDefinitions_TypedB"

return PNC.CompanionCommandFlavor
