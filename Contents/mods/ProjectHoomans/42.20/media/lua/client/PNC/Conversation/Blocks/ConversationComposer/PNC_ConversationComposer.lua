PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Conversation = PNC.Conversation
local Composer = Conversation.Composer or {}
Conversation.Composer = Composer

require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Runtime"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Context"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Requests"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Blocks"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Outcomes"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Recruitment"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_GiftPresentation"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Gifts"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Menu"

return Composer
