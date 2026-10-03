-- Project Hoomans adapter for the reusable PsychopatzCore social-flavor hub.
-- Provider composition root: shared context, speech/safety, delivery lifecycle.

PNC = PNC or {}
PNC.SocialFlavorPresentation = PNC.SocialFlavorPresentation or {}

require "PNC/Conversation/PNC_SocialFlavorPresentation_Core"
require "PNC/Conversation/PNC_SocialFlavorPresentation_Speech"
require "PNC/Conversation/PNC_SocialFlavorPresentation_Delivery"

return PNC.SocialFlavorPresentation
