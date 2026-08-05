-- Reusable built-in definition manifest. Each conversation family owns its
-- registration module so it can evolve without growing a monolithic file.
require "PNC/Conversation/Definitions/01_PNC_ConversationDefinitionHelpers"
require "PNC/Conversation/Definitions/10_PNC_ConversationCategories"
require "PNC/Conversation/Definitions/20_PNC_ConversationGreetings"
require "PNC/Conversation/Definitions/30_PNC_ConversationWhatsUp"
require "PNC/Conversation/Definitions/40_PNC_ConversationWellbeing"
require "PNC/Conversation/Definitions/50_PNC_ConversationSmallTalk"
require "PNC/Conversation/Definitions/60_PNC_ConversationAskAbout"
require "PNC/Conversation/Definitions/70_PNC_ConversationNeeds"
require "PNC/Conversation/Definitions/80_PNC_ConversationTrade"
require "PNC/Conversation/Definitions/90_PNC_ConversationWorkOrders"
require "PNC/Conversation/Definitions/91_PNC_ConversationPersonal"
require "PNC/Conversation/Definitions/92_PNC_ConversationRelationship"

return true
