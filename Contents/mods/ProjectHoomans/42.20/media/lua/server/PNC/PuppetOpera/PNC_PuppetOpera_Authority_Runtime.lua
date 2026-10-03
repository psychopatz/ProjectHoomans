-- Server-authoritative Puppet Opera runtime state machine.
--
-- This spoke owns phase progression and per-tick adapter coordination.  It
-- receives validation, ownership, and lifecycle operations from the authority
-- entry module through the bounded Internal handoff table.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Opera = PNC.PuppetOpera
local Authority = Opera.Authority or {}
Opera.Authority = Authority
local Internal = Authority.Internal or {}
Authority.Internal = Internal

require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Runtime_Timeline"
require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Runtime_Phases"
require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Runtime_Safety"
require "PNC/PuppetOpera/PNC_PuppetOpera_Authority_Runtime_Dispatch"

return Authority
