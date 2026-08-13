-- Deterministic Presence runtime entry. BodyLifecycle loads earlier because
-- Health and PathService depend on its engine-object lifecycle facade.
require "PNC/Core/Presence/PNC_PresenceAdmission"
require "PNC/Core/Presence/PNC_MaterializationSafety"
require "PNC/Core/Presence/PNC_Presence"

return PNC and PNC.Presence
