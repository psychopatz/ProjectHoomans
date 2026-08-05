-- Build 42.20 conversation runtime composition root.
require "PsychopatzCore/UI/Conversation/PsychopatzConversation"
require "PNC/Conversation/PNC_ConversationFactionEmblem"
require "PNC/Conversation/PNC_ConversationTime"
require "PNC/Conversation/Content/PNC_ConversationRegistry"
require "PNC/Conversation/PNC_ConversationRelationship"
require "PNC/Conversation/PNC_ConversationRelationshipPanel"
require "PNC/Conversation/PNC_ConversationLifecycle"
require "PNC/UI/PNC_NPCTypePalette"

require "PNC/Conversation/PortraitBackgrounds/PNC_BackgroundDawn"
require "PNC/Conversation/PortraitBackgrounds/PNC_BackgroundSunrise"
require "PNC/Conversation/PortraitBackgrounds/PNC_BackgroundSunset"
require "PNC/Conversation/PortraitBackgrounds/PNC_BackgroundDusk"
require "PNC/Conversation/PortraitBackgrounds/PNC_BackgroundTwilight"

require "PNC/Conversation/Content/Greetings/FirstMeet/00_FirstMeetGreetings"
require "PNC/Conversation/Content/Greetings/Acquaintance/00_AcquaintanceGreetings"
require "PNC/Conversation/Content/Greetings/Member/00_MemberGreetings"
require "PNC/Conversation/Content/Greetings/Lover/00_LoverGreetings"

require "PNC/Conversation/PNC_ConversationDefinition"

return PNC.Conversation
