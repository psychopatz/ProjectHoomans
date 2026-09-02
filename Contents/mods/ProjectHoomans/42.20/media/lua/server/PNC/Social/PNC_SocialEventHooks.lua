-- Stable social-event hooks entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}

require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_Core"
require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_RescueContributions"
require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_Treatment"
require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_Encounter"
require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_ThreatAttribution"
require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_CombatAdapter"
require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DamageAdapter"
require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_ClientKill"

return PNC.SocialEventHooks
