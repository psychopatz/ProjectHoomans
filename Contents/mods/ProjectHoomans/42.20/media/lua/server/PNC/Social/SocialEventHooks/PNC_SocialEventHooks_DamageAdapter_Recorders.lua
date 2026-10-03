-- Server-authoritative social damage event recorder provider.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DamageAdapter_TeammateDelivery"
require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DamageAdapter_Recorders_Helpers"
require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DamageAdapter_Recorders_NPC"
require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DamageAdapter_Recorders_Faction"
require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DamageAdapter_Recorders_Player"

return PNC.SocialEventHooks
