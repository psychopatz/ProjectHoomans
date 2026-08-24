-- Public social-event emission facade.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEvents = PNC.SocialEvents or {}
local SocialEvents = PNC.SocialEvents

function SocialEvents.Emit(eventSpec)
    return SocialEvents.Process(eventSpec)
end

return SocialEvents
