-- Server-authoritative social damage adapter composition root.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DamageAdapter_Context"
require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DamageAdapter_TeammateDelivery"
require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DamageAdapter_Recorders"
require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DamageAdapter_Polling"

return PNC.SocialEventHooks
