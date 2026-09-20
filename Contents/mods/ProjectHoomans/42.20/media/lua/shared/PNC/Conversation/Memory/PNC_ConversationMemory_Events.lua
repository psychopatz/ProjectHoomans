-- Event-memory facade. Storage, identity resolution, and gossip projection
-- live in separate modules so each part stays bounded and easy to extend.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Memory = PNC.Conversation.Memory
local Events = Memory.Events or {}
Memory.Events = Events
Events.Internal = Events.Internal or {}

require "PNC/Conversation/Memory/Events/PNC_ConversationMemory_Events_Registry"
require "PNC/Conversation/Memory/Events/PNC_ConversationMemory_Events_Catalog"
require "PNC/Conversation/Memory/Events/PNC_ConversationMemory_Events_TopicRegistry"
require "PNC/Conversation/Memory/Events/PNC_ConversationMemory_Events_Topics"
require "PNC/Conversation/Memory/Events/PNC_ConversationMemory_Events_Targets"
require "PNC/Conversation/Memory/Events/PNC_ConversationMemory_Events_Storage"
require "PNC/Conversation/Memory/Events/PNC_ConversationMemory_Events_TopicMemory"
require "PNC/Conversation/Memory/Events/PNC_ConversationMemory_Events_Recorder"
require "PNC/Conversation/Memory/Events/PNC_ConversationMemory_Events_Gossip"

return Events
