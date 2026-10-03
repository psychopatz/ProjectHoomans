-- Animation-scene debug window composition root.
-- UI creation, catalog/target state, details, and actions load in order.
-- Stable route contract: animation_scene_play, animation_scene_pool_step,
-- animation_scene_pool_start, and animation_scene_stop remain exposed by
-- the action provider. The catalog is driven by PNC.AnimationScenes.List().
-- Responsive layout keeps the gap field on the shared boundary:
-- `Layout.SetBounds(self.gapEntry, ...)`.

PNC = PNC or {}
PNC.AnimationSceneDebugWindow = PNC.AnimationSceneDebugWindow or {}

require "PNC/UI/PNC_AnimationSceneDebugWindow_Core"
require "PNC/UI/PNC_AnimationSceneDebugWindow_Catalog"
require "PNC/UI/PNC_AnimationSceneDebugWindow_Details"
require "PNC/UI/PNC_AnimationSceneDebugWindow_Actions"

return PNC.AnimationSceneDebugWindow
