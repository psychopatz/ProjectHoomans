-- Animation-scene lifecycle composition root.
-- Shared clear helpers load before request and control providers.

PNC = PNC or {}
PNC.AnimationScenes = PNC.AnimationScenes or {}
PNC.AnimationScenes.Internal = PNC.AnimationScenes.Internal or {}

require "PNC/Core/Visuals/PNC_AnimationScenes/PNC_AnimationScenes_Lifecycle_Core"
require "PNC/Core/Visuals/PNC_AnimationScenes/PNC_AnimationScenes_Lifecycle_Request"
require "PNC/Core/Visuals/PNC_AnimationScenes/PNC_AnimationScenes_Lifecycle_Controls"

return PNC.AnimationScenes
