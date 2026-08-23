-- Stable entry point for the Project Hoomans cross-system API façade.

PNC = PNC or {}
PNC.API = PNC.API or {}
PNC.API.Internal = PNC.API.Internal or {}
PNC.API.MapPresentation = PNC.API.MapPresentation or {}
PNC.API.Travel = PNC.API.Travel or {}
PNC.API.Conversations = PNC.API.Conversations or {}
PNC.API.AnimationScenes = PNC.API.AnimationScenes or {}
PNC.API.MapCommands = PNC.API.MapCommands or {}

require "PNC/Core/API/PNC_API/Lifecycle"
require "PNC/Core/API/PNC_API/HealthSnapshots"
require "PNC/Core/API/PNC_API/MapPresentation"
require "PNC/Core/API/PNC_API/DebugCommands"
require "PNC/Core/API/PNC_API/Travel"
require "PNC/Core/API/PNC_API/Conversations"
require "PNC/Core/API/PNC_API/AnimationScenes"
require "PNC/Core/API/PNC_API/MapCommands"
