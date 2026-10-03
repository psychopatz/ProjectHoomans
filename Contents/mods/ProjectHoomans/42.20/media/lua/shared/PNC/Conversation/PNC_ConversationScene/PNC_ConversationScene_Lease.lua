-- Conversation lease composition root.
-- Shared ownership, begin, LLM request, and end/pump providers load in order.

PNC = PNC or {}
PNC.ConversationScene = PNC.ConversationScene or {}
PNC.ConversationScene.Internal = PNC.ConversationScene.Internal or {}

require "PNC/Conversation/PNC_ConversationScene/PNC_ConversationScene_Lease_Core"
require "PNC/Conversation/PNC_ConversationScene/PNC_ConversationScene_Lease_Begin"
require "PNC/Conversation/PNC_ConversationScene/PNC_ConversationScene_Lease_LLM"
require "PNC/Conversation/PNC_ConversationScene/PNC_ConversationScene_Lease_End"

return PNC.ConversationScene
