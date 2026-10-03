-- Built-in animation scene definition composition root.
-- Base/social, facility, and ambient/survival registrations load in order.

PNC = PNC or {}
PNC.AnimationScenes = PNC.AnimationScenes or {}
PNC.AnimationScenes.Internal = PNC.AnimationScenes.Internal or {}

require "PNC/Core/Visuals/PNC_AnimationSceneDefinitions_Base"
require "PNC/Core/Visuals/PNC_AnimationSceneDefinitions_Facility"
require "PNC/Core/Visuals/PNC_AnimationSceneDefinitions_Ambient"

return PNC.AnimationScenes
