-- Physical-world tree access, persistent ledger reconciliation, and claims.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal

require "PNC/Lumber/LumberService/PNC_LumberService_Trees_Access"
require "PNC/Lumber/LumberService/PNC_LumberService_Trees_Scan"
require "PNC/Lumber/LumberService/PNC_LumberService_Trees_Claims"

return Service
