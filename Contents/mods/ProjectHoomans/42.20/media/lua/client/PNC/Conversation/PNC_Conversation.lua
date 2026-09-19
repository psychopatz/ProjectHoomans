-- Build 42.20 conversation runtime composition root.
require "PsychopatzCore/UI/Conversation/PsychopatzConversation"
require "PNC/Conversation/PNC_ConversationFactionEmblem"
require "PNC/Conversation/PNC_ConversationTime"
require "PNC/Conversation/PNC_ConversationBackgrounds"
require "PNC/Conversation/PNC_ConversationDiary"
require "PNC/Conversation/Blocks/PNC_ConversationTextLoader"
require "PNC/Conversation/PNC_ConversationAudience"
require "PNC/Conversation/ConversationRelationship/PNC_ConversationRelationship"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer"
require "PNC/Conversation/PNC_ConversationRelationshipPanel"
require "PNC/Conversation/PNC_ConversationLifecycle"
require "PNC/Conversation/PNC_ConversationGroup"
require "PNC/PNC_ConversationSemantics"
local ConversationSemantics = PNC.ConversationSemantics
if ConversationSemantics
    and type(ConversationSemantics.RegisterConversation) == "function"
then
    ConversationSemantics.RegisterConversation(
        PNC.Conversation, PNC.Conversation.Group, PNC.Conversation.Time)
end
require "PNC/Conversation/PNC_SocialFlavorPresentation"
require "PNC/Conversation/PNC_ConversationLiveAnimation"

require "PNC/Conversation/PortraitBackgrounds/PNC_BackgroundDawn"
require "PNC/Conversation/PortraitBackgrounds/PNC_BackgroundSunrise"
require "PNC/Conversation/PortraitBackgrounds/PNC_BackgroundSunset"
require "PNC/Conversation/PortraitBackgrounds/PNC_BackgroundDusk"
require "PNC/Conversation/PortraitBackgrounds/PNC_BackgroundTwilight"

require "PNC/Conversation/PNC_ConversationDefinition"

return PNC.Conversation
