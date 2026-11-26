-- Server-authoritative Puppet Opera admission composition root.
--
-- Resolution/preflight and session acquisition live in ordered providers.
-- This entry preserves the original require path and Internal namespace.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Choreography = PNC.Choreography or {}

local Opera = PNC.Choreography
local Authority = Opera.Authority or {}
Opera.Authority = Authority
Authority.Internal = Authority.Internal or {}

require "PNC/Choreography/PNC_Choreography_Authority_Admission_Preflight"
require "PNC/Choreography/PNC_Choreography_Authority_Admission_Session"

return Authority
