-- Domain registration: Social. Ordered startup only; no gameplay policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
require "PNC/Social/PNC_SocialEventDebug"
require "PNC/Social/PNC_SocialEventService"
require "PNC/Social/PNC_SocialEncounterTracker"
require "PNC/Social/PNC_SocialMeetingService"
require "PNC/Social/PNC_SocialGreetingService"
require "PNC/Social/PNC_FollowerAbandonmentService"
require "PNC/Social/PNC_SocialEventHooks"
