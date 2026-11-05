-- Project Hoomans registration facade over Core's shared map-tools menu.
-- Core owns the singleton registry, window, toolbar button, and lifecycle;
-- Hoomans contributes only provider-specific entries.

local Menu = require "PsychopatzCore/UI/Map/PsychopatzMapToolsMenu"

PNC = PNC or {}
PNC.MapHoomansMenu = Menu

return Menu
