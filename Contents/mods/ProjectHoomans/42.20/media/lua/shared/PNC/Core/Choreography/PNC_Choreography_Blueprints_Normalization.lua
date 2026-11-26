-- Puppet Opera blueprint normalization composition root.
local PNC = _G.PNC or {}
local Opera = PNC.Choreography or {}
local Capabilities = Opera.AnimationCapabilities
    or require "PNC/Core/Choreography/PNC_Choreography_AnimationCapabilities"

local Normalization = {}
Normalization._Capabilities = Capabilities
Opera.BlueprintNormalization = Normalization

require "PNC/Core/Choreography/PNC_Choreography_Blueprints_Normalization_Primitives"
require "PNC/Core/Choreography/PNC_Choreography_Blueprints_Normalization_Actors"
require "PNC/Core/Choreography/PNC_Choreography_Blueprints_Normalization_Timeline"

Normalization.CleanText = Normalization._CleanText
Normalization.ValidID = Normalization._ValidID
Normalization.NumberInRange = Normalization._NumberInRange
Normalization.IntegerInRange = Normalization._IntegerInRange
Normalization.NormalizeAnchor = Normalization._NormalizeAnchor
Normalization.NormalizeActors = Normalization._NormalizeActors
Normalization.NormalizeBeats = Normalization._NormalizeBeats

return Normalization
