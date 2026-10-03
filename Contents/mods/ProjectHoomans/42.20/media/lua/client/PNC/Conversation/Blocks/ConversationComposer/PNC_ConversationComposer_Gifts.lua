-- Client-side semantic gift composer composition root.
local Conversation = PNC.Conversation
local Composer = Conversation.Composer

require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Gifts_Receive_Context"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Gifts_Receive_Presentation"
require "PNC/Conversation/Blocks/ConversationComposer/PNC_ConversationComposer_Gifts_Receive"

return Composer
