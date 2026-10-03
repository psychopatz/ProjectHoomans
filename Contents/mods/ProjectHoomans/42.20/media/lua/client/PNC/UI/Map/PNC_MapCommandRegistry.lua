-- Stable map-command entry point. Selection and provider dispatch, context
-- menus, and map rendering/input hooks load in dependency order.
require "PNC/UI/Map/PNC_MapCommandRegistry_Core"
require "PNC/UI/Map/PNC_MapCommandRegistry_Context"
require "PNC/UI/Map/PNC_MapCommandRegistry_Render"

return PNC.MapCommands
