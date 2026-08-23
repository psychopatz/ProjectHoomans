-- Stable entry point for serialization-safe abstract-world normalization.

PNC = PNC or {}
PNC.AbstractWorldTypes = PNC.AbstractWorldTypes or {}
PNC.AbstractWorldTypes.Internal =
    PNC.AbstractWorldTypes.Internal or {}

require "PNC/Core/Director/PNC_AbstractWorldTypes/PNC_AbstractWorldTypes_Core"
require "PNC/Core/Director/PNC_AbstractWorldTypes/PNC_AbstractWorldTypes_Profiles"
require "PNC/Core/Director/PNC_AbstractWorldTypes/PNC_AbstractWorldTypes_Group"
require "PNC/Core/Director/PNC_AbstractWorldTypes/PNC_AbstractWorldTypes_Location"
require "PNC/Core/Director/PNC_AbstractWorldTypes/PNC_AbstractWorldTypes_Population"
require "PNC/Core/Director/PNC_AbstractWorldTypes/PNC_AbstractWorldTypes_Registry"

return PNC.AbstractWorldTypes
