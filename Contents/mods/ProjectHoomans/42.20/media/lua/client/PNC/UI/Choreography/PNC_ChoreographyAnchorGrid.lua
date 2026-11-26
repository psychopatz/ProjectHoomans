-- Compatibility and load-order hub for the Puppet Opera anchor grid.
--
-- Keep this public module path and class name stable.  The implementation is
-- split into cohesive UI spokes so callers can continue to use the original
-- Project Zomboid UI class without depending on the internal file layout.

require "ISUI/ISPanel"
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}

ISPNCChoreographyAnchorGrid = ISPanel:derive("ISPNCChoreographyAnchorGrid")

-- Load state first, then the pure coordinate contract, then the two runtime
-- surfaces which consume it.  The explicit order keeps PZ's Lua load order
-- deterministic while preserving the original single-module entry point.
require "PNC/UI/Choreography/PNC_ChoreographyAnchorGrid_Lifecycle"
require "PNC/UI/Choreography/PNC_ChoreographyAnchorGrid_Geometry"
require "PNC/UI/Choreography/PNC_ChoreographyAnchorGrid_Presentation"
require "PNC/UI/Choreography/PNC_ChoreographyAnchorGrid_Interaction"

return ISPNCChoreographyAnchorGrid
