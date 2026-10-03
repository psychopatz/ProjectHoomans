-- Stable social combat adapter composition root.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_CombatAdapter_Awareness"
require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_CombatAdapter_Witnesses"

return PNC.SocialEventHooks
