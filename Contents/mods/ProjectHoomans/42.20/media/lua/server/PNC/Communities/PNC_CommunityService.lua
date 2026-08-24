-- Server-authoritative persistent communities entry.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.Communities = PNC.Communities or {}
PNC.Communities.Internal = PNC.Communities.Internal or {}

require "PNC/Communities/CommunityService/PNC_CommunityService_Core"
require "PNC/Communities/CommunityService/PNC_CommunityService_Indexes"
require "PNC/Communities/CommunityService/PNC_CommunityService_Persistence"
require "PNC/Communities/CommunityService/PNC_CommunityService_Queries"
require "PNC/Communities/CommunityService/PNC_CommunityService_Sites"
require "PNC/Communities/CommunityService/PNC_CommunityService_Affiliations"
require "PNC/Communities/CommunityService/PNC_CommunityService_Membership"
require "PNC/Communities/CommunityService/PNC_CommunityService_Leadership"
require "PNC/Communities/CommunityService/PNC_CommunityService_Attributes"
require "PNC/Communities/CommunityService/PNC_CommunityService_Supplies"
require "PNC/Communities/CommunityService/PNC_CommunityService_Lifecycle"
require "PNC/Communities/CommunityService/PNC_CommunityService_Validation"

return PNC.Communities
