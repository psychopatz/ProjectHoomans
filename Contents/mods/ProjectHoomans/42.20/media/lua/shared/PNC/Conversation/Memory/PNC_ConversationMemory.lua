-- Full memory facade: storage plus contextual realization, recording and gossip.
require "PNC/Conversation/Memory/PNC_ConversationMemoryRepository"
local Memory = PNC.Conversation.Memory
require "PNC/Conversation/Memory/PNC_ConversationMemory_BackstoryContext"
require "PNC/Conversation/Memory/PNC_ConversationMemory_Gossip"
require "PNC/Conversation/Memory/PNC_ConversationMemory_Events"

local MemoryProvider = require
    "PNC/Semantics/PNC_SemanticConversationMemoryProvider"
MemoryProvider.Bind(Memory)

return Memory
