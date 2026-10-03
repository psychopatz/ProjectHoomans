-- Radio, debug, and conversation discovery sources.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.Internal
local Types = PNC.WorldDiscoveryTypes
local Core = PNC.Core

require "PNC/WorldDiscovery/PNC_WorldDiscovery_Actions_RadioHelpers"
require "PNC/WorldDiscovery/PNC_WorldDiscovery_Actions_Radio"
require "PNC/WorldDiscovery/PNC_WorldDiscovery_Actions_Contacts"

return Discovery
