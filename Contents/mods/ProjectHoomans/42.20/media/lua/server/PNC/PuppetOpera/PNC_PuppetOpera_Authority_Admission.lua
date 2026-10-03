-- Server-authoritative Puppet Opera admission composition root.
--
-- Resolution/preflight and session acquisition live in ordered providers.
-- This entry preserves the original require path and Internal namespace.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Authority = Opera.Authority or {}
Opera.Authority = Authority
Authority.Internal = Authority.Internal or {}

require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Admission_Preflight"
require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Admission_Session"

return Authority
