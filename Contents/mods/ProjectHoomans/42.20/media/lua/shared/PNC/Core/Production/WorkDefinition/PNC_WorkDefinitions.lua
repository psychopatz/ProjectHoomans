PNC = PNC or {}
PNC.WorkDefinitions = PNC.WorkDefinitions or {}

local Definitions = PNC.WorkDefinitions

-- Providers must load before consumers. This keeps the public namespace and
-- all legacy callers stable while making each work-definition concern
-- independently editable.
require "PNC/Core/Production/WorkDefinition/PNC_WorkDefinitions_Constants"
require "PNC/Core/Production/WorkDefinition/PNC_WorkDefinitions_Stations"
require "PNC/Core/Production/WorkDefinition/PNC_WorkDefinitions_Routing"
require "PNC/Core/Production/WorkDefinition/PNC_WorkDefinitions_Skills"
require "PNC/Core/Production/WorkDefinition/PNC_WorkDefinitions_Rates"

return Definitions
