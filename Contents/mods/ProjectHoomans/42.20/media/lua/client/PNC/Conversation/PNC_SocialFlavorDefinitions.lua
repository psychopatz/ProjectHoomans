-- Stable social flavor definition aggregator.
require "PsychopatzCore/Conversation/PsychopatzSocialFlavor"

PNC = PNC or {}
PNC.SocialFlavorDefinitions = PNC.SocialFlavorDefinitions or {}

require "PNC/Conversation/PNC_SocialFlavorDefinitions_Core"
require "PNC/Conversation/PNC_SocialFlavorDefinitions_GroupA"
require "PNC/Conversation/PNC_SocialFlavorDefinitions_GroupB"
require "PNC/Conversation/PNC_SocialFlavorDefinitions_GroupC"

return PNC.SocialFlavorDefinitions
