-- Stable server-authoritative social-event entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEvents = PNC.SocialEvents or {}

require "PNC/Social/SocialEventService/PNC_SocialEventService_Context"
require "PNC/Social/SocialEventService/PNC_SocialEventService_Validation"
require "PNC/Social/SocialEventService/PNC_SocialEventService_Observers"
require "PNC/Social/SocialEventService/PNC_SocialEventService_Process"
require "PNC/Social/SocialEventService/PNC_SocialEventService_Emit"

return PNC.SocialEvents
