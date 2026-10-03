PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}

local CoreHub = require "PsychopatzCore/UI/PsychopatzCommandHub"
local Registry = CoreHub.Registry
PNC.CommandHub.Registry = Registry
PNC.CommandHub.Gates = PNC.CommandHub.Gates or {}
local Gates = PNC.CommandHub.Gates

local function trace(event, message)
    if CoreHub.Trace then
        CoreHub.Trace(event, message)
    end
end

PNC.CommandHub.RegistryInternal = PNC.CommandHub.RegistryInternal or {}
local Internal = PNC.CommandHub.RegistryInternal
Internal.Registry = Registry
Internal.Gates = Gates
Internal.Trace = trace

require "PNC/UI/CommandHub/PNC_CommandHub_Registry_Gates"
require "PNC/UI/CommandHub/PNC_CommandHub_Registry_Actions"
require "PNC/UI/CommandHub/PNC_CommandHub_Registry_Categories"

return Registry
