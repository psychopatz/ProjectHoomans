-- Client-side recruitment result composer composition root.
local Conversation = PNC.Conversation
local Composer = Conversation.Composer

require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Recruitment_Receive_Context"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Recruitment_Receive_Presentation"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Recruitment_Receive"

return Composer
