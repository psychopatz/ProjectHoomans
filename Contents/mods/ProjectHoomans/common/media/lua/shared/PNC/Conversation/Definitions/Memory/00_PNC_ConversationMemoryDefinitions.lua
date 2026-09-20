-- Registers the modular backstory, event, topic, and gossip catalogs once.
require "PNC/Conversation/Definitions/Memory/Backstories/00_PNC_ConversationBackstories"
require "PNC/Conversation/Definitions/Memory/EventTypes/00_PNC_ConversationMemoryEventTypes"
require "PNC/Conversation/Definitions/Memory/ConversationTopics/00_PNC_ConversationMemoryTopics"
require "PNC/Conversation/Definitions/Memory/GossipTemplates/00_PNC_ConversationGossipTemplates"

PNC.Conversation.Memory.ValidateTextSources()
return true
