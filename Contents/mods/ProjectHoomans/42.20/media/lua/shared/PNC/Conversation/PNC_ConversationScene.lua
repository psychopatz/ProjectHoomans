-- Stable entry point for shared conversation authority and scene leases.

PNC = PNC or {}
PNC.ConversationScene = PNC.ConversationScene or {}
PNC.ConversationScene.Internal = PNC.ConversationScene.Internal or {}

local Scene = PNC.ConversationScene

Scene.ID = "social.conversation"
Scene.CMD_BEGIN = "conversationBegin"
Scene.CMD_END = "conversationEnd"
Scene.CMD_CEASEFIRE = "conversationCeasefire"
Scene.LEASE_MS = 3500
-- Provider calls can outlive the visual conversation window. This lease is
-- separate from the short movement/animation lease and is bound to one
-- reserved request ID.
Scene.LLM_REQUEST_LEASE_MS = 120000
Scene.START_DISTANCE = 6.0
Scene.DANGER_RADIUS = 8.0
Scene.CEASEFIRE_HOURS = 1

require "PNC/Conversation/PNC_ConversationScene/PNC_ConversationScene_Core"
require "PNC/Conversation/PNC_ConversationScene/PNC_ConversationScene_Registration"
require "PNC/Conversation/PNC_ConversationScene/PNC_ConversationScene_Threat"
require "PNC/Conversation/PNC_ConversationScene/PNC_ConversationScene_Lease"
require "PNC/Conversation/PNC_ConversationScene/PNC_ConversationScene_Ceasefire"
require "PNC/Conversation/PNC_ConversationScene/PNC_ConversationScene_Commands"

return Scene
