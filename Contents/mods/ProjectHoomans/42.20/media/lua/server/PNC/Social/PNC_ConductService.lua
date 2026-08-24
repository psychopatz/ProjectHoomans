-- Stable server-authoritative behavioral conduct entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Conduct = PNC.Conduct or {}
PNC.Conduct.Internal = PNC.Conduct.Internal or {}

require "PNC/Social/ConductService/PNC_ConductService_Core"
require "PNC/Social/ConductService/PNC_ConductService_EvidenceInternals"
require "PNC/Social/ConductService/PNC_ConductService_Queries"
require "PNC/Social/ConductService/PNC_ConductService_SocialEvents"
require "PNC/Social/ConductService/PNC_ConductService_EvidenceActions"

return PNC.Conduct
