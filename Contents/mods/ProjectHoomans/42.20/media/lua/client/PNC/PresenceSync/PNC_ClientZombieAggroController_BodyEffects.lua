-- Engine-facing effects for ordinary zombie pursuit and managed shell safety.
-- Target selection and update scheduling stay in the controller.
PNC = PNC or {}
PNC.ZombieAggroEffects = PNC.ZombieAggroEffects or {}

local Effects = PNC.ZombieAggroEffects
Effects.Internal = Effects.Internal or {}

require "PNC/PresenceSync/PNC_ClientZombieAggroController_BodyEffects_Safety"
require "PNC/PresenceSync/PNC_ClientZombieAggroController_BodyEffects_Pursuit"

return Effects
