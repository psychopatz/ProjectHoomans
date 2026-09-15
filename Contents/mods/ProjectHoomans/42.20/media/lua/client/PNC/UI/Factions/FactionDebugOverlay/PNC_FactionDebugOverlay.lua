-- Embedded diplomacy dashboard and controller entry point.

require "ISUI/ISUIElement"
require "PNC/UI/Factions/FactionDebugModel/PNC_FactionDebugModel"

PNC = PNC or {}
PNC.FactionDebugOverlay = PNC.FactionDebugOverlay or {}

local Overlay = PNC.FactionDebugOverlay

require "PNC/UI/Factions/FactionDebugOverlay/PNC_FactionDebugOverlay_Config"

ISPNCFactionDebugOverlay =
    ISUIElement:derive("ISPNCFactionDebugOverlay")

require "PNC/UI/Factions/FactionDebugOverlay/PNC_FactionDebugOverlay_Presentation"
require "PNC/UI/Factions/FactionDebugOverlay/PNC_FactionDebugOverlay_Render"
require "PNC/UI/Factions/FactionDebugOverlay/PNC_FactionDebugOverlay_Selection"
require "PNC/UI/Factions/FactionDebugOverlay/PNC_FactionDebugOverlay_Snapshot"
require "PNC/UI/Factions/FactionDebugOverlay/PNC_FactionDebugOverlay_Diagnostics"
require "PNC/UI/Factions/FactionDebugOverlay/PNC_FactionDebugOverlay_Lifecycle"

return Overlay
