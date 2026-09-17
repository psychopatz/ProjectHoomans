-- Composition root for client-local world-object perception.
-- The public namespace remains stable; ordered spokes own data access,
-- providers, zone policy diagnostics, and snapshot assembly.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

PNC = PNC or {}
PNC.Perception = PNC.Perception or {}

local Perception = PNC.Perception.WorldObjects or {}
PNC.Perception.WorldObjects = Perception

require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception_Internal"
require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception_Registry"
require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception_Providers"
require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception_Zones"
require "PNC/Perception/WorldObjectPerception/PNC_ClientWorldObjectPerception_Snapshot"

return Perception
