-- Client-local group conversation coordinator.
--
-- Nearby mode has one visible conversation queue, but each participant keeps
-- its own semantic router, context, and authoritative action request.  This
-- module only coordinates those boundaries; it never mutates world state.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Group = PNC.Conversation.Group or {}
PNC.Conversation.Group = Group

Group.VERSION = 1
Group.MAX_PARTICIPANTS = 12
Group.MAX_EVENTS = 16
Group.MAX_INPUT_LENGTH = 4000


require "PNC/Conversation/PNC_ConversationGroup_Core"
require "PNC/Conversation/PNC_ConversationGroup_Addressing"
require "PNC/Conversation/PNC_ConversationGroup_Camp"
require "PNC/Conversation/PNC_ConversationGroup_Submit"

return Group
