-- Stable entry point for abstract-world director tuning.

PNC = PNC or {}
PNC.DirectorConfig = PNC.DirectorConfig or {}

require "PNC/Core/Director/PNC_DirectorConfig/PNC_DirectorConfig_Core"
require "PNC/Core/Director/PNC_DirectorConfig/PNC_DirectorConfig_Behavior"
require "PNC/Core/Director/PNC_DirectorConfig/PNC_DirectorConfig_Combat"
require "PNC/Core/Director/PNC_DirectorConfig/PNC_DirectorConfig_Archetypes"
require "PNC/Core/Director/PNC_DirectorConfig/PNC_DirectorConfig_Population"

return PNC.DirectorConfig
